/// Application Environment Enum
enum Environment {
  development,
  staging,
  production,
}

/// Global Application Configuration Class
class AppConfig {
  final String appName;
  final Environment environment;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final bool enableLogging;
  final bool enableAnalytics;
  final bool enableChat;
  final String apiVersion;
  final String webRecaptchaSiteKey;

  const AppConfig({
    required this.appName,
    required this.environment,
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
    this.enableLogging = true,
    this.enableAnalytics = false,
    this.enableChat = true,
    this.apiVersion = 'v1',
    this.webRecaptchaSiteKey = '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI',
  });

  /// Factory for Development Environment
  factory AppConfig.development() {
    return const AppConfig(
      appName: 'Lambac Coffee (Dev)',
      environment: Environment.development,
      apiBaseUrl: 'https://api-dev.lambaccoffee.com/v1',
      enableLogging: true,
      enableAnalytics: false,
      enableChat: true,
    );
  }

  /// Factory for Staging Environment
  factory AppConfig.staging() {
    return const AppConfig(
      appName: 'Lambac Coffee (Staging)',
      environment: Environment.staging,
      apiBaseUrl: 'https://api-staging.lambaccoffee.com/v1',
      enableLogging: true,
      enableAnalytics: true,
      enableChat: true,
    );
  }

  /// Factory for Production Environment
  factory AppConfig.production() {
    return const AppConfig(
      appName: 'Lambac Coffee Roastery',
      environment: Environment.production,
      apiBaseUrl: 'https://api.lambaccoffee.com/v1',
      enableLogging: false,
      enableAnalytics: true,
      enableChat: true,
    );
  }

  /// Factory to initialize from Dart Define flags or custom environment
  factory AppConfig.fromEnvironment() {
    const envString = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    const customBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

    final env = switch (envString.toLowerCase()) {
      'production' || 'prod' => Environment.production,
      'staging' || 'stage' => Environment.staging,
      _ => Environment.development,
    };

    const recaptchaKey = String.fromEnvironment('RECAPTCHA_SITE_KEY', defaultValue: '');

    final baseConfig = switch (env) {
      Environment.production => AppConfig.production(),
      Environment.staging => AppConfig.staging(),
      Environment.development => AppConfig.development(),
    };

    var config = baseConfig;
    if (customBaseUrl.isNotEmpty) {
      config = config.copyWith(apiBaseUrl: customBaseUrl);
    }
    if (recaptchaKey.isNotEmpty) {
      config = config.copyWith(webRecaptchaSiteKey: recaptchaKey);
    }
    return config;
  }

  bool get isProduction => environment == Environment.production;
  bool get isStaging => environment == Environment.staging;
  bool get isDevelopment => environment == Environment.development;

  AppConfig copyWith({
    String? appName,
    Environment? environment,
    String? apiBaseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    bool? enableLogging,
    bool? enableAnalytics,
    bool? enableChat,
    String? apiVersion,
    String? webRecaptchaSiteKey,
  }) {
    return AppConfig(
      appName: appName ?? this.appName,
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      enableLogging: enableLogging ?? this.enableLogging,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableChat: enableChat ?? this.enableChat,
      apiVersion: apiVersion ?? this.apiVersion,
      webRecaptchaSiteKey: webRecaptchaSiteKey ?? this.webRecaptchaSiteKey,
    );
  }
}
