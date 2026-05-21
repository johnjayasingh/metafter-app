import 'core/config/environment_config.dart';
import 'main.dart';

Future<void> main() async {
  await bootstrap(
    environment: Environment.uat,
    appTitle: 'Metafter [UAT]',
    debugBanner: true,
  );
}
