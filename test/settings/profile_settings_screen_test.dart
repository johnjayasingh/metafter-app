import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/features/home/presentation/pages/profile_settings_screen.dart';

import '../services/fakes.dart';
import 'settings_test_utils.dart';

void main() {
  late FakeSettingsRepository settings;

  Future<void> pump(WidgetTester tester) async {
    // Tall phone viewport so the whole settings list (and pickers) fit.
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProfileSettingsScreen()));
    await tester.pumpAndSettle();
  }

  setUp(() {
    settings = installFakeServices().settings;
  });

  testWidgets('header renders the local profile', (tester) async {
    await pump(tester);
    expect(find.text('Luna Ray'), findsOneWidget);
    expect(find.text('UI / UX Designer – Techinorm'), findsOneWidget);
    expect(find.text('See Profile'), findsOneWidget);
  });

  testWidgets('mood ring picker writes through to the repository',
      (tester) async {
    await pump(tester);
    expect(find.text('Networking'), findsOneWidget); // current value chip

    await tester.tap(find.text('Set Mood Ring'));
    await tester.pumpAndSettle();
    // All four MoodRing options are offered (§11.1).
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Catchup'), findsOneWidget);
    expect(find.text('Just Checking'), findsOneWidget);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(settings.mood.value, MoodRing.friends);
    // Row chip updates live from the same listenable.
    expect(find.text('Friends'), findsOneWidget);
  });

  testWidgets('time format row toggles use24hTime', (tester) async {
    await pump(tester);
    expect(find.text('12hr'), findsOneWidget);

    await tester.tap(find.text('Time Format'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24hr'));
    await tester.pumpAndSettle();

    expect(settings.use24hTime.value, isTrue);
    expect(find.text('24hr'), findsOneWidget);
  });

  testWidgets('language picker writes through', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();

    expect(settings.language.value, 'French');
  });

  testWidgets('accessibility sheet drives reduce motion and larger text',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Accessibility'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reduce Motion'));
    await tester.pumpAndSettle();
    expect(settings.reduceMotion.value, isTrue);

    await tester.tap(find.text('Larger Text'));
    await tester.pumpAndSettle();
    expect(settings.largerText.value, isTrue);
  });

  testWidgets('discoverable time picker writes the session duration',
      (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Discoverable Time'));
    await tester.pumpAndSettle();
    expect(find.text('4 hrs'), findsOneWidget);

    await tester.tap(find.text('Discoverable Time'));
    await tester.pumpAndSettle();
    expect(find.text('30 min'), findsOneWidget);

    await tester.tap(find.text('8 hrs'));
    await tester.pumpAndSettle();

    expect(settings.discoverableDuration.value, const Duration(hours: 8));
  });

  testWidgets('proximity distance picker writes the distance budget',
      (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Proximity Distance'));
    await tester.pumpAndSettle();
    expect(find.text('2 mts'), findsOneWidget);

    await tester.tap(find.text('Proximity Distance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 mts'));
    await tester.pumpAndSettle();

    expect(settings.distanceBudget.value, 5.0);
  });

  testWidgets('share profile is a coming-soon stub', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Share Profile'));
    await tester.pump();
    expect(find.text('Profile sharing is coming soon.'), findsOneWidget);
  });

  testWidgets('pro dialog reports purchases coming soon and links pricing',
      (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Get MetAfter Pro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get MetAfter Pro'));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to Pro'), findsOneWidget);
    expect(find.text('See other plans'), findsOneWidget);

    await tester.tap(find.text('Continue with Pro'));
    await tester.pump();
    expect(find.text('Purchases are coming soon.'), findsOneWidget);
  });
}
