import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/features/home/presentation/pages/pricing_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    // Tall viewport so the lazily-built plan cards are both realized.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: PricingScreen()));
    await tester.pumpAndSettle();
  }

  Finder billingToggle() => find.byType(AnimatedContainer).first;

  testWidgets('annual mode (default) shows the §11.3 pro card', (tester) async {
    await pump(tester);

    expect(
      find.text(
        'We believe MetAfter should be accessible to all. '
        'Simple, transparent pricing.',
      ),
      findsOneWidget,
    );
    expect(find.text('Annual pricing '), findsOneWidget);
    expect(find.text('(Save 20%)'), findsOneWidget);

    expect(find.text(r'$10/mth'), findsOneWidget);
    expect(find.text('Pro Plan'), findsOneWidget);
    // Both cards bill annually in annual mode.
    expect(find.text('Billed annually.'), findsNWidgets(2));
    expect(find.text('Billed monthly.'), findsNothing);

    // §11.3 feature checklist.
    expect(find.text('Access to all basic features'), findsWidgets);
    expect(find.text('Unlimited connection requests'), findsOneWidget);
    expect(find.text('Invitation notes to individual users'), findsOneWidget);
    expect(find.text('Priority chat & email support'), findsOneWidget);
  });

  testWidgets('toggle switches to monthly pricing', (tester) async {
    await pump(tester);

    await tester.tap(billingToggle());
    await tester.pumpAndSettle();

    expect(find.text(r'$12/mth'), findsOneWidget);
    expect(find.text('Billed monthly.'), findsNWidgets(2));
    expect(find.text('Billed annually.'), findsNothing);

    // And back to annual.
    await tester.tap(billingToggle());
    await tester.pumpAndSettle();
    expect(find.text(r'$10/mth'), findsOneWidget);
    expect(find.text('Billed annually.'), findsNWidgets(2));
  });

  testWidgets('CTA reports purchases coming soon', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Get Started').first);
    await tester.pump();

    expect(find.text('Purchases are coming soon.'), findsOneWidget);
  });
}
