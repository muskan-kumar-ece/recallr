import '../security/environment_config.dart';
import 'health_status.dart';
import 'telemetry_service.dart';

/// Safe, non-sensitive diagnostic snapshot suitable for operational monitoring.
class ProductionDiagnostics {
  final String appVersion;
  final String buildNumber;
  final AppEnvironment environment;
  final bool firebaseInitialized;
  final bool appCheckActive;
  final bool geminiConfigured;
  final bool telemetryActive;
  final bool crashReportingActive;
  final SystemHealthReport healthReport;

  const ProductionDiagnostics({
    required this.appVersion,
    required this.buildNumber,
    required this.environment,
    required this.firebaseInitialized,
    required this.appCheckActive,
    required this.geminiConfigured,
    required this.telemetryActive,
    required this.crashReportingActive,
    required this.healthReport,
  });

  /// Factory creating diagnostic snapshot from current environment and telemetry services.
  factory ProductionDiagnostics.capture({
    EnvironmentConfig? config,
    bool firebaseInitialized = true,
    bool appCheckActive = true,
    bool crashReportingActive = true,
    TelemetryService? telemetryService,
    List<ComponentHealth>? customComponents,
  }) {
    final cfg = config ?? EnvironmentConfig.current();
    final hasGeminiKey = cfg.geminiApiKey != null && cfg.geminiApiKey!.isNotEmpty;

    final components = customComponents ??
        [
          ComponentHealth(
            name: 'Firebase Core',
            state: firebaseInitialized ? HealthState.healthy : HealthState.unavailable,
          ),
          ComponentHealth(
            name: 'App Check',
            state: appCheckActive ? HealthState.healthy : HealthState.degraded,
          ),
          ComponentHealth(
            name: 'Gemini AI Provider',
            state: hasGeminiKey ? HealthState.healthy : HealthState.degraded,
            message: hasGeminiKey ? 'Configured' : 'Operating in deterministic fallback',
          ),
        ];

    final hasUnavailable = components.any((c) => c.state == HealthState.unavailable);
    final hasDegraded = components.any((c) => c.state == HealthState.degraded);

    final overallState = hasUnavailable
        ? HealthState.unavailable
        : (hasDegraded ? HealthState.degraded : HealthState.healthy);

    return ProductionDiagnostics(
      appVersion: '1.0.0',
      buildNumber: '1',
      environment: cfg.environment,
      firebaseInitialized: firebaseInitialized,
      appCheckActive: appCheckActive,
      geminiConfigured: hasGeminiKey,
      telemetryActive: telemetryService != null,
      crashReportingActive: crashReportingActive,
      healthReport: SystemHealthReport(
        overallState: overallState,
        components: components,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'environment': environment.name,
      'firebaseInitialized': firebaseInitialized,
      'appCheckActive': appCheckActive,
      'geminiConfigured': geminiConfigured,
      'telemetryActive': telemetryActive,
      'crashReportingActive': crashReportingActive,
      'health': healthReport.toMap(),
    };
  }
}