import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/proximity/proximity_engine.dart';
import 'package:metafter/core/repositories/repositories.dart';
import 'package:metafter/core/services/app_services.dart';
import 'package:metafter/core/services/services.dart';
import 'package:metafter/core/transport/transport_client.dart';

/// Small self-contained fakes for the Discover-module widget tests
/// (independent from test/services/fakes.dart, which must not change).
///
/// Only the members the Discover/Requests screens actually touch are
/// implemented; everything else throws via [noSuchMethod].

class FakeEncounterRepository implements EncounterRepository {
  final List<Encounter> rows = [];
  final _changes = StreamController<void>.broadcast();

  void notify() => _changes.add(null);

  List<Encounter> _forDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final list = rows
        .where((e) =>
            !e.lastSeen.isBefore(start) && e.lastSeen.isBefore(end))
        .toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return list;
  }

  @override
  Stream<List<Encounter>> watchDay(DateTime day) async* {
    yield _forDay(day);
    yield* _changes.stream.map((_) => _forDay(day));
  }

  @override
  Future<List<DateTime>> daysWithEncounters() async {
    final days = <DateTime>{
      for (final e in rows)
        DateTime(e.lastSeen.year, e.lastSeen.month, e.lastSeen.day),
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return days;
  }

  @override
  Future<void> markRequested(String encounterId, String requestId) async {
    final i = rows.indexWhere((e) => e.id == encounterId);
    if (i >= 0) rows[i] = rows[i].copyWith(sentRequestId: requestId);
    notify();
  }

  @override
  Future<String> recordSighting(NearbyPeer peer,
      {Duration mergeWindow = const Duration(minutes: 30)}) async {
    return 'enc-${rows.length}';
  }

  @override
  Future<void> sweepOlderThan(Duration age) async {}
}

class FakeRequestRepository implements RequestRepository {
  final Map<String, ConnectionRequest> rows = {};
  final _changes = StreamController<void>.broadcast();

  void notify() => _changes.add(null);

  List<ConnectionRequest> _pending() => rows.values
      .where((r) =>
          r.direction == RequestDirection.incoming &&
          r.status == RequestStatus.pending)
      .toList();

  @override
  Stream<List<ConnectionRequest>> watchIncomingPending() async* {
    yield _pending();
    yield* _changes.stream.map((_) => _pending());
  }

  @override
  Stream<int> watchIncomingPendingCount() =>
      watchIncomingPending().map((l) => l.length);

  @override
  Stream<List<ConnectionRequest>> watchOutgoing() async* {
    yield const [];
  }

  @override
  Future<ConnectionRequest?> byId(String id) async => rows[id];

  @override
  Future<void> upsert(ConnectionRequest request) async {
    rows[request.id] = request;
    notify();
  }

  @override
  Future<void> setStatus(String id, RequestStatus status) async {
    final row = rows[id];
    if (row != null) rows[id] = row.copyWith(status: status);
    notify();
  }

  @override
  Future<int> countOutgoingSince(DateTime since) async => 0;

  @override
  Future<int> countOutgoingWithNote() async => 0;
}

class FakeConnectionService implements ConnectionService {
  FakeConnectionService(this.encounters, this.requests);

  final FakeEncounterRepository encounters;
  final FakeRequestRepository requests;

  SendRequestOutcome outcome = SendRequestOutcome.sentNearby;
  final List<({ProfileCard toCard, String? note, String? encounterId})>
      sendCalls = [];
  final List<ConnectionRequest> accepted = [];
  final List<ConnectionRequest> declined = [];
  final List<String> disconnected = [];

  @override
  Future<SendRequestOutcome> sendRequest({
    required ProfileCard toCard,
    String? note,
    String? encounterId,
  }) async {
    sendCalls.add((toCard: toCard, note: note, encounterId: encounterId));
    final sent = outcome == SendRequestOutcome.sentNearby ||
        outcome == SendRequestOutcome.sentRelay;
    if (sent && encounterId != null) {
      await encounters.markRequested(encounterId, 'req-${sendCalls.length}');
    }
    return outcome;
  }

  @override
  Future<void> accept(ConnectionRequest request) async {
    accepted.add(request);
    await requests.setStatus(request.id, RequestStatus.accepted);
  }

  @override
  Future<void> decline(ConnectionRequest request) async {
    declined.add(request);
    await requests.setStatus(request.id, RequestStatus.declined);
  }

  @override
  Future<void> disconnect(String peerSub) async {
    disconnected.add(peerSub);
  }
}

class FakeProximityEngine implements ProximityEngine {
  final Set<String> nearbySubs = {};

  @override
  bool isNearby(String peerSub) => nearbySubs.contains(peerSub);

  @override
  Stream<RangeSample> range(String peerSub) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class FakeSettingsRepository implements SettingsRepository {
  @override
  final ValueNotifier<bool> use24hTime = ValueNotifier(false);

  @override
  final ValueNotifier<bool> reduceMotion = ValueNotifier(true);

  @override
  final ValueNotifier<bool> isPro = ValueNotifier(false);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class StubProfileRepository implements ProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class StubConnectionRepository implements ConnectionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class StubMessageRepository implements MessageRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class StubTransportClient implements TransportClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class StubSessionService implements SessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class StubMessageService implements MessageService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Builds the fake service graph and installs it as [AppServices.I].
/// Returns the fakes the tests interact with.
({
  FakeEncounterRepository encounters,
  FakeRequestRepository requests,
  FakeConnectionService connection,
  FakeProximityEngine engine,
  FakeSettingsRepository settings,
}) installFakeServices() {
  final encounters = FakeEncounterRepository();
  final requests = FakeRequestRepository();
  final engine = FakeProximityEngine();
  final settings = FakeSettingsRepository();
  final connection = FakeConnectionService(encounters, requests);

  AppServices.install(AppServices(
    profile: StubProfileRepository(),
    encounters: encounters,
    requests: requests,
    connections: StubConnectionRepository(),
    messages: StubMessageRepository(),
    settings: settings,
    engine: engine,
    transport: StubTransportClient(),
    session: StubSessionService(),
    connection: connection,
    messaging: StubMessageService(),
  ));

  return (
    encounters: encounters,
    requests: requests,
    connection: connection,
    engine: engine,
    settings: settings,
  );
}
