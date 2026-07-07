import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import '../repositories/repositories.dart';
import 'watch_query.dart';

/// sqflite-backed [MessageRepository]: `messages` rows plus denormalised
/// `threads` summaries kept in sync on every mutation.
class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl(this._db);

  final Database _db;
  final _changes = StreamController<void>.broadcast();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

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
    final thread = await _threadRow(message.peerSub);

    // Honour the thread's disappearing TTL when the caller did not already
    // stamp an expiry.
    var stored = message;
    if (stored.expiresAt == null && thread != null) {
      final ttlMs = thread['disappearing_ttl_ms'] as int?;
      if (ttlMs != null) {
        stored = stored.copyWith(
          expiresAt: stored.sentAt.add(Duration(milliseconds: ttlMs)),
        );
      }
    }

    await _db.transaction((txn) async {
      await txn.insert(
        'messages',
        _messageToRow(stored),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (thread == null) {
        await txn.insert('threads', {
          'peer_sub': stored.peerSub,
          'card_json': card.encode(),
          'last_message': stored.body,
          'last_message_at': stored.sentAt.millisecondsSinceEpoch,
          'last_from_me': stored.fromMe ? 1 : 0,
          'unread_count': stored.fromMe ? 0 : 1,
          'archived': 0,
          'disappearing_ttl_ms': null,
        });
      } else {
        final unread = thread['unread_count'] as int? ?? 0;
        await txn.update(
          'threads',
          {
            'card_json': card.encode(),
            'last_message': stored.body,
            'last_message_at': stored.sentAt.millisecondsSinceEpoch,
            'last_from_me': stored.fromMe ? 1 : 0,
            'unread_count': stored.fromMe ? unread : unread + 1,
          },
          where: 'peer_sub = ?',
          whereArgs: [stored.peerSub],
        );
      }
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
    await _db.update(
      'threads',
      {'unread_count': 0},
      where: 'peer_sub = ?',
      whereArgs: [peerSub],
    );
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
          await txn.update(
            'threads',
            {
              'last_message': last['body'] as String,
              'last_message_at': last['sent_at'] as int,
              'last_from_me': last['from_me'] as int,
            },
            where: 'peer_sub = ?',
            whereArgs: [peerSub],
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

  Future<Map<String, Object?>?> _threadRow(String peerSub) async {
    final rows = await _db.query(
      'threads',
      where: 'peer_sub = ?',
      whereArgs: [peerSub],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
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
