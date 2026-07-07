import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/db/message_repository_impl.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'db_test_utils.dart';

const alice = ProfileCard(sub: 'alice', name: 'Alice');

ChatMessage msg(
  String id, {
  String peerSub = 'alice',
  bool fromMe = true,
  String body = 'hello',
  required DateTime sentAt,
  DateTime? expiresAt,
}) =>
    ChatMessage(
      id: id,
      peerSub: peerSub,
      fromMe: fromMe,
      body: body,
      sentAt: sentAt,
      expiresAt: expiresAt,
    );

void main() {
  late Database db;
  late MessageRepositoryImpl repo;
  final t0 = DateTime(2026, 7, 7, 9);

  setUp(() async {
    db = await openTestDb();
    repo = MessageRepositoryImpl(db);
  });

  tearDown(() => db.close());

  Future<ThreadSummary> summary(String peerSub) async {
    final threads = await repo.watchThreads(archived: false).first;
    return threads.singleWhere((t) => t.peerSub == peerSub);
  }

  test('append creates the thread and keeps the summary in sync', () async {
    await repo.append(msg('m1', sentAt: t0, body: 'hi'), card: alice);

    var thread = await summary('alice');
    expect(thread.lastMessage, 'hi');
    expect(thread.lastFromMe, isTrue);
    expect(thread.unreadCount, 0);
    expect(thread.card.name, 'Alice');

    await repo.append(
      msg('m2',
          fromMe: false,
          body: 'hey!',
          sentAt: t0.add(const Duration(minutes: 1))),
      card: alice,
    );
    await repo.append(
      msg('m3',
          fromMe: false,
          body: 'you there?',
          sentAt: t0.add(const Duration(minutes: 2))),
      card: alice,
    );

    thread = await summary('alice');
    expect(thread.lastMessage, 'you there?');
    expect(thread.lastFromMe, isFalse);
    expect(thread.unreadCount, 2); // only inbound messages count
    expect(thread.lastMessageAt, t0.add(const Duration(minutes: 2)));
  });

  test('markThreadRead zeroes the unread count', () async {
    await repo.append(msg('m1', fromMe: false, sentAt: t0), card: alice);
    expect((await summary('alice')).unreadCount, 1);

    await repo.markThreadRead('alice');
    expect((await summary('alice')).unreadCount, 0);
  });

  test('watchThread emits chronologically and reacts to mutations', () async {
    final emissions = <List<ChatMessage>>[];
    final sub = repo.watchThread('alice').listen(emissions.add);
    await pumpEventQueue();
    expect(emissions.single, isEmpty);

    await repo.append(msg('m1', sentAt: t0), card: alice);
    await repo.append(
        msg('m2', sentAt: t0.add(const Duration(seconds: 5))),
        card: alice);
    await pumpEventQueue();

    expect(emissions.last.map((m) => m.id), ['m1', 'm2']);

    await repo.setReaction('m1', '👍');
    await pumpEventQueue();
    expect(emissions.last.first.reaction, '👍');

    await repo.setStatus('m2', MessageStatus.read);
    await pumpEventQueue();
    expect(emissions.last.last.status, MessageStatus.read);
    await sub.cancel();
  });

  test('append stamps expiresAt from the thread disappearing TTL', () async {
    await repo.append(msg('m1', sentAt: t0), card: alice);
    await repo.setDisappearingTtl('alice', const Duration(hours: 1));

    final stored = await repo.append(
      msg('m2', sentAt: t0.add(const Duration(minutes: 1))),
      card: alice,
    );

    expect(stored.expiresAt,
        t0.add(const Duration(minutes: 1)).add(const Duration(hours: 1)));
    expect((await summary('alice')).disappearingTtl, const Duration(hours: 1));
  });

  test('sweepExpired deletes expired messages and refreshes the summary',
      () async {
    final now = DateTime.now();
    await repo.append(
      msg('old', body: 'gone soon', sentAt: now.subtract(const Duration(hours: 2))),
      card: alice,
    );
    await repo.append(
      msg('newer',
          body: 'still here',
          fromMe: false,
          sentAt: now.subtract(const Duration(hours: 1))),
      card: alice,
    );
    // Make the LAST message the expired one.
    await repo.append(
      msg('expired-last',
          body: 'vanishing',
          sentAt: now.subtract(const Duration(minutes: 30)),
          expiresAt: now.subtract(const Duration(minutes: 1))),
      card: alice,
    );

    await repo.sweepExpired();

    final remaining = await repo.watchThread('alice').first;
    expect(remaining.map((m) => m.id), ['old', 'newer']);

    final thread = await summary('alice');
    expect(thread.lastMessage, 'still here');
    expect(thread.lastFromMe, isFalse);
  });

  test('sweepExpired keeps an emptied thread with a blank preview', () async {
    final now = DateTime.now();
    await repo.append(
      msg('only',
          body: 'poof',
          sentAt: now.subtract(const Duration(minutes: 10)),
          expiresAt: now.subtract(const Duration(minutes: 1))),
      card: alice,
    );

    await repo.sweepExpired();

    expect(await repo.watchThread('alice').first, isEmpty);
    final thread = await summary('alice');
    expect(thread.lastMessage, '');
    expect(thread.unreadCount, 0);
  });

  test('sweepExpired leaves unexpired messages alone', () async {
    final now = DateTime.now();
    await repo.append(
      msg('keeper',
          sentAt: now, expiresAt: now.add(const Duration(hours: 1))),
      card: alice,
    );

    await repo.sweepExpired();
    expect(await repo.watchThread('alice').first, hasLength(1));
  });

  test('setArchived moves threads between the two lists', () async {
    await repo.append(msg('m1', sentAt: t0), card: alice);
    await repo.setArchived('alice', true);

    expect(await repo.watchThreads(archived: false).first, isEmpty);
    final archived = await repo.watchThreads(archived: true).first;
    expect(archived.single.peerSub, 'alice');
  });

  test('deleteThread removes the thread and its messages', () async {
    await repo.append(msg('m1', sentAt: t0), card: alice);
    await repo.deleteThread('alice');

    expect(await repo.watchThreads(archived: false).first, isEmpty);
    expect(await db.query('messages'), isEmpty);
  });
}
