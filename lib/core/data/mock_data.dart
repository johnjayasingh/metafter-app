import 'package:flutter/foundation.dart';

import '../../features/signup/data/signup_draft.dart';
import '../domain/models.dart';

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

  // ── Demo content (Discover & Messages) ────────────────────────────────
  //
  // Presentation-layer sample rows matching the design prototype
  // (MetAfterDemo.mov), so the app can be demoed with populated lists on a
  // device that has no real encounters/threads. Toggled from Profile
  // Settings → "Demo Content". Never written to the database — the screens
  // merge these rows in front of the live streams while the toggle is on.

  /// Session-scoped toggle for the sample rows below.
  static final ValueNotifier<bool> demoContent = ValueNotifier<bool>(false);

  /// Prefix marking demo rows so taps/actions can be intercepted.
  static const String demoPrefix = 'demo-';

  static ProfileCard _card(String id, String name, String designation,
          String company) =>
      ProfileCard(
        sub: '$demoPrefix$id',
        name: name,
        designation: designation,
        company: company,
      );

  /// Today's crossed-paths timeline, exactly as in the prototype.
  static List<Encounter> demoEncounters() {
    final now = DateTime.now();
    DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
    Encounter e(String id, String name, String designation, String company,
            DateTime seen) =>
        Encounter(
          id: '$demoPrefix$id',
          peerEid: '$demoPrefix$id',
          card: _card(id, name, designation, company),
          firstSeen: seen,
          lastSeen: seen,
          meters: 2,
        );
    return [
      e('e1', 'Koby Stone', 'SVP Engineering', 'InnoVision', at(16, 28)),
      e('e2', 'Luna Ray', 'Head of Marketing', 'MarketVerse', at(16, 24)),
      e('e3', 'Owen Hill', 'VP, Sales', 'SaleSail', at(16, 22)),
      e('e4', 'Koby Stone', 'SVP Engineering', 'InnoVision', at(16, 18)),
      e('e5', 'Luna Ray', 'Head of Marketing', 'MarketVerse', at(16, 12)),
      e('e6', 'Owen Hill', 'VP, Sales', 'SaleSail', at(16, 10)),
    ];
  }

  /// Chat list rows, exactly as in the prototype.
  static List<ThreadSummary> demoThreads() {
    final now = DateTime.now();
    ThreadSummary t(String id, String name, String message, int hoursAgo,
            {bool fromMe = false}) =>
        ThreadSummary(
          peerSub: '$demoPrefix$id',
          card: _card(id, name, '', ''),
          lastMessage: message,
          lastMessageAt: now.subtract(Duration(hours: hoursAgo)),
          lastFromMe: fromMe,
        );
    return [
      t('p1', 'Candice Wue', "Okay, Let's Go.", 3, fromMe: true),
      t('p2', 'Zahir Mays', 'Whats the plan', 6, fromMe: true),
      t('p3', 'Rane Wells', 'Meet you there at 7?', 12),
      t('p4', 'Sophia Ramirez', "Don't forget the keys", 18),
      t('p5', 'Jasmine', 'How are you?', 22),
      t('p6', 'Candice Wue', "Okay, Let's Go.", 3, fromMe: true),
      t('p7', 'Zahir Mays', 'Whats the plan', 6, fromMe: true),
      t('p8', 'Rane Wells', 'Meet you there at 7?', 12),
    ];
  }

  /// Populates [SignupDraft.instance] with sample data so the multi-step
  /// signup flow is one-tap navigable. No-op outside debug builds, and
  /// no-op if the user already has a persisted draft.
  static void prefillSignupDraft({bool force = false}) {
    if (!kDebugMode && !force) return;
    final d = SignupDraft.instance;
    // Don't clobber a real persisted signup.
    if (!force && d.isOnboarded) return;
    if (!force && d.name.isNotEmpty) return;
    // Only text fields are prefilled — verification state (livenessSessionId,
    // verificationPhotoKey) and the photo must never be faked as done.
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
