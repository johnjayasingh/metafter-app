import 'dart:async';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../proximity/proximity_engine.dart';
import '../repositories/repositories.dart';
import 'watch_query.dart';

/// sqflite-backed [EncounterRepository] — the "crossed paths" ledger.
class EncounterRepositoryImpl implements EncounterRepository {
  EncounterRepositoryImpl(this._db);

  final Database _db;
  final _changes = StreamController<void>.broadcast();
  static const _uuid = Uuid();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Force every live `watch*` stream to re-query. Used after a bulk wipe
  /// (finding [10]) so listeners re-emit an empty ledger.
  void refresh() => _notify();

  @override
  Stream<List<Encounter>> watchDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    // Calendar arithmetic, NOT start.add(Duration(days: 1)): on DST transition
    // days a calendar day is 23 or 25 absolute hours, so adding a fixed 24h
    // would leave a gap (or overlap) around midnight (finding [11]).
    // DateTime normalises day overflow to the true next local midnight, and
    // this matches daysWithEncounters' local-day bucketing.
    final end = DateTime(day.year, day.month, day.day + 1);
    return watchQuery(_changes.stream, () async {
      final rows = await _db.query(
        'encounters',
        where: 'last_seen >= ? AND last_seen < ?',
        whereArgs: [
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
        orderBy: 'last_seen DESC',
      );
      return rows.map(_fromRow).toList();
    });
  }

  @override
  Future<List<DateTime>> daysWithEncounters() async {
    final rows = await _db.query(
      'encounters',
      columns: ['last_seen'],
      orderBy: 'last_seen DESC',
    );
    final days = <DateTime>[];
    for (final row in rows) {
      final seen =
          DateTime.fromMillisecondsSinceEpoch(row['last_seen'] as int);
      final day = DateTime(seen.year, seen.month, seen.day);
      if (days.isEmpty || days.last != day) days.add(day);
    }
    return days;
  }

  @override
  Future<String> recordSighting(
    NearbyPeer peer, {
    Duration mergeWindow = const Duration(minutes: 30),
  }) async {
    final sub = peer.card?.sub ?? '';
    final seenMs = peer.lastSeen.millisecondsSinceEpoch;
    final windowMs = mergeWindow.inMilliseconds;

    // Same peer = same sub (once the card was read) or same ephemeral id
    // (covers sightings recorded before the GATT card read completed).
    final candidates = await _db.query(
      'encounters',
      where: "((? != '' AND peer_sub = ?) OR peer_eid = ?) "
          'AND last_seen >= ? AND last_seen <= ?',
      whereArgs: [sub, sub, peer.eid, seenMs - windowMs, seenMs + windowMs],
      orderBy: 'last_seen DESC',
      limit: 1,
    );

    if (candidates.isNotEmpty) {
      final row = candidates.first;
      final id = row['id'] as String;
      await _db.update(
        'encounters',
        {
          'peer_eid': peer.eid,
          if (sub.isNotEmpty) 'peer_sub': sub,
          if (peer.card != null) 'card_json': peer.card!.encode(),
          'last_seen': math.max(row['last_seen'] as int, seenMs),
          'meters': math.min(row['meters'] as double, peer.meters),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      _notify();
      return id;
    }

    final id = _uuid.v4();
    await _db.insert('encounters', {
      'id': id,
      'peer_eid': peer.eid,
      'peer_sub': sub,
      'card_json': (peer.card ?? ProfileCard(sub: sub, name: '')).encode(),
      'first_seen': seenMs,
      'last_seen': seenMs,
      'meters': peer.meters,
      'sent_request_id': null,
    });
    _notify();
    return id;
  }

  @override
  Future<void> markRequested(String encounterId, String requestId) async {
    await _db.update(
      'encounters',
      {'sent_request_id': requestId},
      where: 'id = ?',
      whereArgs: [encounterId],
    );
    _notify();
  }

  @override
  Future<void> sweepOlderThan(Duration age) async {
    final cutoff = DateTime.now().subtract(age).millisecondsSinceEpoch;
    final deleted = await _db.delete(
      'encounters',
      where: 'last_seen < ?',
      whereArgs: [cutoff],
    );
    if (deleted > 0) _notify();
  }

  static Encounter _fromRow(Map<String, Object?> row) => Encounter(
        id: row['id'] as String,
        peerEid: row['peer_eid'] as String,
        card: ProfileCard.decode(row['card_json'] as String),
        firstSeen:
            DateTime.fromMillisecondsSinceEpoch(row['first_seen'] as int),
        lastSeen: DateTime.fromMillisecondsSinceEpoch(row['last_seen'] as int),
        meters: row['meters'] as double,
        sentRequestId: row['sent_request_id'] as String?,
      );
}
