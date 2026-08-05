import 'dart:async';

import 'package:flutter/foundation.dart';

import 'proximity_engine.dart';

/// Routes every call to either the real BLE engine or the simulated one,
/// following a live flag.
///
/// The simulated engine exists so the app can be demoed without BLE hardware,
/// but it must never surface invented people as if they were genuinely nearby.
/// Which engine is in charge is therefore a property of the user's "Demo
/// Content" switch, not of the build flavor: with the switch OFF, discovery,
/// connect requests, chat frames and ranging all run over real BLE, even in
/// the dev flavor.
///
/// Flipping the switch mid-session hands the running session over: the old
/// engine is stopped, its peers are dropped (they are not nearby by the new
/// engine's reckoning), and the session is restarted on the new one.
class SwitchableProximityEngine implements ProximityEngine {
  SwitchableProximityEngine({
    required ProximityEngine real,
    required ProximityEngine simulated,
    required this.useSimulated,
  }) : _real = real,
       _simulated = simulated {
    _attached = _target;
    _listen(_attached);
    useSimulated.addListener(_onFlip);
  }

  final ProximityEngine _real;
  final ProximityEngine _simulated;

  /// True = serve fake peers. Read live, never cached.
  final ValueListenable<bool> useSimulated;

  final _nearby = StreamController<List<NearbyPeer>>.broadcast();
  final _events = StreamController<PeerEvent>.broadcast();
  StreamSubscription<List<NearbyPeer>>? _nearbySub;
  StreamSubscription<PeerEvent>? _eventSub;

  /// The engine currently wired to the outward streams.
  late ProximityEngine _attached;

  /// Kept so a flip can restart an in-flight session on the other engine.
  SessionConfig? _config;

  ProximityEngine get _target => useSimulated.value ? _simulated : _real;

  void _listen(ProximityEngine e) {
    _nearbySub = e.nearbyPeers.listen(_nearby.add);
    _eventSub = e.events.listen(_events.add);
  }

  void _onFlip() {
    if (identical(_target, _attached)) return;
    unawaited(_handOver());
  }

  Future<void> _handOver() async {
    final previous = _attached;
    final next = _target;
    final config = _config;

    await _nearbySub?.cancel();
    await _eventSub?.cancel();
    if (previous.isRunning) {
      try {
        await previous.stopSession();
      } catch (e) {
        debugPrint('Proximity hand-over: stopping the old engine failed: $e');
      }
    }

    _attached = next;
    _listen(next);
    // Whoever was in range a moment ago was the OTHER engine's idea of nearby.
    if (!_nearby.isClosed) _nearby.add(const []);

    if (config != null) {
      try {
        await next.startSession(config);
      } catch (e) {
        debugPrint('Proximity hand-over: restarting the session failed: $e');
      }
    }
  }

  @override
  Stream<List<NearbyPeer>> get nearbyPeers => _nearby.stream;

  @override
  Stream<PeerEvent> get events => _events.stream;

  @override
  bool get isRunning => _attached.isRunning;

  @override
  Future<void> startSession(SessionConfig config) {
    _config = config;
    return _attached.startSession(config);
  }

  @override
  Future<void> stopSession() {
    _config = null;
    return _attached.stopSession();
  }

  @override
  Future<bool> sendRequest(String peerSub, ConnectRequestPayload payload) =>
      _attached.sendRequest(peerSub, payload);

  @override
  Future<bool> sendResponse(String peerSub, ConnectResponsePayload payload) =>
      _attached.sendResponse(peerSub, payload);

  @override
  Future<bool> sendFrame(String peerSub, Uint8List frame) =>
      _attached.sendFrame(peerSub, frame);

  @override
  bool isNearby(String peerSub) => _attached.isNearby(peerSub);

  @override
  Stream<RangeSample> range(String peerSub) => _attached.range(peerSub);

  @override
  Future<void> dispose() async {
    useSimulated.removeListener(_onFlip);
    await _nearbySub?.cancel();
    await _eventSub?.cancel();
    await _nearby.close();
    await _events.close();
    await _real.dispose();
    await _simulated.dispose();
  }
}
