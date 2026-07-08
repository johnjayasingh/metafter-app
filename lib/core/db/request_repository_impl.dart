import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import '../repositories/repositories.dart';
import 'watch_query.dart';

/// sqflite-backed [RequestRepository].
class RequestRepositoryImpl implements RequestRepository {
  RequestRepositoryImpl(this._db);

  final Database _db;
  final _changes = StreamController<void>.broadcast();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Force live `watch*` streams to re-query after a bulk wipe (finding [10]).
  void refresh() => _notify();

  @override
  Stream<List<ConnectionRequest>> watchIncomingPending() =>
      watchQuery(_changes.stream, _incomingPending);

  @override
  Stream<int> watchIncomingPendingCount() => watchQuery(
      _changes.stream, () async => (await _incomingPending()).length);

  @override
  Stream<List<ConnectionRequest>> watchOutgoing() =>
      watchQuery(_changes.stream, () async {
        final rows = await _db.query(
          'requests',
          where: 'direction = ?',
          whereArgs: [RequestDirection.outgoing.name],
          orderBy: 'created_at DESC',
        );
        return rows.map(_fromRow).toList();
      });

  Future<List<ConnectionRequest>> _incomingPending() async {
    final rows = await _db.query(
      'requests',
      where: 'direction = ? AND status = ?',
      whereArgs: [RequestDirection.incoming.name, RequestStatus.pending.name],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<ConnectionRequest?> byId(String id) async {
    final rows =
        await _db.query('requests', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsert(ConnectionRequest request) async {
    await _db.insert(
      'requests',
      {
        'id': request.id,
        'direction': request.direction.name,
        'peer_sub': request.peerSub,
        'card_json': request.card.encode(),
        'note': request.note,
        'status': request.status.name,
        'created_at': request.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify();
  }

  @override
  Future<void> setStatus(String id, RequestStatus status) async {
    await _db.update(
      'requests',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    _notify();
  }

  @override
  Future<int> countOutgoingSince(DateTime since) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM requests '
      'WHERE direction = ? AND created_at >= ?',
      [RequestDirection.outgoing.name, since.millisecondsSinceEpoch],
    );
    return result.first['c'] as int;
  }

  @override
  Future<int> countOutgoingWithNote() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM requests '
      "WHERE direction = ? AND note IS NOT NULL AND note != ''",
      [RequestDirection.outgoing.name],
    );
    return result.first['c'] as int;
  }

  static ConnectionRequest _fromRow(Map<String, Object?> row) =>
      ConnectionRequest(
        id: row['id'] as String,
        direction: RequestDirection.values.byName(row['direction'] as String),
        peerSub: row['peer_sub'] as String,
        card: ProfileCard.decode(row['card_json'] as String),
        note: row['note'] as String?,
        status: RequestStatus.values.byName(row['status'] as String),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      );
}
