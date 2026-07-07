import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/crypto/crypto_service.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/services/connection_service_impl.dart';
import 'package:metafter/core/services/envelope_codec.dart';
import 'package:metafter/core/services/services.dart';
import 'package:metafter/core/transport/envelope.dart';
import 'package:metafter/core/transport/transport_client.dart';

import 'fakes.dart';

void main() {
  late FakeProximityEngine engine;
  late FakeTransportClient transport;
  late FakeProfileRepository profile;
  late FakeRequestRepository requests;
  late FakeConnectionRepository connections;
  late FakeEncounterRepository encounters;
  late FakeSettingsRepository settings;
  late ConnectionServiceImpl service;

  final t0 = DateTime(2026, 7, 7, 12);
  var idCounter = 0;

  setUp(() {
    engine = FakeProximityEngine();
    transport = FakeTransportClient();
    profile = FakeProfileRepository();
    requests = FakeRequestRepository();
    connections = FakeConnectionRepository();
    encounters = FakeEncounterRepository();
    settings = FakeSettingsRepository();
    idCounter = 0;
    service = ConnectionServiceImpl(
      engine: engine,
      transport: transport,
      profile: profile,
      requests: requests,
      connections: connections,
      encounters: encounters,
      settings: settings,
      codec: EnvelopeCodec(
        signer: (json) async => 'fake-sig',
        sealer: (xPub, json) async => const SealedBox(
            ephPubB64: 'eph', nonceB64: 'n', ciphertextB64: 'ct'),
        newId: () => 'env-${++idCounter}',
      ),
      newId: () => 'req-${++idCounter}',
      now: () => t0,
    );
  });

  group('sendRequest Pro gating (DESIGN_SPEC §11.3)', () {
    final peer = card('bob');

    // (isPro, outgoingToday, note, outgoingWithNote) -> expected outcome
    final table = <(bool, int, String?, int, SendRequestOutcome)>[
      // Free tier under the daily quota goes through.
      (false, 0, null, 0, SendRequestOutcome.sentNearby),
      (false, ProLimits.freeRequestsPerDay - 1, null, 0,
          SendRequestOutcome.sentNearby),
      // Daily request quota.
      (false, ProLimits.freeRequestsPerDay, null, 0,
          SendRequestOutcome.quotaExceeded),
      (false, ProLimits.freeRequestsPerDay + 3, null, 0,
          SendRequestOutcome.quotaExceeded),
      (true, ProLimits.freeRequestsPerDay, null, 0,
          SendRequestOutcome.sentNearby),
      // Invitation-note quota (all-time, free tier only).
      (false, 0, 'hi!', 0, SendRequestOutcome.sentNearby),
      (false, 0, 'hi!', ProLimits.freeInviteNotes,
          SendRequestOutcome.noteQuotaExceeded),
      (true, 0, 'hi!', ProLimits.freeInviteNotes,
          SendRequestOutcome.sentNearby),
      // No note -> the note quota is irrelevant.
      (false, 0, null, ProLimits.freeInviteNotes,
          SendRequestOutcome.sentNearby),
      // The daily quota is checked before the note quota.
      (false, ProLimits.freeRequestsPerDay, 'hi!', ProLimits.freeInviteNotes,
          SendRequestOutcome.quotaExceeded),
    ];

    for (final (isPro, outgoing, note, withNote, expected) in table) {
      test(
          'isPro=$isPro outgoingToday=$outgoing note=${note != null} '
          'withNote=$withNote -> $expected', () async {
        settings.isPro.value = isPro;
        requests.outgoingToday = outgoing;
        requests.outgoingWithNote = withNote;
        engine.nearbySubs.add('bob');

        final outcome =
            await service.sendRequest(toCard: peer, note: note);

        expect(outcome, expected);
        final gated = expected == SendRequestOutcome.quotaExceeded ||
            expected == SendRequestOutcome.noteQuotaExceeded;
        // Gated sends must not create rows or hit any channel.
        expect(requests.rows.isEmpty, gated);
        expect(engine.sentRequests.isEmpty, gated);
        expect(transport.sent, isEmpty);
      });
    }
  });

  group('sendRequest delivery', () {
    test('nearby peer -> BLE, row persisted, encounter linked', () async {
      engine.nearbySubs.add('bob');

      final outcome = await service.sendRequest(
          toCard: card('bob'), note: 'expo', encounterId: 'enc-9');

      expect(outcome, SendRequestOutcome.sentNearby);
      final row = requests.rows.values.single;
      expect(row.direction, RequestDirection.outgoing);
      expect(row.status, RequestStatus.pending);
      expect(row.peerSub, 'bob');
      expect(encounters.requested['enc-9'], row.id);
      final (to, payload) = engine.sentRequests.single;
      expect(to, 'bob');
      expect(payload.requestId, row.id);
      expect(payload.note, 'expo');
      expect(payload.senderCard.sub, 'me');
      expect(transport.sent, isEmpty);
    });

    test('out of range -> sealed relay envelope', () async {
      final outcome = await service.sendRequest(toCard: card('bob'));

      expect(outcome, SendRequestOutcome.sentRelay);
      final envelope = transport.sent.single;
      expect(envelope.to, 'bob');
      expect(envelope.kind, EnvelopeKind.connectRequest);
      expect(envelope.ciphertext, 'ct');
      expect(engine.sentRequests, isEmpty);
    });

    test('BLE write fails -> falls back to relay', () async {
      engine.nearbySubs.add('bob');
      engine.bleSendResult = false;

      final outcome = await service.sendRequest(toCard: card('bob'));

      expect(outcome, SendRequestOutcome.sentRelay);
      expect(engine.sentRequests, hasLength(1));
      expect(transport.sent, hasLength(1));
    });

    test('card without keys -> directory lookup', () async {
      transport.directory['bob'] = const DirectoryEntry(
          sub: 'bob', ed25519Pub: 'ed', x25519Pub: 'x');

      final outcome = await service.sendRequest(
          toCard: card('bob', edPub: null, xPub: null));

      expect(outcome, SendRequestOutcome.sentRelay);
    });

    test('no keys anywhere -> failed, row stays pending', () async {
      final outcome = await service.sendRequest(
          toCard: card('bob', edPub: null, xPub: null));

      expect(outcome, SendRequestOutcome.failed);
      expect(requests.rows.values.single.status, RequestStatus.pending);
    });

    test('relay deposit rejected -> failed', () async {
      transport.sendResult = false;

      final outcome = await service.sendRequest(toCard: card('bob'));

      expect(outcome, SendRequestOutcome.failed);
    });
  });

  group('accept / decline / disconnect', () {
    ConnectionRequest incoming() => ConnectionRequest(
          id: 'r1',
          direction: RequestDirection.incoming,
          peerSub: 'bob',
          card: card('bob', name: 'Bob'),
          createdAt: t0,
        );

    test('accept persists the connection and responds over BLE', () async {
      engine.nearbySubs.add('bob');
      await requests.upsert(incoming());

      await service.accept(incoming());

      expect(requests.rows['r1']!.status, RequestStatus.accepted);
      final conn = connections.rows['bob']!;
      expect(conn.card.name, 'Bob');
      expect(conn.moodAtMeet, settings.mood.value);
      final (to, payload) = engine.sentResponses.single;
      expect(to, 'bob');
      expect(payload.accepted, isTrue);
      expect(payload.responderCard.sub, 'me');
    });

    test('accept out of range responds via relay', () async {
      await requests.upsert(incoming());

      await service.accept(incoming());

      expect(connections.rows, contains('bob'));
      final envelope = transport.sent.single;
      expect(envelope.kind, EnvelopeKind.connectResponse);
      expect(envelope.to, 'bob');
    });

    test('decline is silent — status only, nothing sent', () async {
      engine.nearbySubs.add('bob');
      await requests.upsert(incoming());

      await service.decline(incoming());

      expect(requests.rows['r1']!.status, RequestStatus.declined);
      expect(connections.rows, isEmpty);
      expect(engine.sentResponses, isEmpty);
      expect(transport.sent, isEmpty);
    });

    test('disconnect notifies best-effort and removes the row', () async {
      await connections.upsert(
          Connection(peerSub: 'bob', card: card('bob'), connectedAt: t0));

      await service.disconnect('bob');

      expect(connections.rows, isEmpty);
      final envelope = transport.sent.single;
      expect(envelope.kind, EnvelopeKind.disconnect);
    });

    test('disconnect without a connection row still succeeds', () async {
      await service.disconnect('ghost');
      expect(transport.sent, isEmpty);
    });
  });
}
