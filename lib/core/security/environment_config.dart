import 'package:flutter/foundation.dart';

/// Supported deployment and runtime environments for Recallr.
enum AppEnvironment {
  development,
  staging,
  production;

  /// Resolves the current runtime environment from compilation flags or environment variables.
  static AppEnvironment fromEnvironment([String? overrideName]) {
    final envName = overrideName ??
        const String.fromEnvironment('APP_ENV',
            defaultValue: String.fromEnvironment('ENVIRONMENT', defaultValue: ''));

    if (envName.isNotEmpty) {
      switch (envName.toLowerCase()) {
        case 'production':
        case 'prod':
          return AppEnvironment.production;
        case 'staging':
        case 'stage':
          return AppEnvironment.staging;
        case 'development':
        case 'dev':
        default:
          return AppEnvironment.development;
      }
    }

    // Default: Release builds map to production unless explicitly set
    return kReleaseMode ? AppEnvironment.production : AppEnvironment.development;
  }
}

/// Supported Firebase App Check provider types.
enum AppCheckProviderType {
  playIntegrity,
  deviceCheck,
  appAttest,
  reCaptchaV3,
  debug,
  custom,
}

/// Centralized security and environment configuration manager for Recallr.
class EnvironmentConfig {
  final AppEnvironment environment;
  final String firebaseProjectId;
  final bool enableAppCheck;
  final AppCheckProviderType appCheckProviderType;
  final String? appCheckRecaptchaSiteKey;
  final bool useEmulators;
  final String emulatorHost;
  final int authEmulatorPort;
  final int firestoreEmulatorPort;
  final int storageEmulatorPort;
  final String? geminiApiKey;
  final bool enableVerboseLogging;
  final bool allowMockFallback;

  const EnvironmentConfig({
    this.environment = AppEnvironment.development,
    this.firebaseProjectId = 'recallr-b0bcc',
    this.enableAppCheck = false,
    this.appCheckProviderType = AppCheckProviderType.debug,
    this.appCheckRecaptchaSiteKey,
    this.useEmulators = false,
    this.emulatorHost = 'localhost',
    this.authEmulatorPort = 9099,
    this.firestoreEmulatorPort = 8080,
    this.storageEmulatorPort = 9199,
    this.geminiApiKey,
    this.enableVerboseLogging = false,
    this.allowMockFallback = true,
  });

  /// Factory resolving active runtime environment from build-time compilation flags.
  factory EnvironmentConfig.current() {
    final env = AppEnvironment.fromEnvironment();
    final appCheckFlag = const bool.fromEnvironment('ENABLE_APP_CHECK', defaultValue: false);
    final verboseLog = const bool.fromEnvironment('VERBOSE_LOGGING', defaultValue: false);
    final emulatorsFlag = const bool.fromEnvironment('USE_EMULATORS', defaultValue: false);
    final hostFlag = const String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');
    final apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    final recaptchaKey = const String.fromEnvironment('RECAPTCHA_SITE_KEY', defaultValue: '');
    final customProjectId = const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');

    final resolvedProjectId = customProjectId.isNotEmpty
        ? customProjectId
        : (env == AppEnvironment.production
            ? 'recaller-prod'
            : (env == AppEnvironment.staging ? 'recaller-staging' : 'recallr-b0bcc'));

    final AppCheckProviderType defaultProvider;
    if (env == AppEnvironment.production) {
      if (kIsWeb) {
        defaultProvider = AppCheckProviderType.reCaptchaV3;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        defaultProvider = AppCheckProviderType.appAttest;
      } else {
        defaultProvider = AppCheckProviderType.playIntegrity;
      }
    } else {
      defaultProvider = AppCheckProviderType.debug;
    }

    return EnvironmentConfig(
      environment: env,
      firebaseProjectId: resolvedProjectId,
      enableAppCheck: env == AppEnvironment.production ? true : appCheckFlag,
      appCheckProviderType: defaultProvider,
      appCheckRecaptchaSiteKey: recaptchaKey.isNotEmpty ? recaptchaKey : null,
      useEmulators: env == AppEnvironment.production ? false : emulatorsFlag,
      emulatorHost: hostFlag,
      authEmulatorPort: const int.fromEnvironment('AUTH_EMULATOR_PORT', defaultValue: 9099),
      firestoreEmulatorPort: const int.fromEnvironment('FIRESTORE_EMULATOR_PORT', defaultValue: 8080),
      storageEmulatorPort: const int.fromEnvironment('STORAGE_EMULATOR_PORT', defaultValue: 9199),
      geminiApiKey: apiKey.isNotEmpty ? apiKey : null,
      enableVerboseLogging: env == AppEnvironment.development ? true : verboseLog,
      allowMockFallback: env != AppEnvironment.production,
    );
  }

  /// Factory for development configuration.
  factory EnvironmentConfig.development({
    bool useEmulators = false,
    String emulatorHost = 'localhost',
    String? geminiApiKey,
  }) {
    return EnvironmentConfig(
      environment: AppEnvironment.development,
      firebaseProjectId: 'recallr-b0bcc',
      enableAppCheck: false,
      appCheckProviderType: AppCheckProviderType.debug,
      useEmulators: useEmulators,
      emulatorHost: emulatorHost,
      geminiApiKey: geminiApiKey,
      enableVerboseLogging: true,
      allowMockFallback: true,
    );
  }

