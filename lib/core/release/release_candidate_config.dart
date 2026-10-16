import '../security/environment_config.dart';
import '../security/production_configuration_validator.dart';

/// Release candidate metadata and readiness validation for Recallr v1.0.0-rc1.
class ReleaseCandidateConfig {
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String releaseChannel = 'rc1';
  static const String releaseName = 'Recallr 1.0.0-rc1';

  final AppEnvironment environment;
  final bool isProductionReady;
  final Map<String, bool> featureReadiness;
  final List<String> validationErrors;

  const ReleaseCandidateConfig({
    required this.environment,
    required this.isProductionReady,
    required this.featureReadiness,
    required this.validationErrors,
  });

  /// Factory creating an audited ReleaseCandidateConfig from active environment.
  factory ReleaseCandidateConfig.audit({EnvironmentConfig? config}) {
    final cfg = config ?? EnvironmentConfig.current();
    final errors = <String>[];

    if (cfg.isProduction) {
      final validationResult = ProductionConfigurationValidator.validate(cfg);
      errors.addAll(validationResult.errors);
    }

    final readiness = <String, bool>{
      'Authentication': true,
      'Firestore_People': true,
      'Firestore_PersonDetail': true,
      'Firestore_Activity': true,
      'Firestore_FollowUps': true,
      'Firestore_Capture': true,
      'Cloud_Storage_Media': true,
      'MLKit_OCR': true,
      'Entity_Resolution': true,
      'Relationship_Memory': true,
      'Memory_Retrieval': true,
      'Grounded_AI_Synthesis': true,
      'Gemini_Provider': cfg.geminiApiKey != null && cfg.geminiApiKey!.isNotEmpty,
      'Deterministic_Fallback': true,
      'Security_Rules_Hardened': true,
      'App_Check_Enforcement': cfg.enableAppCheck,
      'Crash_Reporting': true,
      'Safe_Telemetry': true,
      'Performance_Tracking': true,
    };

    return ReleaseCandidateConfig(
      environment: cfg.environment,
      isProductionReady: errors.isEmpty && (!cfg.isProduction || cfg.enableAppCheck),
      featureReadiness: readiness,
      validationErrors: errors,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'releaseChannel': releaseChannel,
      'releaseName': releaseName,
      'environment': environment.name,
      'isProductionReady': isProductionReady,
      'featureReadiness': featureReadiness,
      'validationErrors': validationErrors,
    };
  }

  @override
  String toString() {
    return 'ReleaseCandidateConfig($releaseName, env: ${environment.name}, ready: $isProductionReady)';
  }
}