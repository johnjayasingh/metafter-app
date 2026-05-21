enum Environment {
  local,
  dev,
  uat,
  production,
}

class EnvironmentConfig {
  static Environment _environment = Environment.production;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static String get baseUrl {
    switch (_environment) {
      case Environment.local:
        return 'http://13.54.59.56:8000'; // Same as DEV, with debug pre-fill
      case Environment.dev:
        return 'http://13.54.59.56:8000';
      case Environment.uat:
        return 'http://16.176.75.140:8000';
      case Environment.production:
        return 'http://16.176.75.140:8000';
    }
  }

  static String get environmentName {
    switch (_environment) {
      case Environment.local:
        return 'LOCAL';
      case Environment.dev:
        return 'DEV';
      case Environment.uat:
        return 'UAT';
      case Environment.production:
        return 'PROD';
    }
  }

  static bool get isProduction => _environment == Environment.production;
  static bool get isDev => _environment == Environment.dev;
  static bool get isUat => _environment == Environment.uat;
  static bool get isLocal => _environment == Environment.local;
  
  // Debug pre-fill enabled only in local environment for faster testing
  // Can be toggled at runtime via the UI toggle on AHD/POA tabs
  static bool _debugPrefillOverride = true;

  static bool get useDebugPrefill =>
      _environment == Environment.local && _debugPrefillOverride;

  /// Toggle debug prefill on/off (only works in local environment)
  static void setDebugPrefill(bool enabled) {
    if (_environment == Environment.local) {
      _debugPrefillOverride = enabled;
    }
  }
}
