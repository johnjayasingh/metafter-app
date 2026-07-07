import 'package:flutter/foundation.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/proximity/proximity_engine.dart';
import 'package:metafter/core/services/app_services.dart';
import 'package:metafter/core/services/services.dart';

import '../services/fakes.dart';

/// Minimal service stubs — the settings screens never touch these, but the
/// [AppServices] constructor requires the full graph.
class FakeSessionService implements SessionService {
  final ValueNotifier<SessionState> _state =
      ValueNotifier<SessionState>(const SessionIdle());
  final ValueNotifier<Duration> _remaining =
      ValueNotifier<Duration>(Duration.zero);

  @override
  ValueListenable<SessionState> get state => _state;

  @override
  ValueListenable<Duration> get remaining => _remaining;

  @override
  Stream<List<NearbyPeer>> get nearby => Stream.value(const []);

  @override
  Future<String?> start() async => null;

  @override
  Future<void> end() async {}
}

class FakeConnectionService implements ConnectionService {
  @override
  Future<SendRequestOutcome> sendRequest({
    required ProfileCard toCard,
    String? note,
    String? encounterId,
  }) async =>
      SendRequestOutcome.sentNearby;

  @override
  Future<void> accept(ConnectionRequest request) async {}

  @override
  Future<void> decline(ConnectionRequest request) async {}

  @override
  Future<void> disconnect(String peerSub) async {}
}

class FakeMessageService implements MessageService {
  @override
  Future<void> send(String peerSub, String body) async {}

  @override
  Future<void> react(String peerSub, String messageId, String? emoji) async {}

  @override
  Future<void> markRead(String peerSub) async {}

  @override
  bool isPeerNearby(String peerSub) => false;
}

/// Installs [AppServices.I] backed entirely by in-memory fakes and returns
/// the handles the settings tests assert against.
({FakeSettingsRepository settings, FakeProfileRepository profile})
    installFakeServices({MyProfile? me}) {
  final settings = FakeSettingsRepository();
  final profile = FakeProfileRepository(
    me: me ??
        const MyProfile(
          sub: 'me',
          name: 'Luna Ray',
          designation: 'UI / UX Designer',
          company: 'Techinorm',
        ),
  );
  AppServices.install(AppServices(
    profile: profile,
    encounters: FakeEncounterRepository(),
    requests: FakeRequestRepository(),
    connections: FakeConnectionRepository(),
    messages: FakeMessageRepository(),
    settings: settings,
    engine: FakeProximityEngine(),
    transport: FakeTransportClient(),
    session: FakeSessionService(),
    connection: FakeConnectionService(),
    messaging: FakeMessageService(),
  ));
  return (settings: settings, profile: profile);
}