  /// Factory for staging configuration.
  factory EnvironmentConfig.staging({
    String? geminiApiKey,
    bool enableAppCheck = true,
    String? recaptchaSiteKey,
  }) {
    return EnvironmentConfig(
      environment: AppEnvironment.staging,
      firebaseProjectId: 'recaller-staging',
      enableAppCheck: enableAppCheck,
      appCheckProviderType: AppCheckProviderType.debug,
      appCheckRecaptchaSiteKey: recaptchaSiteKey,
      useEmulators: false,
      geminiApiKey: geminiApiKey,
      enableVerboseLogging: false,
      allowMockFallback: true,
    );
  }

  /// Factory for production configuration.
  factory EnvironmentConfig.production({
    String? geminiApiKey,
    String? recaptchaSiteKey,
    String firebaseProjectId = 'recaller-prod',
  }) {
    final AppCheckProviderType provider;
    if (kIsWeb) {
      provider = AppCheckProviderType.reCaptchaV3;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      provider = AppCheckProviderType.appAttest;
    } else {
      provider = AppCheckProviderType.playIntegrity;
    }

    return EnvironmentConfig(
      environment: AppEnvironment.production,
      firebaseProjectId: firebaseProjectId,
      enableAppCheck: true,
      appCheckProviderType: provider,
      appCheckRecaptchaSiteKey: recaptchaSiteKey,
      useEmulators: false,
      geminiApiKey: geminiApiKey,
      enableVerboseLogging: false,
      allowMockFallback: false,
    );
  }

  bool get isProduction => environment == AppEnvironment.production;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isDevelopment => environment == AppEnvironment.development;

  /// Safe logging check: Debug logs are suppressed in production unless explicitly permitted.
  bool get shouldLogDebug => !isProduction || enableVerboseLogging;

  /// Maximum file upload size: 25 MB (26,214,400 bytes).
  int get maxUploadSizeBytes => 25 * 1024 * 1024;

  /// Maximum candidate evidence items sent to AI synthesis.
  int get geminiMaxEvidence => 15;

  /// Maximum context character budget sent to AI synthesis.
  int get geminiMaxContextChars => 8000;

  /// Bounded timeout for AI completion requests.
  Duration get geminiTimeout => const Duration(seconds: 15);

  /// Maximum transient retries with exponential backoff for AI completion.
  int get geminiMaxRetries => 2;

  /// Recommended App Check provider based on active environment.
  String get recommendedAppCheckProvider {
    if (isDevelopment || isStaging) {
      return 'DebugAppCheckProvider';
    }
    if (kIsWeb) {
      return 'ReCaptchaV3AppCheckProvider';
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'DeviceCheckProvider / AppAttestProvider'
        : 'PlayIntegrityAppCheckProvider';
  }

  /// Sanitizes sensitive patterns from log messages to prevent secret leaks.
  static String sanitizeForLog(String text) {
    if (text.isEmpty) return text;

    var sanitized = text;

    // Redact Google / Gemini API Keys (AIzaSy...)
    sanitized = sanitized.replaceAll(
      RegExp(r'\bAIza[0-9A-Za-z\-_]{15,}\b'),
      '[REDACTED_API_KEY]',
    );

    // Redact Bearer and Auth Tokens
    sanitized = sanitized.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-\._~\+\/]+=*', caseSensitive: false),
      'Bearer [REDACTED_TOKEN]',
    );

    // Redact HTTP Basic Authorization headers
    sanitized = sanitized.replaceAll(
      RegExp(r'Basic\s+[A-Za-z0-9\+\/]+=*', caseSensitive: false),
      'Basic [REDACTED_BASIC_AUTH]',
    );

    // Redact private Firebase UIDs in sensitive URLs (users/[uid]/...)
    sanitized = sanitized.replaceAll(
      RegExp(r'users\/[a-zA-Z0-9_-]{20,}\/'),
      'users/[REDACTED_UID]/',
    );

    // Redact URL Query Tokens and Credentials (e.g. ?token=..., &token=..., &key=..., &apiKey=...)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'([?&](?:token|key|api_key|apiKey|auth|access_token|secret|password)=)[^&\s]+', caseSensitive: false),
      (match) => '${match.group(1)}[REDACTED_TOKEN]',
    );

    // Redact Firebase Storage download URL tokens specifically
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(firebasestorage\.googleapis\.com\/[^\s]+[?&]token=)[a-zA-Z0-9_\-]+', caseSensitive: false),
      (match) => '${match.group(1)}[REDACTED_TOKEN]',
    );

    // Redact Bare JWTs (Header.Payload.Signature)
    sanitized = sanitized.replaceAll(
      RegExp(r'\beyJ[a-zA-Z0-9_\-]{10,}\.eyJ[a-zA-Z0-9_\-]{10,}\.[a-zA-Z0-9_\-]+={0,2}\b'),
      '[REDACTED_JWT]',
    );

    // Redact Generic API Keys (OpenAI, GitHub, AWS, Stripe)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(?:sk-[a-zA-Z0-9]{20,}|gh[pousr]_[a-zA-Z0-9]{36,}|AKIA[0-9A-Z]{16}|live_[0-9a-zA-Z]{24})\b'),
      '[REDACTED_API_KEY]',
    );

    // Redact HTTP Basic Auth in URIs
    sanitized = sanitized.replaceAll(
      RegExp(r'(https?:\/\/)[^:\/\s]+:[^@\/\s]+@'),
      r'$1[REDACTED_CREDENTIALS]@',
    );

    // Redact Credit Card Numbers (13-19 digits with spaces/dashes)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(?:\d{4}[-\s]?){3}\d{4}\b'),
      '[REDACTED_PAN]',
    );

    // Redact private email addresses
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+\b'),
      '[REDACTED_EMAIL]',
    );

    // Redact private phone numbers
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'),
      '[REDACTED_PHONE]',
    );

    return sanitized;
  }
}