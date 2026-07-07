import '../proximity/proximity_engine.dart';
import '../repositories/repositories.dart';
import '../transport/transport_client.dart';
import 'services.dart';

/// Composition root / service locator.
///
/// [init] is called once from `bootstrap()` in main.dart (after
/// EnvironmentConfig is set and SignupDraft is loaded). It opens the local
/// database, loads keys, picks the proximity engine for the flavor
/// (SimulatedProximityEngine for local/dev, BleProximityEngine otherwise),
/// and wires the services. UI code accesses everything through
/// `AppServices.I`.
class AppServices {
  AppServices({
    required this.profile,
    required this.encounters,
    required this.requests,
    required this.connections,
    required this.messages,
    required this.settings,
    required this.engine,
    required this.transport,
    required this.session,
    required this.connection,
    required this.messaging,
  });

  final ProfileRepository profile;
  final EncounterRepository encounters;
  final RequestRepository requests;
  final ConnectionRepository connections;
  final MessageRepository messages;
  final SettingsRepository settings;

  final ProximityEngine engine;
  final TransportClient transport;

  final SessionService session;
  final ConnectionService connection;
  final MessageService messaging;

  static AppServices? _instance;

  static AppServices get I {
    final i = _instance;
    if (i == null) {
      throw StateError('AppServices.init() has not completed');
    }
    return i;
  }

  static bool get isReady => _instance != null;

  /// Installed once by `initAppServices()` in bootstrap_services.dart,
  /// which builds every concrete implementation. bootstrap() in main.dart
  /// awaits that function during startup.
  static void install(AppServices services) => _instance = services;
}
