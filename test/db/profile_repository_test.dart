import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/db/profile_repository_impl.dart';
import 'package:metafter/core/db/settings_repository_impl.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'db_test_utils.dart';

void main() {
  late Database db;
  late SettingsRepositoryImpl settings;
  late ProfileRepositoryImpl repo;

  const me = MyProfile(
    sub: 'me-sub',
    name: 'Jenny Wilson',
    role: 'Designer',
    designation: 'UI/UX Designer',
    company: 'Techinorm',
    intro: 'Hi there',
  );

  setUp(() async {
    db = await openTestDb();
    settings = SettingsRepositoryImpl(db);
    await settings.load();
    repo = ProfileRepositoryImpl(db, settings);
    await repo.load();
  });

  tearDown(() => db.close());

  test('profile is null until saved, then persists across load()', () async {
    expect(repo.profile.value, isNull);

    await repo.save(me);
    expect(repo.profile.value?.name, 'Jenny Wilson');

    final reloaded = ProfileRepositoryImpl(db, settings);
    await reloaded.load();
    expect(reloaded.profile.value?.sub, 'me-sub');
    expect(reloaded.profile.value?.company, 'Techinorm');
  });

  test('markVerified stores the badge signature', () async {
    await repo.save(me);
    await repo.markVerified('sig-b64');

    final reloaded = ProfileRepositoryImpl(db, settings);
    await reloaded.load();
    expect(reloaded.profile.value?.verified, isTrue);
    expect(reloaded.profile.value?.verifiedBadgeSig, 'sig-b64');
  });

  test('buildCard carries the full profile with default settings', () async {
    await repo.save(me);
    final card = await repo.buildCard();

    expect(card.sub, 'me-sub');
    expect(card.name, 'Jenny Wilson');
    expect(card.designation, 'UI/UX Designer');
    expect(card.company, 'Techinorm');
    expect(card.photoBase64, isNull); // no photoPath set
  });

  test('buildCard honours privacy settings', () async {
    await repo.save(me);

    await settings.setShowCompany(false);
    await settings.setShowDesignation(false);
    var card = await repo.buildCard();
    expect(card.company, isEmpty);
    expect(card.designation, isEmpty);

    await settings.setNameVisibility(PrivacyVisibility.visibleToConnections);
    card = await repo.buildCard();
    expect(card.name, 'Jenny'); // first name only for broadcast

    await settings.setNameVisibility(PrivacyVisibility.hidden);
    card = await repo.buildCard();
    expect(card.name, isEmpty);
  });

  test('buildCard survives a missing photo file', () async {
    await repo.save(me.copyWith(photoPath: '/nonexistent/photo.jpg'));
    final card = await repo.buildCard();
    expect(card.photoBase64, isNull);
  });

  test('clear wipes the row and the notifier', () async {
    await repo.save(me);
    await repo.clear();

    expect(repo.profile.value, isNull);
    expect(await db.query('my_profile'), isEmpty);
  });
}
