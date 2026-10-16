import 'dart:async';
import 'telemetry_event.dart';
import 'telemetry_service.dart';

/// Tracks latency and operational timing across Recallr subsystems.
class PerformanceTracker {
  final TelemetryService _telemetryService;

  PerformanceTracker(this._telemetryService);

  /// Executes [action], records its execution duration, and emits a TelemetryEvent.
  Future<T> track<T>(
    String operation,
    Future<T> Function() action, {
    TelemetryFeature feature = TelemetryFeature.system,
    String? provider,
    Map<String, String>? safeAttributes,
  }) async {
    final stopwatch = Stopwatch()..start();
    bool isSuccess = true;
    String? errorCategory;

    try {
      final result = await action();
      return result;
    } catch (e) {
      isSuccess = false;
      errorCategory = e.runtimeType.toString();
      rethrow;
    } finally {
      stopwatch.stop();
      _telemetryService.recordEvent(
        TelemetryEvent(
          name: '${operation}_timed',
          feature: feature,
          operation: operation,
          durationMs: stopwatch.elapsedMilliseconds,
          isSuccess: isSuccess,
          safeErrorCategory: errorCategory,
          provider: provider,
          safeAttributes: safeAttributes,
        ),
      );
    }
  }
}