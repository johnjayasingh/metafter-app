import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/environment_config.dart';
import 'core/network/api_client.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

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
