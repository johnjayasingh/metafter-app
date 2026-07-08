import 'package:sqflite/sqflite.dart';

/// Durable processed-message ledger used by `InboundHandler` for replay
/// protection (finding [0]).
///
/// Deliberately independent of thread retention: an id remains recorded even
/// after its message row is purged by the disappearing-message sweep, so a
/// re-injected (still validly signed) envelope is recognised as a replay
/// rather than resurrected as a fresh message.
abstract class SeenMessageLedger {
  /// Record that [messageId] has been processed at [seenAt].
  ///
  /// Returns true when the id was newly inserted (the caller should process
  /// the message), false when it was already present (a replay/duplicate that
  /// must be dropped).
  Future<bool> record(String messageId, DateTime seenAt);

  /// Drop ledger rows first seen before [before] to bound growth.
  Future<void> pruneBefore(DateTime before);
}

/// sqflite-backed [SeenMessageLedger] over the `seen_messages` table.
class SqliteSeenMessageLedger implements SeenMessageLedger {
  SqliteSeenMessageLedger(this._db);

  final Database _db;

  @override
  Future<bool> record(String messageId, DateTime seenAt) async {
    // ConflictAlgorithm.ignore returns 0 when a row with this primary key
    // already exists, i.e. the message was seen before.
    final rowId = await _db.insert(
      'seen_messages',
      {'message_id': messageId, 'seen_at': seenAt.millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return rowId != 0;
  }

  @override
  Future<void> pruneBefore(DateTime before) async {
    await _db.delete(
      'seen_messages',
      where: 'seen_at < ?',
      whereArgs: [before.millisecondsSinceEpoch],
    );
  }
}
