import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/db/message_repository_impl.dart';
import 'package:metafter/core/db/settings_repository_impl.dart';
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

  test('markThreadRead flips received messages to read and is idempotent',
      () async {
    await repo.append(msg('in', fromMe: false, sentAt: t0), card: alice);
    await repo.append(
      msg('out', fromMe: true, sentAt: t0.add(const Duration(seconds: 1))),
      card: alice,
    );

    await repo.markThreadRead('alice');

    var msgs = await repo.watchThread('alice').first;
    expect(msgs.firstWhere((m) => m.id == 'in').status, MessageStatus.read);
    // The message we sent is not force-read by our own markRead.
    expect(
        msgs.firstWhere((m) => m.id == 'out').status, isNot(MessageStatus.read));

    // Idempotent: the chat-screen guard ("any received message with status !=
    // read") must settle so markRead cannot re-arm (finding [8]).
    await repo.markThreadRead('alice');
    msgs = await repo.watchThread('alice').first;
    expect(msgs.where((m) => !m.fromMe && m.status != MessageStatus.read),
        isEmpty);
    expect((await summary('alice')).unreadCount, 0);
  });

  test('concurrent appends for a brand-new peer lose no messages', () async {
    // Fire both without awaiting the first: before finding [9] both took the
    // INSERT branch off the same null snapshot and the second rolled back.
    final f1 = repo.append(msg('c1', fromMe: false, sentAt: t0), card: alice);
    final f2 = repo.append(
      msg('c2', fromMe: false, sentAt: t0.add(const Duration(seconds: 1))),
      card: alice,
    );
    await Future.wait([f1, f2]);

    final msgs = await repo.watchThread('alice').first;
    expect(msgs.map((m) => m.id), containsAll(['c1', 'c2']));
    expect((await summary('alice')).unreadCount, 2);
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

  test('sweepExpired clamps a stale unread badge when messages remain',
      () async {
    final now = DateTime.now();
    // One surviving unread received message...
    await repo.append(
      msg('keep', fromMe: false, body: 'still here', sentAt: now),
      card: alice,
    );
    // ...plus two disappearing received messages counted as unread.
    await repo.append(
      msg('e1',
          fromMe: false,
          sentAt: now,
          expiresAt: now.subtract(const Duration(minutes: 1))),
      card: alice,
    );
    await repo.append(
      msg('e2',
          fromMe: false,
          sentAt: now,
          expiresAt: now.subtract(const Duration(minutes: 1))),
      card: alice,
    );
    expect((await summary('alice')).unreadCount, 3);

    await repo.sweepExpired();

    // Only 'keep' survives, so the badge must clamp to 1 (finding [12]).
    expect((await repo.watchThread('alice').first).map((m) => m.id), ['keep']);
    expect((await summary('alice')).unreadCount, 1);
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

  test('a new thread seeds its TTL from disappearingDefault', () async {
    final settings = SettingsRepositoryImpl(db);
    await settings.load();
    await settings.setDisappearingDefault(true);
    final seeded = MessageRepositoryImpl(db, settings);

    final stored = await seeded.append(
      msg('m1', fromMe: false, sentAt: t0),
      card: alice,
    );

    // The message expiry and the thread TTL both come from the 24h default.
    expect(stored.expiresAt,
        t0.add(MessageRepositoryImpl.disappearingDefaultTtl));
    final thread =
        (await seeded.watchThreads(archived: false).first).single;
    expect(thread.disappearingTtl, MessageRepositoryImpl.disappearingDefaultTtl);
  });

  test('a new thread keeps a NULL TTL when disappearingDefault is off',
      () async {
    final settings = SettingsRepositoryImpl(db);
    await settings.load(); // default false
    final plain = MessageRepositoryImpl(db, settings);

    final stored =
        await plain.append(msg('m1', fromMe: false, sentAt: t0), card: alice);

    expect(stored.expiresAt, isNull);
    expect(
        (await plain.watchThreads(archived: false).first).single.disappearingTtl,
        isNull);
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
