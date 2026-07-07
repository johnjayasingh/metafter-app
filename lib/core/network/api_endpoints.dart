import '../config/environment_config.dart';

/// API endpoint paths.
///
/// Keep this file as the single source of truth for backend paths.
/// Group endpoints by feature with section comments as you add them.
///
/// NOTE: the backend keeps no personal profile data (DESIGN_SPEC §13) —
/// there are no `/profile*` endpoints. Identity verification is a transient
/// photo + liveness comparison; only `{verified, badgeSig}` survives on the
/// directory row.
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => EnvironmentConfig.baseUrl;

  // --- Identity verification (Rekognition Face Liveness + CompareFaces) ---
  static const String verificationStart = '/verification/start';
  static const String verificationComplete = '/verification/complete';

  // --- Relay transport: key directory + E2E mailbox (ARCHITECTURE.md §4.3) ---
  static const String directory = '/directory';
  static String directoryEntry(String sub) => '$directory/$sub';
  static const String mailbox = '/mailbox';
  static String mailboxEnvelope(String envelopeId) => '$mailbox/$envelopeId';
}
