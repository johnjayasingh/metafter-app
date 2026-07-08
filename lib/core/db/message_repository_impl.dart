import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import '../repositories/repositories.dart';
import 'watch_query.dart';

/// sqflite-backed [MessageRepository]: `messages` rows plus denormalised
/// `threads` summaries kept in sync on every mutation.
class MessageRepositoryImpl implements MessageRepository {
  /// [settings] is optional so repository-only tests can construct the impl
  /// without the whole settings stack; when present, a brand-new thread seeds
  /// its disappearing TTL from `settings.disappearingDefault` (finding [13]).
  MessageRepositoryImpl(this._db, [this._settings]);

  final Database _db;
  final SettingsRepository? _settings;
  final _changes = StreamController<void>.broadcast();

  /// TTL seeded into a NEW thread when the user enabled "disappearing messages
  /// by default" (finding [13]).
  static const Duration disappearingDefaultTtl = Duration(hours: 24);

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Force live `watch*` streams to re-query after a bulk wipe (finding [10]).
  void refresh() => _notify();

  @override
  Stream<List<ThreadSummary>> watchThreads({required bool archived}) =>
      watchQuery(_changes.stream, () async {
        final rows = await _db.query(
          'threads',
          where: 'archived = ?',
          whereArgs: [archived ? 1 : 0],
          orderBy: 'last_message_at DESC',
        );
        return rows.map(_threadFromRow).toList();
      });

  @override
  Stream<List<ChatMessage>> watchThread(String peerSub) =>
      watchQuery(_changes.stream, () async {
        final rows = await _db.query(
          'messages',
          where: 'peer_sub = ?',
          whereArgs: [peerSub],
          orderBy: 'sent_at ASC',
        );
        return rows.map(_messageFromRow).toList();
      });

  @override
  Future<ChatMessage> append(ChatMessage message,
      {required ProfileCard card}) async {
    late ChatMessage stored;
    await _db.transaction((txn) async {
      // Read the thread row INSIDE the transaction (finding [9]). sqflite
      // serialises transactions, so concurrent appends for a brand-new peer
      // observe each other's inserts instead of both taking a doomed INSERT
      // branch and losing messages.
      final existing = await txn.query(
        'threads',
        columns: ['disappearing_ttl_ms'],
        where: 'peer_sub = ?',
        whereArgs: [message.peerSub],
        limit: 1,
      );
      final threadExists = existing.isNotEmpty;

      // Effective TTL: an existing thread keeps its own; a brand-new thread
      // inherits the "disappearing by default" preference (finding [13]).
      final int? ttlMs = threadExists
          ? existing.first['disappearing_ttl_ms'] as int?
          : (_settings?.disappearingDefault.value ?? false)
              ? disappearingDefaultTtl.inMilliseconds
              : null;

      stored = message;
      if (stored.expiresAt == null && ttlMs != null) {
        stored = stored.copyWith(
          expiresAt: stored.sentAt.add(Duration(milliseconds: ttlMs)),
        );
      }

      await txn.insert(
        'messages',
        _messageToRow(stored),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Atomic upsert of the thread summary (finding [9]): unread_count is
      // bumped as a SQL expression so two concurrent inbound appends can't
      // read the same snapshot and clobber the increment. disappearing_ttl_ms
      // is only set on the INSERT path, so an existing thread keeps its TTL.
      final inc = stored.fromMe ? 0 : 1;
      await txn.rawInsert(
        'INSERT INTO threads '
        '(peer_sub, card_json, last_message, last_message_at, last_from_me, '
        'unread_count, archived, disappearing_ttl_ms) '
        'VALUES (?, ?, ?, ?, ?, ?, 0, ?) '
        'ON CONFLICT(peer_sub) DO UPDATE SET '
        'card_json = excluded.card_json, '
        'last_message = excluded.last_message, '
        'last_message_at = excluded.last_message_at, '
        'last_from_me = excluded.last_from_me, '
        'unread_count = unread_count + ?',
        [
          stored.peerSub,
          card.encode(),
          stored.body,
          stored.sentAt.millisecondsSinceEpoch,
          stored.fromMe ? 1 : 0,
          inc,
          ttlMs,
          inc,
        ],
      );
    });
    _notify();
    return stored;
  }

  @override
  Future<void> setStatus(String messageId, MessageStatus status) async {
    await _db.update(
      'messages',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [messageId],
    );
    _notify();
  }

  @override
  Future<void> setReaction(String messageId, String? reaction) async {
    await _db.update(
      'messages',
      {'reaction': reaction},
      where: 'id = ?',
      whereArgs: [messageId],
    );
    _notify();
  }

  @override
  Future<void> markThreadRead(String peerSub) async {
    await _db.transaction((txn) async {
      // Flip received (from_me = 0) messages to 'read' as well as zeroing the
      // unread badge (finding [8]). Without this, markThreadRead is not
      // idempotent: the chat screen re-fires markRead on every watchThread
      // re-emit because a received message is still 'delivered', spinning a
      // markRead -> notify -> markRead loop. Keep the status string exactly
      // MessageStatus.read.name so the UI guard ("any received message with
      // status != read") settles.
      await txn.update(
        'messages',
        {'status': MessageStatus.read.name},
        where: 'peer_sub = ? AND from_me = 0 AND status != ?',
        whereArgs: [peerSub, MessageStatus.read.name],
      );
      await txn.update(
        'threads',
        {'unread_count': 0},
        where: 'peer_sub = ?',
        whereArgs: [peerSub],
      );
    });
    _notify();
  }

  @override
  Future<void> setArchived(String peerSub, bool archived) async {
    await _db.update(
      'threads',
      {'archived': archived ? 1 : 0},
      where: 'peer_sub = ?',
      whereArgs: [peerSub],
    );
    _notify();
  }

  @override
  Future<void> setDisappearingTtl(String peerSub, Duration? ttl) async {
    await _db.update(
      'threads',
      {'disappearing_ttl_ms': ttl?.inMilliseconds},
      where: 'peer_sub = ?',
      whereArgs: [peerSub],
    );
    _notify();
  }

  @override
  Future<void> sweepExpired() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final affected = await _db.rawQuery(
      'SELECT DISTINCT peer_sub FROM messages '
      'WHERE expires_at IS NOT NULL AND expires_at <= ?',
      [nowMs],
    );
    if (affected.isEmpty) return;

    await _db.transaction((txn) async {
      await txn.delete(
        'messages',
        where: 'expires_at IS NOT NULL AND expires_at <= ?',
        whereArgs: [nowMs],
      );
      // Refresh the summary of every touched thread from what remains.
      for (final row in affected) {
        final peerSub = row['peer_sub'] as String;
        final newest = await txn.query(
          'messages',
          where: 'peer_sub = ?',
          whereArgs: [peerSub],
          orderBy: 'sent_at DESC',
          limit: 1,
        );
        if (newest.isEmpty) {
          // Thread emptied out — keep the row but blank the preview.
          await txn.update(
            'threads',
            {'last_message': '', 'unread_count': 0},
            where: 'peer_sub = ?',
            whereArgs: [peerSub],
          );
        } else {
          final last = newest.first;
          // Clamp unread_count down to the received messages that actually
          // survive the sweep (finding [12]). Deleting expired *unread*
          // incoming messages would otherwise leave a phantom badge counting
          // messages the user can no longer see.
          await txn.rawUpdate(
            'UPDATE threads SET '
            'last_message = ?, last_message_at = ?, last_from_me = ?, '
            'unread_count = MIN(unread_count, '
            '(SELECT COUNT(*) FROM messages '
            'WHERE peer_sub = ? AND from_me = 0)) '
            'WHERE peer_sub = ?',
            [
              last['body'] as String,
              last['sent_at'] as int,
              last['from_me'] as int,
              peerSub,
              peerSub,
            ],
          );
        }
      }
    });
    _notify();
  }

