import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/signup/data/signup_draft.dart';
import '../auth/cognito_auth_service.dart';
import '../crypto/crypto_service.dart';
// NOTE: the three imports below are provided by the db / proximity /
// transport modules (built in parallel to their contracts). If a path or
// constructor differs at integration time, this file is the only place to
// reconcile.
import '../db/app_database.dart';
import '../db/connection_repository_impl.dart';
import '../db/encounter_repository_impl.dart';
import '../db/message_repository_impl.dart';
import '../db/profile_repository_impl.dart';
import '../db/request_repository_impl.dart';
import '../db/seen_message_store.dart';
import '../db/settings_repository_impl.dart';
import '../proximity/ble_proximity_engine.dart';
import '../proximity/proximity_engine.dart';
import '../proximity/simulated_proximity_engine.dart';
import '../proximity/switchable_proximity_engine.dart';
import '../storage/secure_storage_service.dart';
import '../transport/relay_transport_client.dart';
import 'app_services.dart';
import 'connection_service_impl.dart';
import 'envelope_router.dart';
import 'inbound_handler.dart';
import 'message_service_impl.dart';
import 'session_service_impl.dart';

EnvelopeRouter? _router;
MessageServiceImpl? _messaging;

// References kept for wipeLocalData() (finding [10]): the open handle to wipe
// every table, and the concrete repositories whose in-memory notifiers/streams
// must be reset so the UI reflects an empty, signed-out state.
Database? _db;
EncounterRepositoryImpl? _encounters;
RequestRepositoryImpl? _requests;
ConnectionRepositoryImpl? _connections;
MessageRepositoryImpl? _messages;

/// Builds the whole service graph and installs it as [AppServices.I].
///
/// Called once from `bootstrap()` in main.dart, after EnvironmentConfig is
/// set. [simulated] is a LIVE flag (the user's "Demo Content" switch): while
/// it is on, proximity is served by [SimulatedProximityEngine]; while it is
/// off, by the real [BleProximityEngine]. Passing null pins the real engine.
///
/// The relay transport is connected lazily: immediately when a profile
/// already exists (returning user), otherwise not until the signup flow
/// calls [connectTransport] after account creation.
Future<void> initAppServices({ValueListenable<bool>? simulated}) async {
  // 1. Identity keys (generate on first run).
  await CryptoService.instance.init();

  // 2. Local database + repositories.
  final db = await AppDatabase.openAppDatabase();
  final settings = SettingsRepositoryImpl(db);
  final profile = ProfileRepositoryImpl(db, settings);
  final encounters = EncounterRepositoryImpl(db);
  final requests = RequestRepositoryImpl(db);
  final connections = ConnectionRepositoryImpl(db);
  // settings passed so new threads inherit "disappearing by default"
  // (finding [13]).
  final messages = MessageRepositoryImpl(db, settings);
  final seen = SqliteSeenMessageLedger(db);
  await settings.load();
  await profile.load();

  // Retained for wipeLocalData() (finding [10]).
  _db = db;
  _encounters = encounters;
  _requests = requests;
  _connections = connections;
  _messages = messages;

  // 3. Channels.
  final ProximityEngine engine = simulated == null
      ? BleProximityEngine()
      : SwitchableProximityEngine(
          real: BleProximityEngine(),
          simulated: SimulatedProximityEngine(),
          useSimulated: simulated,
        );
  final transport = RelayTransportClient();

  // 4. Services. MessageService first so the inbound handler can borrow its
  //    receipt plumbing.
  final messaging = MessageServiceImpl(
    engine: engine,
    transport: transport,
    profile: profile,
    connections: connections,
    messages: messages,
    settings: settings,
  );
  final inbound = InboundHandler(
    requests: requests,
    connections: connections,
    messages: messages,
    sendReceipt: messaging.sendReceipt,
    seen: seen,
  );
  final router = EnvelopeRouter(
    transport: transport,
    connections: connections,
    handler: inbound,
  );
  final session = SessionServiceImpl(
    engine: engine,
    profile: profile,
    encounters: encounters,
    settings: settings,
    inbound: inbound,
    router: router,
  );
  final connection = ConnectionServiceImpl(
    engine: engine,
    transport: transport,
    profile: profile,
    requests: requests,
    connections: connections,
    encounters: encounters,
    settings: settings,
  );

  AppServices.install(AppServices(
    profile: profile,
    encounters: encounters,
    requests: requests,
    connections: connections,
    messages: messages,
    settings: settings,
    engine: engine,
    transport: transport,
    session: session,
    connection: connection,
    messaging: messaging,
  ));

  _router = router..start();
  _messaging = messaging..start();

  // 5. Housekeeping + transport.
  unawaited(encounters
      .sweepOlderThan(const Duration(days: 30))
      .catchError((Object e) => debugPrint('Encounter sweep failed: $e')));
  // Bound the replay ledger to the freshness window (finding [0]).
  unawaited(seen
      .pruneBefore(DateTime.now().subtract(const Duration(days: 7)))
      .catchError((Object e) => debugPrint('Seen-ledger prune failed: $e')));
  if (profile.profile.value != null) {
    // Signed-in user: bring the relay up in the background.
    unawaited(connectTransport());
  }
}

