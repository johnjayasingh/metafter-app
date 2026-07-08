import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/environment_config.dart';
import 'core/data/mock_data.dart';
import 'core/network/api_client.dart';
import 'core/routes/app_router.dart';
import 'core/services/app_services.dart';
import 'core/services/bootstrap_services.dart';
import 'core/theme/app_theme.dart';
import 'features/signup/data/signup_draft.dart';

/// Global navigator key — allows triggering navigation from outside the
/// widget tree (e.g. session timeout handlers).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Shared bootstrap for every flavor entrypoint.
///
/// Each flavor (`main.dart`, `main_dev.dart`, `main_uat.dart`,
/// `main_local.dart`) sets its [Environment] then calls [bootstrap].
Future<void> bootstrap({
  required Environment environment,
  String? appTitle,
  bool debugBanner = false,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  EnvironmentConfig.setEnvironment(environment);
  ApiClient().initialize();

  // When the Cognito session can't be refreshed, send the user back to the
  // phone entry to re-authenticate (signUpWithPhone is idempotent, so the
  // same screens serve both first-time signup and returning-user login).
  ApiClient().onSessionTimeout = () async {
    await SignupDraft.instance.signOut();
    // Wipe every local table before routing to signup so the next account on
    // a shared device never inherits the previous user's messages,
    // connections, or encounters. Guarded because the service graph may not
    // be installed yet if a timeout fires mid-bootstrap.
    if (AppServices.isReady) await wipeLocalData();
    AppRouter.router.go(AppRouter.signupBasics);
  };

  // Restore any previously-persisted signup draft (keeps the user signed
  // in across launches).
  await SignupDraft.instance.load();

  // Build the local-first service graph (crypto keys, SQLite repositories,
  // proximity engine, relay transport) and install it as AppServices.I.
  // Local/dev flavors run against the simulated proximity engine so the
  // whole app is drivable on emulators/simulators without BLE hardware.
  await initAppServices(
    simulated: EnvironmentConfig.isLocal || EnvironmentConfig.isDev,
  );

  // Prefill the signup draft with mock data in debug builds so we can
  // tab through the multi-step signup flow without retyping everything.
  // Skipped if a real draft was already persisted.
  MockData.prefillSignupDraft();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MetafterApp(
    title: appTitle ?? 'Metafter',
    debugBanner: debugBanner,
  ));
}

class MetafterApp extends StatelessWidget {
  const MetafterApp({
    super.key,
    this.title = 'Metafter',
    this.debugBanner = false,
  });

  final String title;
  final bool debugBanner;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: debugBanner,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}

/// Production entrypoint.
Future<void> main() async {
  await bootstrap(environment: Environment.production);
}
