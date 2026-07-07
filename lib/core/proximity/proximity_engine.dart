import 'dart:typed_data';

import '../domain/models.dart';

/// Abstraction over the device-to-device proximity channel.
///
/// Two implementations:
///  * [BleProximityEngine] — real BLE: central scan (flutter_blue_plus) +
///    peripheral advertise / GATT server (bluetooth_low_energy).
///  * [SimulatedProximityEngine] — deterministic fake peers for local/dev
///    flavors and simulators (iOS simulators cannot advertise BLE).
///
/// The engine deals in [ProfileCard]s and opaque encrypted frames; it never
/// touches the network or the database. Orchestration (persisting encounters,
/// creating requests, routing chat frames) is SessionService's job.
abstract class ProximityEngine {
  /// Latest snapshot of everyone currently in range (already filtered by the
  /// session's distance budget, smoothed distances, sorted nearest-first).
  /// Emits a new list whenever membership or distances change.
  Stream<List<NearbyPeer>> get nearbyPeers;

  /// Inbound protocol events (requests / responses / chat frames received
  /// over the local channel).
  Stream<PeerEvent> get events;

  bool get isRunning;

  /// Start advertising (unless [SessionConfig.incognito]) and scanning.
  Future<void> startSession(SessionConfig config);

  /// Stop advertising + scanning. Safe to call when not running.
  Future<void> stopSession();

  /// Deliver a connect request to a peer currently in range.
  /// Returns true when the peer's device acknowledged the GATT write.
  Future<bool> sendRequest(String peerSub, ConnectRequestPayload payload);

  /// Deliver an accept/decline for a previously received request.
  Future<bool> sendResponse(String peerSub, ConnectResponsePayload payload);

  /// Deliver an opaque encrypted chat frame to a peer in range.
  Future<bool> sendFrame(String peerSub, Uint8List frame);

  /// Whether this peer is currently in BLE range (drives the "nearby"
  /// presence chip in chat and the BLE-vs-relay routing decision).
  bool isNearby(String peerSub);

  /// Live ranging for the Find Person screen: smoothed distance in meters +
  /// coarse relative bearing in radians (0 = ahead). Emits until the peer is
  /// lost. Bearing is an RSSI-gradient/compass estimate — see DESIGN_SPEC §8.
  Stream<RangeSample> range(String peerSub);

  Future<void> dispose();
}

class SessionConfig {
  const SessionConfig({
    required this.duration,
    required this.maxMeters,
    required this.mood,
    required this.myCard,
    this.incognito = false,
  });

  final Duration duration;

  /// Distance budget (2/5/10 m) — peers estimated beyond it are not surfaced.
  final double maxMeters;
  final MoodRing mood;

  /// Card served to peers that read our ProfileCard characteristic. Already
  /// filtered by privacy settings by the caller.
  final ProfileCard myCard;

  /// Scan without advertising.
  final bool incognito;
}

class NearbyPeer {
  const NearbyPeer({
    required this.eid,
    required this.meters,
    required this.mood,
    required this.lastSeen,
    this.card,
    this.rssi,
  });

  /// Hex ephemeral id from the advertisement.
  final String eid;

  /// Smoothed distance estimate.
  final double meters;
  final MoodRing mood;
  final DateTime lastSeen;

  /// Populated once the profile card has been read over GATT (may lag the
  /// first sighting by a second or two).
  final ProfileCard? card;
  final int? rssi;

  String get displayKey => card?.sub.isNotEmpty == true ? card!.sub : eid;
}

class RangeSample {
  const RangeSample({required this.meters, required this.bearing});

  final double meters;

  /// Radians relative to the user's current heading; 0 = straight ahead,
  /// positive = clockwise (to the right).
  final double bearing;
}

class ConnectRequestPayload {
  const ConnectRequestPayload({
    required this.requestId,
    required this.senderCard,
    this.note,
  });

  final String requestId;
  final ProfileCard senderCard;
  final String? note;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'card': senderCard.toJson(),
        if (note != null) 'note': note,
      };

  static ConnectRequestPayload fromJson(Map<String, dynamic> j) =>
      ConnectRequestPayload(
        requestId: j['requestId'] as String,
        senderCard:
            ProfileCard.fromJson(j['card'] as Map<String, dynamic>),
        note: j['note'] as String?,
      );
}

class ConnectResponsePayload {
  const ConnectResponsePayload({
    required this.requestId,
    required this.accepted,
    required this.responderCard,
  });

  final String requestId;
  final bool accepted;
  final ProfileCard responderCard;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'accepted': accepted,
        'card': responderCard.toJson(),
      };

  static ConnectResponsePayload fromJson(Map<String, dynamic> j) =>
      ConnectResponsePayload(
        requestId: j['requestId'] as String,
        accepted: j['accepted'] as bool,
        responderCard:
            ProfileCard.fromJson(j['card'] as Map<String, dynamic>),
      );
}

/// Inbound events surfaced by the engine.
sealed class PeerEvent {
  const PeerEvent();
}

class PeerRequestReceived extends PeerEvent {
  const PeerRequestReceived(this.payload);
  final ConnectRequestPayload payload;
}

class PeerResponseReceived extends PeerEvent {
  const PeerResponseReceived(this.payload);
  final ConnectResponsePayload payload;
}

/// An encrypted chat frame arrived over BLE from [senderSub].
class PeerFrameReceived extends PeerEvent {
  const PeerFrameReceived(this.senderSub, this.frame);
  final String senderSub;
  final Uint8List frame;
}
