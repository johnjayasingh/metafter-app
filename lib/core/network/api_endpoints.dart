import '../config/environment_config.dart';

/// API endpoint paths.
///
/// Keep this file as the single source of truth for backend paths.
/// Group endpoints by feature with section comments as you add them.
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => EnvironmentConfig.baseUrl;

  // --- Profile ---
  static const String profile = '/profile';
  static const String photoUploadUrl = '/profile/photo-upload-url';

  // --- Identity verification (Rekognition Face Liveness + CompareFaces) ---
  static const String livenessSession = '/profile/liveness-session';
  static const String verifyIdentity = '/profile/verify-identity';
}
