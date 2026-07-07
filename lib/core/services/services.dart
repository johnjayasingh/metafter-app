import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../proximity/proximity_engine.dart';

/// Service contracts — the orchestration layer between UI and the
/// engine/transport/repositories. Concrete implementations live beside this
/// file; UI reaches them through [AppServices] (see app_services.dart).

// ---------------------------------------------------------------------------
// Discoverable session
// ---------------------------------------------------------------------------

sealed class SessionState {
  const SessionState();
}

class SessionIdle extends SessionState {
  const SessionIdle();
}

class SessionStarting extends SessionState {
  const SessionStarting();
}

class SessionActive extends SessionState {
  const SessionActive({required this.endsAt, required this.incognito});
  final DateTime endsAt;
  final bool incognito;
}

/// Owns the discoverable-session lifecycle (Home ⇄ Meet in DESIGN_SPEC §4):
/// builds the privacy-filtered card, starts/stops the [ProximityEngine],
/// ticks the countdown, records encounters, and turns engine events into
/// repository writes.
abstract class SessionService {
  ValueListenable<SessionState> get state;

  /// Ticks every second while active; Duration.zero when idle.
  ValueListenable<Duration> get remaining;

  /// Live nearby peers (passthrough of the engine stream while active;
  /// empty list when idle).
  Stream<List<NearbyPeer>> get nearby;

  /// Uses SettingsRepository's duration/distance/mood/incognito values.
  /// Returns null on success or a user-displayable error message
  /// (e.g. "Bluetooth is off").
  Future<String?> start();

  Future<void> end();
}

// ---------------------------------------------------------------------------
// Connections
// ---------------------------------------------------------------------------

enum SendRequestOutcome {
  /// Delivered device-to-device over BLE.
  sentNearby,

  /// Peer out of range — E2E envelope deposited with the relay.
  sentRelay,

  /// Free-tier connection-request quota hit — show the Pro upsell.
  quotaExceeded,

  /// Free-tier invitation-note quota hit — show the Pro upsell.
  noteQuotaExceeded,

  failed,
}

/// Free/Pro limits (DESIGN_SPEC §11.3). Gating is real; purchase is not
/// wired this phase.
abstract final class ProLimits {
  static const int freeRequestsPerDay = 5;
  static const int freeInviteNotes = 1;
  static const int proInviteNotes = 5;
}

abstract class ConnectionService {
  /// Send a connect request. Prefers BLE when the peer is in range, falls
  /// back to the relay (requires the card to carry a sub + keys).
  /// [encounterId] links the request back to the Discover ledger row.
  Future<SendRequestOutcome> sendRequest({
    required ProfileCard toCard,
    String? note,
    String? encounterId,
  });

  /// Accept an incoming request: persist the connection, create the thread,
  /// and deliver the response (BLE or relay).
  Future<void> accept(ConnectionRequest request);

  /// Decline silently (no notification to the sender by design).
  Future<void> decline(ConnectionRequest request);

  /// Remove the connection, notify the peer, and wipe shared state
  /// (thread retention is the caller's choice via MessageRepository).
  Future<void> disconnect(String peerSub);
}

// ---------------------------------------------------------------------------
// Messaging
// ---------------------------------------------------------------------------

abstract class MessageService {
  /// Encrypt + deliver (BLE when nearby, relay otherwise), persist locally,
  /// honouring the thread's disappearing TTL.
  Future<void> send(String peerSub, String body);

  /// Set/clear an emoji reaction and propagate it to the peer.
  Future<void> react(String peerSub, String messageId, String? emoji);

  /// Mark thread read locally and emit read receipts if enabled.
  Future<void> markRead(String peerSub);

  /// Presence for the chat header chip / find-person entry.
  bool isPeerNearby(String peerSub);
}
