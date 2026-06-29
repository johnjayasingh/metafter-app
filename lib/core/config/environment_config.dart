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
        return 'https://1fpt127p2k.execute-api.ap-south-1.amazonaws.com/dev/v1';
      case Environment.dev:
        return 'https://1fpt127p2k.execute-api.ap-south-1.amazonaws.com/dev/v1';
      case Environment.uat:
        return 'http://16.176.75.140:8000'; // TODO: uat not deployed yet
      case Environment.production:
        return 'http://16.176.75.140:8000'; // TODO: prod not deployed yet
    }
  }

  // --- AWS backend config (per environment) --------------------------------
  // dev values come from the deployed `metafter-dev-*` CloudFormation outputs.

  static String get region {
    switch (_environment) {
      case Environment.local:
      case Environment.dev:
        return 'ap-south-1';
      case Environment.uat:
      case Environment.production:
        return 'ap-south-1'; // TODO
    }
  }

  static String get cognitoUserPoolId {
    switch (_environment) {
      case Environment.local:
      case Environment.dev:
        return 'ap-south-1_Puu3FZD2g';
      case Environment.uat:
      case Environment.production:
        return ''; // TODO: not deployed yet
    }
  }

  static String get cognitoClientId {
    switch (_environment) {
      case Environment.local:
      case Environment.dev:
        return '3oefeu82020tmag4642f792cs7';
      case Environment.uat:
      case Environment.production:
        return ''; // TODO: not deployed yet
    }
  }

  static String get cognitoIdentityPoolId {
    switch (_environment) {
      case Environment.local:
      case Environment.dev:
        return 'ap-south-1:0cd3ceef-d949-41e7-83f2-b06a72b3a496';
      case Environment.uat:
      case Environment.production:
        return ''; // TODO: not deployed yet
    }
  }

  static String get iotEndpoint {
    switch (_environment) {
      case Environment.local:
      case Environment.dev:
        return 'alubdyo9lpvuy-ats.iot.ap-south-1.amazonaws.com';
      case Environment.uat:
      case Environment.production:
        return ''; // TODO: not deployed yet
    }
  }

  static String get mediaBucket {
    switch (_environment) {
      case Environment.local:
      case Environment.dev:
        return 'metafter-dev-media-419698484406';
      case Environment.uat:
      case Environment.production:
        return ''; // TODO: not deployed yet
    }
  }

  /// The Cognito environment label used in IoT topic names
  /// (`metafter/<stage>/...`). All current envs map to the deployed `dev` stage.
  static String get backendStage => 'dev';

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