/// Connect the relay transport and (re)publish our key bundle to the
/// directory. Safe to call repeatedly; the signup flow calls this right
/// after the account exists.
Future<void> connectTransport() async {
  final services = AppServices.I;
  try {
    await services.transport.connect();
    await services.transport.publishDirectory(
      ed25519Pub: CryptoService.instance.ed25519PubB64,
      x25519Pub: CryptoService.instance.x25519PubB64,
    );
  } catch (e) {
    debugPrint('connectTransport failed (will rely on reconnect/backoff): $e');
  }
}

/// Wipe all on-device state on sign-out / session-timeout / account change
/// (finding [10]). main.dart's `onSessionTimeout` calls this — the name and
/// signature are a cross-agent contract, do not rename.
///
/// Ends any active discoverable session (so the engine stops advertising a
/// card that is about to vanish), deletes every table, drops the crypto key
/// material, then resets the repositories' in-memory notifiers/streams so the
/// UI immediately reflects an empty, signed-out world. Safe to call before
/// services are installed (no-op).
Future<void> wipeLocalData() async {
  if (!AppServices.isReady) return;
  final services = AppServices.I;

  try {
    await services.session.end();
  } catch (e) {
    debugPrint('wipeLocalData: session.end failed: $e');
  }

  final db = _db;
  if (db != null) {
    await AppDatabase.clearAllData(db);
  }
  await CryptoService.instance.wipe();

  // Reset in-memory state so existing listeners re-emit an empty world.
  await services.settings.load(); // repopulates defaults from the now-empty table
  await services.profile.clear(); // nulls the profile notifier
  _encounters?.refresh();
  _requests?.refresh();
  _connections?.refresh();
  _messages?.refresh();
}

/// Full user-initiated sign-out.
///
/// MetAfter is local-first: the cloud holds auth and blindly relays sealed
/// envelopes, so everything the user can actually read lives on this device
/// and there is no server-side copy to restore from. Signing out is therefore
/// destructive and irreversible — callers MUST confirm with the user first
/// (see `_confirmLogout` in ProfileSettingsScreen).
///
/// Order matters. [wipeLocalData] runs first, while the Cognito session is
/// still valid, so `session.end()` can tell the relay to stop advertising
/// before we drop the credentials it needs. Only then do we revoke auth, clear
/// the persisted signup draft, and delete the profile photo off disk.
///
/// Every step is individually guarded: a failure partway through must not
/// leave the user stuck in a signed-in-looking app with half-deleted data, so
/// we push through to the end and let the caller route to signup regardless.
Future<void> signOutAndWipe() async {
  // Capture the on-disk photo paths before the draft is cleared.
  final photoPaths = <String>[
    ?SignupDraft.instance.photoPath,
    ?SignupDraft.instance.selfiePath,
  ];

  try {
    await wipeLocalData();
  } catch (e) {
    debugPrint('signOutAndWipe: wipeLocalData failed: $e');
  }

  try {
    await CognitoAuthService.instance.signOut();
  } catch (e) {
    debugPrint('signOutAndWipe: cognito signOut failed: $e');
  }

  try {
    await SignupDraft.instance.signOut();
  } catch (e) {
    debugPrint('signOutAndWipe: draft signOut failed: $e');
  }

  // Belt and braces: drops anything the individual wipes above missed —
  // crypto.*, cognito.*, and the app's own token keys all share this store.
  try {
    await SecureStorageService().clearAll();
  } catch (e) {
    debugPrint('signOutAndWipe: secure storage clear failed: $e');
  }

  await _deleteProfilePhotos(photoPaths);
}

/// Remove profile imagery copied into the app documents directory.
///
/// The DB row and the draft key both go, but the JPEG itself would otherwise
/// survive a sign-out and be visible to the next account on a shared device.
/// Covers the known stable name as well as whatever the draft was pointing at.
Future<void> _deleteProfilePhotos(List<String> draftPaths) async {
  final targets = {...draftPaths};
  try {
    final dir = await getApplicationDocumentsDirectory();
    targets.add('${dir.path}/profile_photo.jpg');
  } catch (e) {
    debugPrint('signOutAndWipe: documents dir lookup failed: $e');
  }

  for (final path in targets) {
    if (path.isEmpty) continue;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (e) {
      debugPrint('signOutAndWipe: could not delete $path: $e');
    }
  }
}

/// Tear down long-lived listeners/timers (tests, sign-out).
Future<void> disposeAppServices() async {
  await _router?.dispose();
  _router = null;
  _messaging?.dispose();
  _messaging = null;
  _db = null;
  _encounters = null;
  _requests = null;
  _connections = null;
  _messages = null;
}
