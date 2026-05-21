import 'core/config/environment_config.dart';
import 'main.dart';

Future<void> main() async {
  await bootstrap(
    environment: Environment.local,
    appTitle: 'Metafter [LOCAL]',
    debugBanner: true,
  );
}
