import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/features/home/presentation/pages/privacy_security_screen.dart';

import '../services/fakes.dart';
import 'settings_test_utils.dart';

void main() {
  late FakeSettingsRepository settings;

  Future<void> pump(WidgetTester tester) async {
    // Tall phone viewport so all eight switch rows fit without scrolling.
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: PrivacySecurityScreen()));
    await tester.pumpAndSettle();
  }

  setUp(() {
    settings = installFakeServices().settings;
  });

  Future<void> flip(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    final row = find.ancestor(
      of: find.text(label),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(of: row.first, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders all eight privacy switches and the fixed header',
      (tester) async {
    await pump(tester);
    expect(find.text('PRIVACY PREFERENCES'), findsOneWidget);
    for (final label in const [
      'Read Receipts',
      'Typing Indicator',
      'Video Call',
      'Audio Call',
      'Disappearing Messages',
      'Show Company Name',
      'Show Designation',
      'Incognito Scan',
    ]) {
      await tester.ensureVisible(find.text(label));
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(Switch), findsNWidgets(8));
  });

  testWidgets('switches write through to the settings repository',
      (tester) async {
    await pump(tester);

    expect(settings.readReceipts.value, isTrue);
    await flip(tester, 'Read Receipts');
    expect(settings.readReceipts.value, isFalse);

    await flip(tester, 'Typing Indicator');
    expect(settings.typingIndicator.value, isFalse);

    await flip(tester, 'Video Call');
    expect(settings.allowVideoCall.value, isFalse);

    await flip(tester, 'Disappearing Messages');
    expect(settings.disappearingDefault.value, isTrue);

    await flip(tester, 'Show Company Name');
    expect(settings.showCompany.value, isFalse);

    await flip(tester, 'Incognito Scan');
    expect(settings.incognitoScan.value, isTrue);
  });

  testWidgets('switch reflects external repository changes', (tester) async {
    await pump(tester);
    await settings.setReadReceipts(false);
    await tester.pump();
    final row = find.ancestor(
      of: find.text('Read Receipts'),
      matching: find.byType(Row),
    );
    final sw = tester.widget<Switch>(
      find.descendant(of: row.first, matching: find.byType(Switch)),
    );
    expect(sw.value, isFalse);
  });

  testWidgets('name visibility picker uses the shared enum and persists',
      (tester) async {
    await pump(tester);
    expect(settings.nameVisibility.value, PrivacyVisibility.visibleToAll);

    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(find.text('Visible to connections'), findsOneWidget);
    expect(find.text('Hidden'), findsOneWidget);

    await tester.tap(find.text('Hidden'));
    await tester.pumpAndSettle();

    expect(settings.nameVisibility.value, PrivacyVisibility.hidden);
    expect(find.text('Hidden'), findsOneWidget); // row value chip updated
  });

  testWidgets('company visibility picker persists', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Company Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visible to connections'));
    await tester.pumpAndSettle();

    expect(
      settings.companyVisibility.value,
      PrivacyVisibility.visibleToConnections,
    );
  });
}
