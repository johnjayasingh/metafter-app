import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/proximity/proximity_engine.dart';
import 'package:metafter/core/services/app_services.dart';
import 'package:metafter/core/services/services.dart';

import '../services/fakes.dart';

/// Shell-level fakes on top of test/services/fakes.dart (owned by the
/// service-layer module — do not edit it): the orchestration services the
/// Home shell talks to, plus a helper that installs a complete AppServices
/// graph backed entirely by fakes.

/// SessionService fake. Idle→active flips synchronously on [start] (no
/// ticker timers, so widget tests never leak pending timers). When built
/// with an [engine], [start]/[end] drive it and its nearbyPeers stream is
/// piped through [nearby] — pair it with a SimulatedProximityEngine to
/// exercise the radar for real.
class FakeSessionService implements SessionService {
  FakeSessionService({
    ProximityEngine? engine,
    this.duration = const Duration(hours: 4),
    this.maxMeters = 5,
    ProfileCard? myCard,
  })  : _engine = engine,
        _myCard = myCard ?? card('me', name: 'Me');

  final ProximityEngine? _engine;
  final Duration duration;
  final double maxMeters;
  final ProfileCard _myCard;

  /// Non-null → the next [start] fails with this user-displayable message.
  String? nextStartError;

  final ValueNotifier<SessionState> stateNotifier =
      ValueNotifier<SessionState>(const SessionIdle());
  final ValueNotifier<Duration> remainingNotifier =
      ValueNotifier<Duration>(Duration.zero);

  final StreamController<List<NearbyPeer>> _nearbyCtrl =
      StreamController<List<NearbyPeer>>.broadcast();
  List<NearbyPeer> _lastNearby = const [];
  StreamSubscription<List<NearbyPeer>>? _engineSub;

  @override
  ValueListenable<SessionState> get state => stateNotifier;

  @override
  ValueListenable<Duration> get remaining => remainingNotifier;

  @override
  Stream<List<NearbyPeer>> get nearby async* {
    yield _lastNearby;
    yield* _nearbyCtrl.stream;
  }

  /// Test hook: push a nearby-peers snapshot to the radar.
  void emitNearby(List<NearbyPeer> peers) {
    _lastNearby = peers;
    if (!_nearbyCtrl.isClosed) _nearbyCtrl.add(peers);
  }

  /// Test hook: drive the countdown (e.g. into the final-30s pulse window).
  void setRemaining(Duration d) => remainingNotifier.value = d;

  @override
  Future<String?> start() async {
    if (stateNotifier.value is! SessionIdle) return null;
    final error = nextStartError;
    if (error != null) return error;

    final engine = _engine;
    if (engine != null) {
      await engine.startSession(SessionConfig(
        duration: duration,
        maxMeters: maxMeters,
        mood: MoodRing.networking,
        myCard: _myCard,
      ));
      _engineSub = engine.nearbyPeers.listen(emitNearby);
    }
    remainingNotifier.value = duration;
    stateNotifier.value = SessionActive(
      endsAt: DateTime.now().add(duration),
      incognito: false,
    );
    return null;
  }

  @override
  Future<void> end() async {
    // Not awaited: broadcast-subscription cancel futures do not complete
    // under the widget-test FakeAsync zone and would wedge end().
    unawaited(_engineSub?.cancel());
    _engineSub = null;
    await _engine?.stopSession();
    stateNotifier.value = const SessionIdle();
    remainingNotifier.value = Duration.zero;
    emitNearby(const []);
  }
}

class FakeConnectionService implements ConnectionService {
  final List<ConnectionRequest> accepted = [];
  final List<ConnectionRequest> declined = [];
  final List<String> disconnected = [];
  SendRequestOutcome sendOutcome = SendRequestOutcome.sentNearby;

  @override
  Future<void> accept(ConnectionRequest request) async =>
      accepted.add(request);

  @override
  Future<void> decline(ConnectionRequest request) async =>
      declined.add(request);

  @override
  Future<void> disconnect(String peerSub) async => disconnected.add(peerSub);

  @override
  Future<SendRequestOutcome> sendRequest({
    required ProfileCard toCard,
    String? note,
    String? encounterId,
  }) async =>
      sendOutcome;
}

class FakeMessageService implements MessageService {
  final Set<String> nearbySubs = {};

  @override
  bool isPeerNearby(String peerSub) => nearbySubs.contains(peerSub);

  @override
  Future<void> markRead(String peerSub) async {}

  @override
  Future<void> react(String peerSub, String messageId, String? emoji) async {}

  @override
  Future<void> send(String peerSub, String body) async {}
}

/// Builds an AppServices graph entirely from fakes and installs it as
/// [AppServices.I]. Returns the graph so tests can reach into the fakes.
AppServices installShellTestServices({
  ProximityEngine? engine,
  FakeSessionService? session,
  FakeRequestRepository? requests,
}) {
  final resolvedEngine = engine ?? FakeProximityEngine();
  final services = AppServices(
    profile: FakeProfileRepository(),
    encounters: FakeEncounterRepository(),
    requests: requests ?? FakeRequestRepository(),
    connections: FakeConnectionRepository(),
    messages: FakeMessageRepository(),
    settings: FakeSettingsRepository(),
    engine: resolvedEngine,
    transport: FakeTransportClient(),
    session: session ?? FakeSessionService(engine: engine),
    connection: FakeConnectionService(),
    messaging: FakeMessageService(),
  );
  AppServices.install(services);
  return services;
}
