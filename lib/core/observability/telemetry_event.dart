import '../security/environment_config.dart';

/// Severity classifications for operational telemetry events.
enum TelemetrySeverity {
  debug,
  info,
  warning,
  error,
  fatal;

  bool get isErrorOrFatal => this == TelemetrySeverity.error || this == TelemetrySeverity.fatal;
}

/// Feature domains within Recallr.
enum TelemetryFeature {
  auth,
  people,
  activity,
  followUp,
  capture,
  ocr,
  entityResolution,
  relationshipMemory,
  retrieval,
  geminiAi,
  storage,
  bootstrap,
  system;
}

/// Immutable, privacy-sanitized telemetry event model.
///
/// Under NO CIRCUMSTANCES should private memory text, OCR transcriptions,
/// raw user queries, Firebase UIDs, auth tokens, or API keys be stored in this model.
class TelemetryEvent {
  final String name;
  final DateTime timestamp;
  final AppEnvironment environment;
  final TelemetrySeverity severity;
  final TelemetryFeature feature;
  final String operation;
  final int? durationMs;
  final bool isSuccess;
  final String? safeErrorCategory;
  final String? provider;
  final int retryCount;
  final Map<String, String> safeAttributes;

  TelemetryEvent({
    required this.name,
    DateTime? timestamp,
    this.environment = AppEnvironment.development,
    this.severity = TelemetrySeverity.info,
    required this.feature,
    required this.operation,
    this.durationMs,
    this.isSuccess = true,
    this.safeErrorCategory,
    this.provider,
    this.retryCount = 0,
    Map<String, String>? safeAttributes,
  })  : timestamp = timestamp ?? DateTime.now(),
        safeAttributes = _sanitizeAttributes(safeAttributes);

  static Map<String, String> _sanitizeAttributes(Map<String, String>? attributes) {
    if (attributes == null || attributes.isEmpty) return const {};

    final sanitized = <String, String>{};
    for (final entry in attributes.entries) {
      // Validate key
      final cleanKey = entry.key.replaceAll(RegExp(r'[^a-zA-Z0-9_\.]'), '').trim();
      if (cleanKey.isEmpty) continue;

      // Sanitize value through EnvironmentConfig.sanitizeForLog and limit length
      var cleanValue = EnvironmentConfig.sanitizeForLog(entry.value);
      if (cleanValue.length > 200) {
        cleanValue = cleanValue.substring(0, 200);
      }
      sanitized[cleanKey] = cleanValue;
    }
    return Map.unmodifiable(sanitized);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'environment': environment.name,
      'severity': severity.name,
      'feature': feature.name,
      'operation': operation,
      if (durationMs != null) 'durationMs': durationMs,
      'isSuccess': isSuccess,
      if (safeErrorCategory != null) 'safeErrorCategory': safeErrorCategory,
      if (provider != null) 'provider': provider,
      'retryCount': retryCount,
      if (safeAttributes.isNotEmpty) 'attributes': safeAttributes,
    };
  }

  @override
  String toString() {
    return 'TelemetryEvent($name, feature: ${feature.name}, op: $operation, success: $isSuccess, sev: ${severity.name})';
  }
}