import '../config/environment_config.dart';

/// API endpoint paths.
///
/// Keep this file as the single source of truth for backend paths.
/// Group endpoints by feature with section comments as you add them.
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => EnvironmentConfig.baseUrl;

  // Auth (add as needed)
  static const String refreshToken = '/user/refresh-token';
}
