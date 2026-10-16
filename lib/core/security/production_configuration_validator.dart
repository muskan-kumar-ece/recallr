import 'environment_config.dart';

/// Represents the evaluation result of the production configuration validator.
class ConfigurationValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> diagnostics;

  const ConfigurationValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.diagnostics = const {},
  });

  @override
  String toString() {
    return 'ConfigurationValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}

/// Exception thrown when configuration validation fails for production builds.
class RecallrConfigurationException implements Exception {
  final String message;
  final List<String> errors;

  const RecallrConfigurationException(this.message, [this.errors = const []]);

  @override
  String toString() => 'RecallrConfigurationException: $message (Errors: $errors)';
}

/// Validates runtime environment configuration to prevent insecure or misconfigured
/// deployments from booting into production.
class ProductionConfigurationValidator {
  const ProductionConfigurationValidator();

  /// Validates the provided configuration against environment rules.
  static ConfigurationValidationResult validate(EnvironmentConfig config) {
    final errors = <String>[];
    final warnings = <String>[];
    final diagnostics = <String, dynamic>{
      'environment': config.environment.name,
      'projectId': config.firebaseProjectId,
      'appCheckEnabled': config.enableAppCheck,
      'appCheckProvider': config.appCheckProviderType.name,
      'useEmulators': config.useEmulators,
      'verboseLogging': config.enableVerboseLogging,
      'allowMockFallback': config.allowMockFallback,
    };

    if (config.isProduction) {
      // Production Invariants (Zero Tolerance)
      if (config.useEmulators) {
        errors.add('Firebase Emulators are strictly forbidden in production.');
      }

      if (!config.enableAppCheck) {
        errors.add('Firebase App Check must be enabled in production.');
      }

      if (config.appCheckProviderType == AppCheckProviderType.debug) {
        errors.add('DebugAppCheckProvider is strictly forbidden in production.');
      }

      if (config.allowMockFallback) {
        errors.add('Mock fallback is forbidden in production builds.');
      }

      // Production Warnings / Best Practices
      if (config.enableVerboseLogging) {
        warnings.add('Verbose logging is enabled in production; consider disabling for privacy.');
      }

      if (config.firebaseProjectId == 'recallr-b0bcc' ||
          config.firebaseProjectId == 'recaller-cabf8') {
        warnings.add('Production build is referencing development Firebase Project ID (${config.firebaseProjectId}).');
      }

      if (config.geminiApiKey == null || config.geminiApiKey!.isEmpty) {
        warnings.add('GEMINI_API_KEY is not configured; AI features will operate in deterministic fallback mode.');
      }
    } else if (config.isStaging) {
      // Staging Invariants
      if (config.useEmulators) {
        warnings.add('Emulators are enabled in staging mode.');
      }

      if (config.appCheckProviderType == AppCheckProviderType.debug) {
        warnings.add('Staging is using Debug App Check provider.');
      }
    } else {
      // Development Invariants
      if (config.useEmulators) {
        diagnostics['emulatorHost'] = config.emulatorHost;
        diagnostics['authPort'] = config.authEmulatorPort;
        diagnostics['firestorePort'] = config.firestoreEmulatorPort;
        diagnostics['storagePort'] = config.storageEmulatorPort;
      }
    }

    final isValid = errors.isEmpty;
    return ConfigurationValidationResult(
      isValid: isValid,
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
      diagnostics: Map.unmodifiable(diagnostics),
    );
  }

  /// Validates configuration and throws if invalid in production.
  static void validateOrThrow(EnvironmentConfig config) {
    final result = validate(config);
    if (!result.isValid) {
      throw RecallrConfigurationException(
        'Production configuration validation failed with ${result.errors.length} error(s).',
        result.errors,
      );
    }
  }
}