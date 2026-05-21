import 'core/config/environment_config.dart';
import 'main.dart';

Future<void> main() async {
  await bootstrap(
    environment: Environment.dev,
    appTitle: 'Metafter [DEV]',
    debugBanner: true,
  );
}