  @override
  Future<void> deleteThread(String peerSub) async {
    await _db.transaction((txn) async {
      await txn.delete('messages', where: 'peer_sub = ?', whereArgs: [peerSub]);
      await txn.delete('threads', where: 'peer_sub = ?', whereArgs: [peerSub]);
    });
    _notify();
  }

  static Map<String, Object?> _messageToRow(ChatMessage m) => {
        'id': m.id,
        'peer_sub': m.peerSub,
        'from_me': m.fromMe ? 1 : 0,
        'body': m.body,
        'sent_at': m.sentAt.millisecondsSinceEpoch,
        'status': m.status.name,
        'reaction': m.reaction,
        'expires_at': m.expiresAt?.millisecondsSinceEpoch,
      };

  static ChatMessage _messageFromRow(Map<String, Object?> row) {
    final expiresMs = row['expires_at'] as int?;
    return ChatMessage(
      id: row['id'] as String,
      peerSub: row['peer_sub'] as String,
      fromMe: (row['from_me'] as int) != 0,
      body: row['body'] as String,
      sentAt: DateTime.fromMillisecondsSinceEpoch(row['sent_at'] as int),
      status: MessageStatus.values.byName(row['status'] as String),
      reaction: row['reaction'] as String?,
      expiresAt: expiresMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresMs),
    );
  }

  static ThreadSummary _threadFromRow(Map<String, Object?> row) {
    final ttlMs = row['disappearing_ttl_ms'] as int?;
    return ThreadSummary(
      peerSub: row['peer_sub'] as String,
      card: ProfileCard.decode(row['card_json'] as String),
      lastMessage: row['last_message'] as String? ?? '',
      lastMessageAt:
          DateTime.fromMillisecondsSinceEpoch(row['last_message_at'] as int),
      lastFromMe: (row['last_from_me'] as int? ?? 0) != 0,
      unreadCount: row['unread_count'] as int? ?? 0,
      archived: (row['archived'] as int? ?? 0) != 0,
      disappearingTtl: ttlMs == null ? null : Duration(milliseconds: ttlMs),
    );
  }
}
