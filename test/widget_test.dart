import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/proximity/simulated_proximity_engine.dart';
import 'package:metafter/core/routes/app_router.dart';
import 'package:metafter/core/widgets/peer_avatar.dart';
import 'package:metafter/features/signup/data/signup_draft.dart';
import 'package:metafter/main.dart';

import 'shell/shell_fakes.dart';
import 'services/fakes.dart';

/// App-shell smoke tests: the real MetafterApp (router, theme, HomeShell)
/// against a fully faked AppServices graph — no sqflite, no BLE, no network.
void main() {
  setUp(() {
    // Route splash straight to Home instead of onboarding.
    SignupDraft.instance.isOnboarded = true;
  });

  Future<void> pumpToHome(WidgetTester tester) async {
    await tester.pumpWidget(const MetafterApp());
    // AppRouter.router is a process-wide singleton, so force the location
    // instead of relying on the splash timer state of earlier tests.
    AppRouter.router.go(AppRouter.home);
    // Let the splash beat's 1800 ms timer fire so it never leaks.
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();
  }

  testWidgets('Home renders the idle discovery card', (tester) async {
    installShellTestServices();
    await pumpToHome(tester);

    expect(find.text('You are not discoverable'), findsOneWidget);
    expect(find.text('Let’s Go!'), findsOneWidget);
    expect(find.text('Discoverable for the next'), findsOneWidget);
    expect(find.text('Set Distance'), findsOneWidget);
  });

  testWidgets('duration row opens the picker and persists the choice',
      (tester) async {
    final services = installShellTestServices();
    await pumpToHome(tester);

    // Default 4 hrs from settings.
    expect(find.text('4 hrs'), findsOneWidget);

    await tester.tap(find.text('4 hrs'));
    await tester.pumpAndSettle();

    // Spec options are all on offer (DESIGN_SPEC §4.1).
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('8 hrs'), findsOneWidget);

    await tester.tap(find.text('8 hrs').last);
    await tester.pumpAndSettle();

    expect(services.settings.discoverableDuration.value,
        const Duration(hours: 8));
    expect(find.text('8 hrs'), findsOneWidget);
  });

  testWidgets('starting a session shows the Meet radar with simulated peers',
      (tester) async {
    final engine = SimulatedProximityEngine(timeScale: 0.01);
    final session = FakeSessionService(engine: engine);
    final services = installShellTestServices(engine: engine, session: session);
    // Disable the looping radar animations so pumpAndSettle can settle.
    (services.settings as FakeSettingsRepository).reduceMotion.value = true;

    await pumpToHome(tester);
    await tester.tap(find.text('Let’s Go!'));
    await tester.pump();

    // Meet state is on.
    expect(find.text('You are discoverable'), findsOneWidget);
    expect(find.textContaining('Time Remaining:'), findsOneWidget);

    // Simulated personas pop into range over the (scaled) first seconds.
    for (var i = 0;
        i < 60 && find.byType(PeerAvatar).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(PeerAvatar), findsWidgets);

    // End the session (confirm dialog) — back to Home, engine stopped.
    await tester.tap(find.text('End Session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End'));
    await tester.pumpAndSettle();

    expect(find.text('You are not discoverable'), findsOneWidget);
    expect(engine.isRunning, isFalse);
    await engine.dispose();
  });
}
