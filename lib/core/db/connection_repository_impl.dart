import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import '../repositories/repositories.dart';
import 'watch_query.dart';

/// sqflite-backed [ConnectionRepository].
class ConnectionRepositoryImpl implements ConnectionRepository {
  ConnectionRepositoryImpl(this._db);

  final Database _db;
  final _changes = StreamController<void>.broadcast();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Force live `watch*` streams to re-query after a bulk wipe (finding [10]).
  void refresh() => _notify();

  @override
  Stream<List<Connection>> watchAll() => watchQuery(_changes.stream, () async {
        final rows = await _db.query('connections', orderBy: 'connected_at DESC');
        return rows.map(_fromRow).toList();
      });

  @override
  Future<Connection?> byPeer(String peerSub) async {
    final rows = await _db.query(
      'connections',
      where: 'peer_sub = ?',
      whereArgs: [peerSub],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsert(Connection connection) async {
    await _db.insert(
      'connections',
      {
        'peer_sub': connection.peerSub,
        'card_json': connection.card.encode(),
        'connected_at': connection.connectedAt.millisecondsSinceEpoch,
        'mood_at_meet': connection.moodAtMeet?.wire,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify();
  }

  @override
  Future<void> remove(String peerSub) async {
    await _db
        .delete('connections', where: 'peer_sub = ?', whereArgs: [peerSub]);
    _notify();
  }

  static Connection _fromRow(Map<String, Object?> row) {
    final mood = row['mood_at_meet'] as int?;
    return Connection(
      peerSub: row['peer_sub'] as String,
      card: ProfileCard.decode(row['card_json'] as String),
      connectedAt:
          DateTime.fromMillisecondsSinceEpoch(row['connected_at'] as int),
      moodAtMeet: mood == null ? null : MoodRingX.fromWire(mood),
    );
  }
}
