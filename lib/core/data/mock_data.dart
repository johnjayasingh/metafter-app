import 'package:flutter/foundation.dart';

import '../../features/signup/data/signup_draft.dart';

/// Centralised dev-time mock data so we can quickly skim through the
/// signup flow without retyping everything on every hot restart.
///
/// Add new mocks here (e.g. nearby people, will templates, etc.) so the
/// rest of the app has a single source of fake data to import.
class MockData {
  MockData._();

  static const String name = 'Luna Ray';
  static const String email = 'luna.ray@metafter.dev';
  static const String phone = '9876543210';
  static const String countryCode = '+91';
  static const String role = 'Working Professional';
  static const String designation = 'UI / UX Designer';
  static const String company = 'Techinorm';
  static const String introduction =
      'UI/UX designer focused on building simple, intuitive and user-first '
      'digital experiences.';

  /// Populates [SignupDraft.instance] with sample data so the multi-step
  /// signup flow is one-tap navigable. No-op outside debug builds, and
  /// no-op if the user already has a persisted draft.
  static void prefillSignupDraft({bool force = false}) {
    if (!kDebugMode && !force) return;
    final d = SignupDraft.instance;
    // Don't clobber a real persisted signup.
    if (!force && d.isOnboarded) return;
    if (!force && d.name.isNotEmpty) return;
    d.update(() {
      d.name = name;
      d.email = email;
      d.phone = phone;
      d.countryCode = countryCode;
      d.role = role;
      d.designation = designation;
      d.company = company;
      d.introduction = introduction;
    });
  }
}
