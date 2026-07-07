import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import '../repositories/repositories.dart';

/// sqflite-backed [SettingsRepository]: every value is one row in the
/// `settings` key/value table and one in-memory [ValueNotifier], so the Home
/// shell and the Settings screens observe the same state.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db);

  final Database _db;

  // -- keys -------------------------------------------------------------
  static const _kMood = 'mood';
  static const _kDuration = 'discoverableDurationMs';
  static const _kDistance = 'distanceBudget';
  static const _kUse24h = 'use24hTime';
  static const _kLanguage = 'language';
  static const _kReduceMotion = 'reduceMotion';
  static const _kLargerText = 'largerText';
  static const _kReadReceipts = 'readReceipts';
  static const _kTypingIndicator = 'typingIndicator';
  static const _kAllowVideoCall = 'allowVideoCall';
  static const _kAllowAudioCall = 'allowAudioCall';
  static const _kDisappearingDefault = 'disappearingDefault';
  static const _kShowCompany = 'showCompany';
  static const _kShowDesignation = 'showDesignation';
  static const _kIncognitoScan = 'incognitoScan';
  static const _kNameVisibility = 'nameVisibility';
  static const _kCompanyVisibility = 'companyVisibility';
  static const _kIsPro = 'isPro';

  // -- state (defaults per contract) --------------------------------------
  final _mood = ValueNotifier<MoodRing>(MoodRing.networking);
  final _duration = ValueNotifier<Duration>(const Duration(hours: 4));
  final _distance = ValueNotifier<double>(2.0);
  final _use24h = ValueNotifier<bool>(false);
  final _language = ValueNotifier<String>('English');
  final _reduceMotion = ValueNotifier<bool>(false);
  final _largerText = ValueNotifier<bool>(false);
  final _readReceipts = ValueNotifier<bool>(true);
  final _typingIndicator = ValueNotifier<bool>(true);
  final _allowVideoCall = ValueNotifier<bool>(true);
  final _allowAudioCall = ValueNotifier<bool>(true);
  final _disappearingDefault = ValueNotifier<bool>(false);
  final _showCompany = ValueNotifier<bool>(true);
  final _showDesignation = ValueNotifier<bool>(true);
  final _incognitoScan = ValueNotifier<bool>(false);
  final _nameVisibility =
      ValueNotifier<PrivacyVisibility>(PrivacyVisibility.visibleToAll);
  final _companyVisibility =
      ValueNotifier<PrivacyVisibility>(PrivacyVisibility.visibleToAll);
  final _isPro = ValueNotifier<bool>(false);

  @override
  ValueListenable<MoodRing> get mood => _mood;
  @override
  ValueListenable<Duration> get discoverableDuration => _duration;
  @override
  ValueListenable<double> get distanceBudget => _distance;
  @override
  ValueListenable<bool> get use24hTime => _use24h;
  @override
  ValueListenable<String> get language => _language;
  @override
  ValueListenable<bool> get reduceMotion => _reduceMotion;
  @override
  ValueListenable<bool> get largerText => _largerText;
  @override
  ValueListenable<bool> get readReceipts => _readReceipts;
  @override
  ValueListenable<bool> get typingIndicator => _typingIndicator;
  @override
  ValueListenable<bool> get allowVideoCall => _allowVideoCall;
  @override
  ValueListenable<bool> get allowAudioCall => _allowAudioCall;
  @override
  ValueListenable<bool> get disappearingDefault => _disappearingDefault;
  @override
  ValueListenable<bool> get showCompany => _showCompany;
  @override
  ValueListenable<bool> get showDesignation => _showDesignation;
  @override
  ValueListenable<bool> get incognitoScan => _incognitoScan;
  @override
  ValueListenable<PrivacyVisibility> get nameVisibility => _nameVisibility;
  @override
  ValueListenable<PrivacyVisibility> get companyVisibility =>
      _companyVisibility;
  @override
  ValueListenable<bool> get isPro => _isPro;

  @override
  Future<void> load() async {
    final rows = await _db.query('settings');
    final map = <String, String>{
      for (final row in rows) row['key'] as String: row['value'] as String,
    };

    _mood.value = _enum(MoodRing.values, map[_kMood], MoodRing.networking);
    _duration.value = Duration(
        milliseconds: int.tryParse(map[_kDuration] ?? '') ??
            const Duration(hours: 4).inMilliseconds);
    _distance.value = double.tryParse(map[_kDistance] ?? '') ?? 2.0;
    _use24h.value = _bool(map[_kUse24h], false);
    _language.value = map[_kLanguage] ?? 'English';
    _reduceMotion.value = _bool(map[_kReduceMotion], false);
    _largerText.value = _bool(map[_kLargerText], false);
    _readReceipts.value = _bool(map[_kReadReceipts], true);
    _typingIndicator.value = _bool(map[_kTypingIndicator], true);
    _allowVideoCall.value = _bool(map[_kAllowVideoCall], true);
    _allowAudioCall.value = _bool(map[_kAllowAudioCall], true);
    _disappearingDefault.value = _bool(map[_kDisappearingDefault], false);
    _showCompany.value = _bool(map[_kShowCompany], true);
    _showDesignation.value = _bool(map[_kShowDesignation], true);
    _incognitoScan.value = _bool(map[_kIncognitoScan], false);
    _nameVisibility.value = _enum(PrivacyVisibility.values,
        map[_kNameVisibility], PrivacyVisibility.visibleToAll);
    _companyVisibility.value = _enum(PrivacyVisibility.values,
        map[_kCompanyVisibility], PrivacyVisibility.visibleToAll);
    _isPro.value = _bool(map[_kIsPro], false);
  }

  @override
  Future<void> setMood(MoodRing v) => _set(_mood, v, _kMood, v.name);
  @override
  Future<void> setDiscoverableDuration(Duration v) =>
      _set(_duration, v, _kDuration, '${v.inMilliseconds}');
  @override
  Future<void> setDistanceBudget(double v) =>
      _set(_distance, v, _kDistance, '$v');
  @override
  Future<void> setUse24hTime(bool v) => _set(_use24h, v, _kUse24h, '$v');
  @override
  Future<void> setLanguage(String v) => _set(_language, v, _kLanguage, v);
  @override
  Future<void> setReduceMotion(bool v) =>
      _set(_reduceMotion, v, _kReduceMotion, '$v');
  @override
  Future<void> setLargerText(bool v) =>
      _set(_largerText, v, _kLargerText, '$v');
  @override
  Future<void> setReadReceipts(bool v) =>
      _set(_readReceipts, v, _kReadReceipts, '$v');
  @override
  Future<void> setTypingIndicator(bool v) =>
      _set(_typingIndicator, v, _kTypingIndicator, '$v');
  @override
  Future<void> setAllowVideoCall(bool v) =>
      _set(_allowVideoCall, v, _kAllowVideoCall, '$v');
  @override
  Future<void> setAllowAudioCall(bool v) =>
      _set(_allowAudioCall, v, _kAllowAudioCall, '$v');
  @override
  Future<void> setDisappearingDefault(bool v) =>
      _set(_disappearingDefault, v, _kDisappearingDefault, '$v');
  @override
  Future<void> setShowCompany(bool v) =>
      _set(_showCompany, v, _kShowCompany, '$v');
  @override
  Future<void> setShowDesignation(bool v) =>
      _set(_showDesignation, v, _kShowDesignation, '$v');
  @override
  Future<void> setIncognitoScan(bool v) =>
      _set(_incognitoScan, v, _kIncognitoScan, '$v');
  @override
  Future<void> setNameVisibility(PrivacyVisibility v) =>
      _set(_nameVisibility, v, _kNameVisibility, v.name);
  @override
  Future<void> setCompanyVisibility(PrivacyVisibility v) =>
      _set(_companyVisibility, v, _kCompanyVisibility, v.name);
  @override
  Future<void> setIsPro(bool v) => _set(_isPro, v, _kIsPro, '$v');

  Future<void> _set<T>(
      ValueNotifier<T> notifier, T value, String key, String stored) async {
    notifier.value = value;
    await _db.insert(
      'settings',
      {'key': key, 'value': stored},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static bool _bool(String? raw, bool fallback) =>
      raw == null ? fallback : raw == 'true';

  static T _enum<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
