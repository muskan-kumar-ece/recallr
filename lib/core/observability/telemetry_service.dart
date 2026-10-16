import 'dart:async';
import '../logging/safe_logger.dart';
import '../security/environment_config.dart';
import 'feature_health_metrics.dart';
import 'telemetry_event.dart';

/// Abstract contract for recording structured, privacy-safe operational telemetry.
abstract class TelemetryService {
  Future<void> initialize();
  void recordEvent(TelemetryEvent event);
  List<TelemetryEvent> getRecentEvents({int limit = 100});
  FeatureHealthMetrics get aggregateMetrics;
  Future<void> flush();
}

/// Production implementation of TelemetryService featuring rate limiting,
/// deduplication, aggregate counters, and token-safe logging.
class ProductionTelemetryService implements TelemetryService {
  final EnvironmentConfig config;
  final SafeLogger _logger;
  final FeatureHealthMetrics _metrics = FeatureHealthMetrics();
  final List<TelemetryEvent> _recentEvents = [];
  final Map<String, DateTime> _eventDeduplicationCache = {};

  static const int _maxRecentEvents = 200;
  static const Duration _deduplicationWindow = Duration(seconds: 5);

  ProductionTelemetryService({
    EnvironmentConfig? config,
    SafeLogger? logger,
  })  : config = config ?? EnvironmentConfig.current(),
        _logger = logger ?? SafeLogger('TelemetryService');

  @override
  FeatureHealthMetrics get aggregateMetrics => _metrics;

  @override
  Future<void> initialize() async {
    _logger.info('Initialized TelemetryService for environment: ${config.environment.name}');
  }

  @override
  void recordEvent(TelemetryEvent event) {
    // 1. Update Aggregate Metrics
    _updateMetrics(event);

    // 2. Deduplication check for high-frequency failure events
    if (event.severity == TelemetrySeverity.warning || event.severity == TelemetrySeverity.error) {
      final dedupeKey = '${event.name}_${event.safeErrorCategory ?? ""}';
      final lastEmitted = _eventDeduplicationCache[dedupeKey];
      final now = DateTime.now();

      if (lastEmitted != null && now.difference(lastEmitted) < _deduplicationWindow) {
        // Skip duplicate high-frequency telemetry spam
        return;
      }
      _eventDeduplicationCache[dedupeKey] = now;
    }

    // 3. Store in bounded recent events ring
    if (_recentEvents.length >= _maxRecentEvents) {
      _recentEvents.removeAt(0);
    }
    _recentEvents.add(event);

    // 4. Log event through SafeLogger
    if (event.severity.isErrorOrFatal) {
      _logger.error('Telemetry Event: ${event.name} (Op: ${event.operation}, Error: ${event.safeErrorCategory ?? "none"})');
    } else if (event.severity == TelemetrySeverity.warning) {
      _logger.warning('Telemetry Event: ${event.name} (Op: ${event.operation}, Error: ${event.safeErrorCategory ?? "none"})');
    } else {
      _logger.info('Telemetry Event: ${event.name} (Op: ${event.operation}, Duration: ${event.durationMs ?? 0}ms)');
    }
  }

