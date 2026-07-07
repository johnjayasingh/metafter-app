import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/db/settings_repository_impl.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'db_test_utils.dart';

void main() {
  late Database db;
  late SettingsRepositoryImpl repo;

  setUp(() async {
    db = await openTestDb();
    repo = SettingsRepositoryImpl(db);
    await repo.load();
  });

  tearDown(() => db.close());

  test('defaults match the contract', () {
    expect(repo.mood.value, MoodRing.networking);
    expect(repo.discoverableDuration.value, const Duration(hours: 4));
    expect(repo.distanceBudget.value, 2.0);
    expect(repo.use24hTime.value, isFalse); // 12h time
    expect(repo.language.value, 'English');
    expect(repo.reduceMotion.value, isFalse);
    expect(repo.largerText.value, isFalse);
    expect(repo.readReceipts.value, isTrue);
    expect(repo.typingIndicator.value, isTrue);
    expect(repo.allowVideoCall.value, isTrue);
    expect(repo.allowAudioCall.value, isTrue);
    expect(repo.disappearingDefault.value, isFalse);
    expect(repo.showCompany.value, isTrue);
    expect(repo.showDesignation.value, isTrue);
    expect(repo.incognitoScan.value, isFalse);
    expect(repo.nameVisibility.value, PrivacyVisibility.visibleToAll);
    expect(repo.companyVisibility.value, PrivacyVisibility.visibleToAll);
    expect(repo.isPro.value, isFalse);
  });

  test('values persist across a reload (fresh repository, same db)', () async {
    await repo.setMood(MoodRing.friends);
    await repo.setDiscoverableDuration(const Duration(hours: 8));
    await repo.setDistanceBudget(5.0);
    await repo.setUse24hTime(true);
    await repo.setLanguage('German');
    await repo.setReduceMotion(true);
    await repo.setLargerText(true);
    await repo.setReadReceipts(false);
    await repo.setTypingIndicator(false);
    await repo.setAllowVideoCall(false);
    await repo.setAllowAudioCall(false);
    await repo.setDisappearingDefault(true);
    await repo.setShowCompany(false);
    await repo.setShowDesignation(false);
    await repo.setIncognitoScan(true);
    await repo.setNameVisibility(PrivacyVisibility.hidden);
    await repo.setCompanyVisibility(PrivacyVisibility.visibleToConnections);
    await repo.setIsPro(true);

    final reloaded = SettingsRepositoryImpl(db);
    await reloaded.load();

    expect(reloaded.mood.value, MoodRing.friends);
    expect(reloaded.discoverableDuration.value, const Duration(hours: 8));
    expect(reloaded.distanceBudget.value, 5.0);
    expect(reloaded.use24hTime.value, isTrue);
    expect(reloaded.language.value, 'German');
    expect(reloaded.reduceMotion.value, isTrue);
    expect(reloaded.largerText.value, isTrue);
    expect(reloaded.readReceipts.value, isFalse);
    expect(reloaded.typingIndicator.value, isFalse);
    expect(reloaded.allowVideoCall.value, isFalse);
    expect(reloaded.allowAudioCall.value, isFalse);
    expect(reloaded.disappearingDefault.value, isTrue);
    expect(reloaded.showCompany.value, isFalse);
    expect(reloaded.showDesignation.value, isFalse);
    expect(reloaded.incognitoScan.value, isTrue);
    expect(reloaded.nameVisibility.value, PrivacyVisibility.hidden);
    expect(reloaded.companyVisibility.value,
        PrivacyVisibility.visibleToConnections);
    expect(reloaded.isPro.value, isTrue);
  });

  test('setters notify listeners synchronously', () async {
    var notified = 0;
    repo.mood.addListener(() => notified++);
    await repo.setMood(MoodRing.catchup);
    expect(notified, 1);
    expect(repo.mood.value, MoodRing.catchup);
  });

  test('unknown stored values fall back to defaults', () async {
    await db.insert('settings', {'key': 'mood', 'value': 'no-such-mood'});
    await db.insert(
        'settings', {'key': 'discoverableDurationMs', 'value': 'garbage'});

    final reloaded = SettingsRepositoryImpl(db);
    await reloaded.load();

    expect(reloaded.mood.value, MoodRing.networking);
    expect(reloaded.discoverableDuration.value, const Duration(hours: 4));
  });
}
