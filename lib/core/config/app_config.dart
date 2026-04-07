/// Environment configuration for the app.
/// Supports development (Mockoon), staging, and production environments.
enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  AppConfig._();

  static Environment _environment = Environment.development;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  /// Base URL for API calls
  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://localhost:3000'; // Mockoon
      case Environment.staging:
        return 'https://api-staging.kindbanking.com';
      case Environment.production:
        return 'https://api.kindbanking.com';
    }
  }

  /// Whether to enable debug features
  static bool get isDebug => _environment == Environment.development;

  /// Whether to show dev shortcuts (quick login, etc.)
  static bool get showDevShortcuts => _environment == Environment.development;

  /// API timeout in milliseconds
  static int get apiTimeout {
    switch (_environment) {
      case Environment.development:
        return 30000; // 30 seconds for Mockoon
      case Environment.staging:
      case Environment.production:
        return 15000; // 15 seconds
    }
  }

  /// LLM API endpoint
  static String get llmBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://localhost:3000/api/v1/llm'; // Mockoon
      case Environment.staging:
        return 'https://api-staging.kindbanking.com/api/v1/llm';
      case Environment.production:
        return 'https://api.kindbanking.com/api/v1/llm';
    }
  }

  /// Deep link scheme
  static const String deepLinkScheme = 'kindbanking';

  /// Universal link host
  static const String universalLinkHost = 'app.kindbanking.com';
}