  void _updateMetrics(TelemetryEvent event) {
    switch (event.feature) {
      case TelemetryFeature.people:
        if (event.operation.contains('read') || event.operation.contains('stream') || event.operation.contains('get')) {
          _metrics.peopleReads++;
        } else if (event.operation.contains('write') || event.operation.contains('add') || event.operation.contains('save')) {
          _metrics.peopleWrites++;
        }
        if (event.safeErrorCategory == 'permissionDenied') {
          _metrics.peoplePermissionDenied++;
        }
        break;

      case TelemetryFeature.capture:
        if (event.operation == 'createCapture') _metrics.capturesStarted++;
        if (event.operation == 'saveCapture' && event.isSuccess) _metrics.capturesSaved++;
        if (!event.isSuccess) _metrics.captureProcessingFailures++;
        break;

      case TelemetryFeature.storage:
        if (event.isSuccess) {
          _metrics.mediaUploadsSuccess++;
        } else {
          _metrics.mediaUploadsFailed++;
        }
        break;

      case TelemetryFeature.ocr:
        if (event.isSuccess) {
          _metrics.ocrSuccess++;
        } else {
          _metrics.ocrFailed++;
        }
        break;

      case TelemetryFeature.entityResolution:
        if (event.isSuccess) {
          if (event.safeAttributes['status'] == 'exactMatch' || event.safeAttributes['status'] == 'merged') {
            _metrics.entityMatched++;
          } else if (event.safeAttributes['status'] == 'newEntity') {
            _metrics.entityCreated++;
          } else {
            _metrics.entityAmbiguous++;
          }
        } else {
          _metrics.entityFailed++;
        }
        break;

      case TelemetryFeature.relationshipMemory:
        if (event.isSuccess) {
          _metrics.relationshipEnriched++;
        } else {
          _metrics.relationshipFailed++;
        }
        break;

      case TelemetryFeature.followUp:
        if (event.operation == 'addFollowUp' && event.isSuccess) _metrics.followUpsCreated++;
        if (event.operation == 'toggleComplete' && event.isSuccess) _metrics.followUpsCompleted++;
        if (!event.isSuccess) _metrics.followUpsFailed++;
        break;

      case TelemetryFeature.geminiAi:
        if (event.operation == 'answerQuestion') _metrics.aiQuestions++;
        if (event.isSuccess) {
          _metrics.geminiSuccess++;
          if (event.safeAttributes['answerState'] == 'grounded') {
            _metrics.aiGroundedAnswers++;
          } else {
            _metrics.aiEmptyAnswers++;
          }
        } else {
          if (event.safeErrorCategory == 'timeout') _metrics.geminiTimeout++;
          if (event.safeErrorCategory == 'rate_limited') _metrics.geminiRateLimited++;
          if (event.safeErrorCategory == 'malformed_response') _metrics.geminiMalformed++;
          _metrics.geminiProviderFailures++;
        }
        if (event.name == 'ai_fallback_used') {
          _metrics.geminiFallback++;
        }
        break;

      case TelemetryFeature.auth:
        if (event.name == 'auth_signed_in') _metrics.authSignIns++;
        if (event.name == 'auth_signed_out') _metrics.authSignOuts++;
        if (event.name == 'auth_failure') _metrics.authFailures++;
        break;

      default:
        break;
    }
  }

  @override
  List<TelemetryEvent> getRecentEvents({int limit = 100}) {
    if (_recentEvents.length <= limit) {
      return List.unmodifiable(_recentEvents);
    }
    return List.unmodifiable(_recentEvents.sublist(_recentEvents.length - limit));
  }

  @override
  Future<void> flush() async {
    // In production with cloud backend, this flushes queued telemetry batches
    _logger.debug('TelemetryService flushed.');
  }
}

/// In-memory mock telemetry service for unit and widget testing.
class MockTelemetryService implements TelemetryService {
  final List<TelemetryEvent> recordedEvents = [];
  final FeatureHealthMetrics _metrics = FeatureHealthMetrics();
  bool isInitialized = false;

  @override
  FeatureHealthMetrics get aggregateMetrics => _metrics;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  void recordEvent(TelemetryEvent event) {
    recordedEvents.add(event);
  }

  @override
  List<TelemetryEvent> getRecentEvents({int limit = 100}) {
    if (recordedEvents.length <= limit) {
      return List.unmodifiable(recordedEvents);
    }
    return List.unmodifiable(recordedEvents.sublist(recordedEvents.length - limit));
  }

  @override
  Future<void> flush() async {}

  void clear() {
    recordedEvents.clear();
    _metrics.reset();
  }
}