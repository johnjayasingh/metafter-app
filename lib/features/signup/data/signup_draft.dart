import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory model carrying the data the user enters across the
/// multi-step signup flow. Backed by [SharedPreferences] so the user
/// stays signed-in across app launches.
class SignupDraft extends ChangeNotifier {
  SignupDraft._();
  static final SignupDraft instance = SignupDraft._();

  static const _kPrefix = 'signup_draft.';
  static const _kName = '${_kPrefix}name';
  static const _kEmail = '${_kPrefix}email';
  static const _kPhone = '${_kPrefix}phone';
  static const _kCountryCode = '${_kPrefix}countryCode';
  static const _kRole = '${_kPrefix}role';
  static const _kDesignation = '${_kPrefix}designation';
  static const _kCompany = '${_kPrefix}company';
  static const _kIntroduction = '${_kPrefix}introduction';
  static const _kPhotoPath = '${_kPrefix}photoPath';
  static const _kSelfiePath = '${_kPrefix}selfiePath';
  static const _kOnboarded = '${_kPrefix}onboarded';

  String name = '';
  String email = '';
  String phone = '';
  String countryCode = '+91';

  String role = '';
  String designation = '';
  String company = '';
  String introduction = '';

  /// Local file path / data uri of the uploaded profile photo.
  String? photoPath;

  /// Local file path / data uri of the captured selfie.
  String? selfiePath;

  /// `true` once the user has completed the signup flow at least once.
  bool isOnboarded = false;

  void update(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  /// Loads any previously-persisted draft from disk.
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      name = p.getString(_kName) ?? '';
      email = p.getString(_kEmail) ?? '';
      phone = p.getString(_kPhone) ?? '';
      countryCode = p.getString(_kCountryCode) ?? '+91';
      role = p.getString(_kRole) ?? '';
      designation = p.getString(_kDesignation) ?? '';
      company = p.getString(_kCompany) ?? '';
      introduction = p.getString(_kIntroduction) ?? '';
      photoPath = p.getString(_kPhotoPath);
      selfiePath = p.getString(_kSelfiePath);
      isOnboarded = p.getBool(_kOnboarded) ?? false;
      notifyListeners();
    } on Exception {
      // ignore — start with defaults
    }
  }

  /// Persists the current draft to disk. By default also marks the user
  /// as fully onboarded.
  Future<void> save({bool markOnboarded = true}) async {
    if (markOnboarded) isOnboarded = true;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kName, name);
      await p.setString(_kEmail, email);
      await p.setString(_kPhone, phone);
      await p.setString(_kCountryCode, countryCode);
      await p.setString(_kRole, role);
      await p.setString(_kDesignation, designation);
      await p.setString(_kCompany, company);
      await p.setString(_kIntroduction, introduction);
      if (photoPath != null) {
        await p.setString(_kPhotoPath, photoPath!);
      } else {
        await p.remove(_kPhotoPath);
      }
      if (selfiePath != null) {
        await p.setString(_kSelfiePath, selfiePath!);
      } else {
        await p.remove(_kSelfiePath);
      }
      await p.setBool(_kOnboarded, isOnboarded);
    } on Exception {
      // ignore — best-effort persistence
    }
    notifyListeners();
  }

  /// Clears the in-memory draft. Does NOT touch the persisted copy —
  /// use [signOut] for that.
  void reset() {
    name = '';
    email = '';
    phone = '';
    countryCode = '+91';
    role = '';
    designation = '';
    company = '';
    introduction = '';
    photoPath = null;
    selfiePath = null;
    notifyListeners();
  }

  /// Clears both memory and persisted state.
  Future<void> signOut() async {
    reset();
    isOnboarded = false;
    try {
      final p = await SharedPreferences.getInstance();
      for (final k in const [
        _kName,
        _kEmail,
        _kPhone,
        _kCountryCode,
        _kRole,
        _kDesignation,
        _kCompany,
        _kIntroduction,
        _kPhotoPath,
        _kSelfiePath,
        _kOnboarded,
      ]) {
        await p.remove(k);
      }
    } on Exception {
      // ignore
    }
    notifyListeners();
  }
}
