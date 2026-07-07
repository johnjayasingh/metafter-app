import 'dart:async';

import 'package:flutter/foundation.dart';

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
import '../db/settings_repository_impl.dart';
import '../proximity/ble_proximity_engine.dart';
import '../proximity/proximity_engine.dart';
import '../proximity/simulated_proximity_engine.dart';
import '../transport/relay_transport_client.dart';
import 'app_services.dart';
import 'connection_service_impl.dart';
import 'envelope_router.dart';
import 'inbound_handler.dart';
import 'message_service_impl.dart';
import 'session_service_impl.dart';

EnvelopeRouter? _router;
MessageServiceImpl? _messaging;

/// Builds the whole service graph and installs it as [AppServices.I].
///
/// Called once from `bootstrap()` in main.dart, after EnvironmentConfig is
/// set. [simulated] selects [SimulatedProximityEngine] (local/dev flavors,
/// simulators) over the real [BleProximityEngine].
///
/// The relay transport is connected lazily: immediately when a profile
/// already exists (returning user), otherwise not until the signup flow
/// calls [connectTransport] after account creation.
Future<void> initAppServices({bool simulated = false}) async {
  // 1. Identity keys (generate on first run).
  await CryptoService.instance.init();

  // 2. Local database + repositories.
  final db = await AppDatabase.openAppDatabase();
  final settings = SettingsRepositoryImpl(db);
  final profile = ProfileRepositoryImpl(db, settings);
  final encounters = EncounterRepositoryImpl(db);
  final requests = RequestRepositoryImpl(db);
  final connections = ConnectionRepositoryImpl(db);
  final messages = MessageRepositoryImpl(db);
  await settings.load();
  await profile.load();

  // 3. Channels.
  final ProximityEngine engine =
      simulated ? SimulatedProximityEngine() : BleProximityEngine();
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

/// Tear down long-lived listeners/timers (tests, sign-out).
Future<void> disposeAppServices() async {
  await _router?.dispose();
  _router = null;
  _messaging?.dispose();
  _messaging = null;
}
