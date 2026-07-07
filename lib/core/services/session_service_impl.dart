import 'dart:async';

import 'package:flutter/foundation.dart';

import '../proximity/proximity_engine.dart';
import '../repositories/repositories.dart';
import 'envelope_router.dart';
import 'inbound_handler.dart';
import 'services.dart';

/// Discoverable-session orchestrator (DESIGN_SPEC §4).
///
/// Reads the user's session preferences from [SettingsRepository], builds the
/// privacy-filtered card, drives the [ProximityEngine], ticks the countdown,
/// records crossed-path encounters, and forwards inbound engine events to the
/// shared [InboundHandler]/[EnvelopeRouter] so BLE arrivals behave exactly
/// like relay arrivals.
class SessionServiceImpl implements SessionService {
  SessionServiceImpl({
    required ProximityEngine engine,
    required ProfileRepository profile,
    required EncounterRepository encounters,
    required SettingsRepository settings,
    required InboundHandler inbound,
    required EnvelopeRouter router,
    DateTime Function()? now,
  })  : _engine = engine,
        _profile = profile,
        _encounters = encounters,
        _settings = settings,
        _inbound = inbound,
        _router = router,
        _now = now ?? DateTime.now;

  final ProximityEngine _engine;
  final ProfileRepository _profile;
  final EncounterRepository _encounters;
  final SettingsRepository _settings;
  final InboundHandler _inbound;
  final EnvelopeRouter _router;
  final DateTime Function() _now;

  /// Minimum interval between encounter-ledger writes for the same peer.
  static const sightingThrottle = Duration(seconds: 15);

  final _state = ValueNotifier<SessionState>(const SessionIdle());
  final _remaining = ValueNotifier<Duration>(Duration.zero);
  final _nearbyCtrl = StreamController<List<NearbyPeer>>.broadcast();
  List<NearbyPeer> _lastNearby = const [];

  Timer? _ticker;
  StreamSubscription<List<NearbyPeer>>? _peersSub;
  StreamSubscription<PeerEvent>? _eventsSub;
  final Map<String, DateTime> _lastSightingWrite = {};

  @override
  ValueListenable<SessionState> get state => _state;

  @override
  ValueListenable<Duration> get remaining => _remaining;

  @override
  Stream<List<NearbyPeer>> get nearby async* {
    yield _lastNearby;
    yield* _nearbyCtrl.stream;
  }

  @override
  Future<String?> start() async {
    // Idempotent: starting while active/starting is a no-op success.
    if (_state.value is! SessionIdle) return null;
    _state.value = const SessionStarting();

    final duration = _settings.discoverableDuration.value;
    final incognito = _settings.incognitoScan.value;
    try {
      final card = await _profile.buildCard();
      await _engine.startSession(SessionConfig(
        duration: duration,
        maxMeters: _settings.distanceBudget.value,
        mood: _settings.mood.value,
        myCard: card,
        incognito: incognito,
      ));
    } catch (e) {
      _state.value = const SessionIdle();
      return _describeStartError(e);
    }

    final endsAt = _now().add(duration);
    _state.value = SessionActive(endsAt: endsAt, incognito: incognito);
    _remaining.value = duration;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = endsAt.difference(_now());
      if (left <= Duration.zero) {
        _remaining.value = Duration.zero;
        unawaited(end()); // auto-end at zero (DESIGN_SPEC §4.2)
      } else {
        _remaining.value = left;
      }
    });

    _peersSub = _engine.nearbyPeers.listen(_onNearby);
    _eventsSub = _engine.events.listen(_onPeerEvent);
    return null;
  }

  @override
  Future<void> end() async {
    _ticker?.cancel();
    _ticker = null;
    await _peersSub?.cancel();
    _peersSub = null;
    await _eventsSub?.cancel();
    _eventsSub = null;
    _lastSightingWrite.clear();

    try {
      await _engine.stopSession();
    } catch (e) {
      debugPrint('SessionService: stopSession failed: $e');
    }

    _state.value = const SessionIdle();
    _remaining.value = Duration.zero;
    _lastNearby = const [];
    if (!_nearbyCtrl.isClosed) _nearbyCtrl.add(const []);
  }

  Future<void> dispose() async {
    await end();
    await _nearbyCtrl.close();
    _state.dispose();
    _remaining.dispose();
  }

  void _onNearby(List<NearbyPeer> peers) {
    _lastNearby = peers;
    if (!_nearbyCtrl.isClosed) _nearbyCtrl.add(peers);

    // Crossed-paths ledger: only peers whose card we actually read count,
    // throttled to one write per peer per [sightingThrottle].
    final now = _now();
    for (final peer in peers) {
      if (peer.card == null) continue;
      final key = peer.displayKey;
      final last = _lastSightingWrite[key];
      if (last != null && now.difference(last) < sightingThrottle) continue;
      _lastSightingWrite[key] = now;
      unawaited(_encounters.recordSighting(peer).catchError((Object e) {
        debugPrint('SessionService: recordSighting failed: $e');
        return '';
      }));
    }
  }

  void _onPeerEvent(PeerEvent event) {
    unawaited(switch (event) {
      PeerRequestReceived(:final payload) =>
        _inbound.handleRequest(payload, via: InboundVia.ble),
      PeerResponseReceived(:final payload) => _inbound.handleResponse(payload),
      PeerFrameReceived(:final senderSub, :final frame) =>
        _router.handleFrame(senderSub, frame),
    });
  }

  /// Map engine failures to the user-displayable strings the Home page shows.
  String _describeStartError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('permission') || text.contains('unauthorized')) {
      return 'Bluetooth permission is required — enable it in Settings';
    }
    if (text.contains('off') ||
        text.contains('disabled') ||
        text.contains('poweredoff')) {
      return 'Bluetooth is off';
    }
    if (text.contains('unsupported') || text.contains('not supported')) {
      return 'Bluetooth LE is not supported on this device';
    }
    return "Couldn't start discovery. Please try again.";
  }
}
