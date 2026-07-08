import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/db/encounter_repository_impl.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/proximity/proximity_engine.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'db_test_utils.dart';

NearbyPeer peer({
  String eid = 'eid-1',
  String? sub = 'sub-1',
  double meters = 3.0,
  required DateTime lastSeen,
}) =>
    NearbyPeer(
      eid: eid,
      meters: meters,
      mood: MoodRing.networking,
      lastSeen: lastSeen,
      card: sub == null ? null : ProfileCard(sub: sub, name: 'Alice'),
    );

void main() {
  late Database db;
  late EncounterRepositoryImpl repo;
  final noon = DateTime(2026, 7, 7, 12);

  setUp(() async {
    db = await openTestDb();
    repo = EncounterRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('sightings of the same sub within the merge window are merged',
      () async {
    final id1 = await repo.recordSighting(peer(lastSeen: noon, meters: 3.0));
    final id2 = await repo.recordSighting(peer(
      eid: 'eid-rotated',
      lastSeen: noon.add(const Duration(minutes: 10)),
      meters: 1.5,
    ));

    expect(id2, id1);
    final rows = await db.query('encounters');
    expect(rows, hasLength(1));
    expect(rows.first['meters'], 1.5); // min of 3.0 and 1.5
    expect(
      rows.first['last_seen'],
      noon.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
    );
    expect(rows.first['first_seen'], noon.millisecondsSinceEpoch);
  });

  test('merge keeps the minimum distance', () async {
    await repo.recordSighting(peer(lastSeen: noon, meters: 1.0));
    await repo.recordSighting(peer(
      lastSeen: noon.add(const Duration(minutes: 5)),
      meters: 4.0,
    ));

    final rows = await db.query('encounters');
    expect(rows, hasLength(1));
    expect(rows.first['meters'], 1.0);
  });

  test('sightings outside the merge window create a new encounter', () async {
    final id1 = await repo.recordSighting(peer(lastSeen: noon));
    final id2 = await repo.recordSighting(
      peer(lastSeen: noon.add(const Duration(hours: 2))),
    );

    expect(id2, isNot(id1));
    expect(await db.query('encounters'), hasLength(2));
  });

  test('card-less sightings merge by eid', () async {
    final id1 =
        await repo.recordSighting(peer(sub: null, lastSeen: noon));
    final id2 = await repo.recordSighting(
      peer(sub: null, lastSeen: noon.add(const Duration(minutes: 1))),
    );
    expect(id2, id1);
  });

  test('watchDay emits immediately, filters by local day and re-emits',
      () async {
    await repo.recordSighting(peer(lastSeen: noon));
    await repo.recordSighting(peer(
      eid: 'other-day',
      sub: 'sub-2',
      lastSeen: noon.subtract(const Duration(days: 1)),
    ));

    final emissions = <List<Encounter>>[];
    final sub = repo.watchDay(noon).listen(emissions.add);
    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(emissions.single, hasLength(1));
    expect(emissions.single.single.card.sub, 'sub-1');

    await repo.recordSighting(peer(
      eid: 'eid-3',
      sub: 'sub-3',
      lastSeen: noon.add(const Duration(hours: 1)),
    ));
    await pumpEventQueue();
    expect(emissions, hasLength(2));
    expect(emissions.last, hasLength(2));
    // Newest first.
    expect(emissions.last.first.card.sub, 'sub-3');
    await sub.cancel();
  });

  test('watchDay includes a 23:30 encounter (calendar day, not +24h)',
      () async {
    // With start.add(Duration(days: 1)) the window end drifts off true local
    // midnight on DST transition days, dropping late-evening encounters
    // (finding [11]). Calendar arithmetic keeps 23:30 inside the day.
    final lateNight = DateTime(2026, 11, 1, 23, 30);
    await repo.recordSighting(peer(eid: 'late', sub: 'sub-late', lastSeen: lateNight));

    final today = await repo.watchDay(DateTime(2026, 11, 1)).first;
    expect(today.map((e) => e.card.sub), contains('sub-late'));

    // And it must not bleed into the next day.
    final tomorrow = await repo.watchDay(DateTime(2026, 11, 2)).first;
    expect(tomorrow.map((e) => e.card.sub), isNot(contains('sub-late')));
  });

  test('daysWithEncounters returns distinct local days, newest first',
      () async {
    await repo.recordSighting(peer(lastSeen: noon));
    await repo.recordSighting(peer(
      eid: 'e2',
      sub: 'sub-2',
      lastSeen: noon.add(const Duration(hours: 3)),
    ));
    await repo.recordSighting(peer(
      eid: 'e3',
      sub: 'sub-3',
      lastSeen: noon.subtract(const Duration(days: 2)),
    ));

    final days = await repo.daysWithEncounters();
    expect(days, [
      DateTime(2026, 7, 7),
      DateTime(2026, 7, 5),
    ]);
  });

  test('markRequested links the request id', () async {
    final id = await repo.recordSighting(peer(lastSeen: noon));
    await repo.markRequested(id, 'req-42');

    final row =
        (await db.query('encounters', where: 'id = ?', whereArgs: [id])).single;
    expect(row['sent_request_id'], 'req-42');
  });

  test('sweepOlderThan deletes stale encounters only', () async {
    final now = DateTime.now();
    await repo.recordSighting(
      peer(lastSeen: now.subtract(const Duration(days: 40))),
    );
    await repo.recordSighting(peer(
      eid: 'fresh',
      sub: 'sub-2',
      lastSeen: now.subtract(const Duration(minutes: 1)),
    ));

    await repo.sweepOlderThan(const Duration(days: 30));

    final rows = await db.query('encounters');
    expect(rows, hasLength(1));
    expect(rows.first['peer_sub'], 'sub-2');
  });
}
