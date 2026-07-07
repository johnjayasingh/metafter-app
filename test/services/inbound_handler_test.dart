import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/proximity/proximity_engine.dart';
import 'package:metafter/core/services/inbound_handler.dart';

import 'fakes.dart';

void main() {
  late FakeRequestRepository requests;
  late FakeConnectionRepository connections;
  late FakeMessageRepository messages;
  late List<(String peerSub, String messageId, String status)> receipts;
  late InboundHandler handler;

  final t0 = DateTime(2026, 7, 7, 12);

  setUp(() {
    requests = FakeRequestRepository();
    connections = FakeConnectionRepository();
    messages = FakeMessageRepository();
    receipts = [];
    handler = InboundHandler(
      requests: requests,
      connections: connections,
      messages: messages,
      sendReceipt: (peerSub, messageId, status) async =>
          receipts.add((peerSub, messageId, status)),
      now: () => t0,
    );
  });

  group('handleRequest', () {
    test('stores an incoming pending request', () async {
      await handler.handleRequest(
        ConnectRequestPayload(
            requestId: 'r1', senderCard: card('alice'), note: 'hi'),
        via: InboundVia.relay,
      );

      final row = requests.rows['r1']!;
      expect(row.direction, RequestDirection.incoming);
      expect(row.status, RequestStatus.pending);
      expect(row.peerSub, 'alice');
      expect(row.note, 'hi');
      expect(row.createdAt, t0);
    });

    test('dedupes by requestId (BLE then relay)', () async {
      final payload =
          ConnectRequestPayload(requestId: 'r1', senderCard: card('alice'));
      await handler.handleRequest(payload);
      await requests.setStatus('r1', RequestStatus.accepted);

      await handler.handleRequest(payload, via: InboundVia.relay);

      expect(requests.rows.length, 1);
      // The duplicate must not reset the row back to pending.
      expect(requests.rows['r1']!.status, RequestStatus.accepted);
    });
  });

  group('handleResponse', () {
    setUp(() async {
      await requests.upsert(ConnectionRequest(
        id: 'r1',
        direction: RequestDirection.outgoing,
        peerSub: 'bob',
        card: card('bob'),
        createdAt: t0,
      ));
    });

    test('accepted: marks the request and stores the connection', () async {
      await handler.handleResponse(ConnectResponsePayload(
        requestId: 'r1',
        accepted: true,
        responderCard: card('bob', name: 'Bob'),
      ));

      expect(requests.rows['r1']!.status, RequestStatus.accepted);
      final conn = connections.rows['bob']!;
      expect(conn.card.name, 'Bob');
      expect(conn.connectedAt, t0);
    });

    test('declined: marks the request, no connection', () async {
      await handler.handleResponse(ConnectResponsePayload(
        requestId: 'r1',
        accepted: false,
        responderCard: card('bob'),
      ));

      expect(requests.rows['r1']!.status, RequestStatus.declined);
      expect(connections.rows, isEmpty);
    });

    test('unknown requestId is dropped', () async {
      await handler.handleResponse(ConnectResponsePayload(
        requestId: 'nope',
        accepted: true,
        responderCard: card('bob'),
      ));

      expect(connections.rows, isEmpty);
    });
  });

  group('handleMessage', () {
    setUp(() async {
      await connections.upsert(Connection(
        peerSub: 'bob',
        card: card('bob', name: 'Bob'),
        connectedAt: t0,
      ));
    });

    test('appends inbound message with the connection card and sends a '
        'delivered receipt', () async {
      final sentAt = t0.subtract(const Duration(minutes: 1));
      await handler.handleMessage(
          from: 'bob', messageId: 'm1', body: 'hello', sentAt: sentAt);

      final m = messages.rows.single;
      expect(m.fromMe, isFalse);
      expect(m.peerSub, 'bob');
      expect(m.body, 'hello');
      expect(m.sentAt, sentAt);
      expect(m.expiresAt, isNull);
      expect(messages.threadCards['bob']!.name, 'Bob');
      expect(receipts, [('bob', 'm1', 'delivered')]);
    });

    test('honours explicit expiresInSec', () async {
      await handler.handleMessage(
          from: 'bob',
          messageId: 'm1',
          body: 'hi',
          sentAt: t0,
          expiresInSec: 60);

      expect(messages.rows.single.expiresAt, t0.add(const Duration(seconds: 60)));
    });

    test('falls back to the thread disappearing TTL', () async {
      // Existing thread with a 24h TTL.
      await messages.append(
        ChatMessage(
            id: 'm0', peerSub: 'bob', fromMe: true, body: 'x', sentAt: t0),
        card: card('bob'),
      );
      await messages.setDisappearingTtl('bob', const Duration(hours: 24));

      await handler.handleMessage(
          from: 'bob', messageId: 'm1', body: 'hi', sentAt: t0);

      final m = messages.rows.firstWhere((m) => m.id == 'm1');
      expect(m.expiresAt, t0.add(const Duration(hours: 24)));
    });

    test('drops messages from non-connections', () async {
      await handler.handleMessage(
          from: 'mallory', messageId: 'm1', body: 'yo', sentAt: t0);

      expect(messages.rows, isEmpty);
      expect(receipts, isEmpty);
    });

    test('dedupes by messageId', () async {
      await handler.handleMessage(
          from: 'bob', messageId: 'm1', body: 'hi', sentAt: t0);
      await handler.handleMessage(
          from: 'bob', messageId: 'm1', body: 'hi', sentAt: t0);

      expect(messages.rows.length, 1);
      expect(receipts.length, 1);
    });
  });

  group('handleReceipt / handleDisconnect', () {
    setUp(() async {
      await connections.upsert(
          Connection(peerSub: 'bob', card: card('bob'), connectedAt: t0));
      await messages.append(
        ChatMessage(
            id: 'm1', peerSub: 'bob', fromMe: true, body: 'hi', sentAt: t0),
        card: card('bob'),
      );
    });

    test('delivered receipt updates status', () async {
      await handler.handleReceipt(
          from: 'bob', messageId: 'm1', status: 'delivered');
      expect(messages.rows.single.status, MessageStatus.delivered);
    });

    test('read receipt updates status', () async {
      await handler.handleReceipt(from: 'bob', messageId: 'm1', status: 'read');
      expect(messages.rows.single.status, MessageStatus.read);
    });

    test('reaction receipt sets the reaction', () async {
      await handler.handleReceipt(
          from: 'bob', messageId: 'm1', reaction: '😊', hasReaction: true);
      expect(messages.rows.single.reaction, '😊');
    });

    test('null reaction with hasReaction clears it', () async {
      await messages.setReaction('m1', '😊');
      await handler.handleReceipt(
          from: 'bob', messageId: 'm1', hasReaction: true);
      expect(messages.rows.single.reaction, isNull);
    });

    test('disconnect removes the connection but keeps the thread', () async {
      await handler.handleDisconnect('bob');
      expect(connections.rows, isEmpty);
      expect(messages.rows, hasLength(1));
    });
  });
}
