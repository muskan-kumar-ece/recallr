import 'dart:async';
import '../logging/safe_logger.dart';
import '../security/environment_config.dart';

/// Abstract contract for production crash reporting and unhandled exception capture.
abstract class CrashReportingService {
  Future<void> initialize();
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  });
  Future<void> recordFatalError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  });
  Future<void> setUserContext({
    String? environment,
  });
}

/// Production implementation of CrashReportingService wrapping platform handlers / Crashlytics.
class ProductionCrashReportingService implements CrashReportingService {
  final EnvironmentConfig config;
  final SafeLogger _logger;
  bool _isInitialized = false;

  ProductionCrashReportingService({
    EnvironmentConfig? config,
    SafeLogger? logger,
  })  : config = config ?? EnvironmentConfig.current(),
        _logger = logger ?? SafeLogger('CrashReporting');

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _logger.info('Initializing crash reporting for environment: ${config.environment.name}');
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    final sanitizedReason = reason != null ? EnvironmentConfig.sanitizeForLog(reason) : null;
    final sanitizedError = EnvironmentConfig.sanitizeForLog(error.toString());

    if (fatal) {
      _logger.error('FATAL CRASH RECORDED: $sanitizedError${sanitizedReason != null ? " (Reason: $sanitizedReason)" : ""}', error, stackTrace);
    } else {
      _logger.warning('NON-FATAL ERROR RECORDED: $sanitizedError${sanitizedReason != null ? " (Reason: $sanitizedReason)" : ""}', error, stackTrace);
    }
  }

  @override
  Future<void> recordFatalError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    await recordError(error, stackTrace, reason: reason, fatal: true);
  }

  @override
  Future<void> setUserContext({
    String? environment,
  }) async {
    // We explicitly set environment context, but NEVER private user IDs or emails
    _logger.info('Crash reporting environment context set: ${environment ?? config.environment.name}');
  }
}

/// Recorded error snapshot in MockCrashReportingService for testing.
class RecordedError {
  final Object error;
  final StackTrace stackTrace;
  final String? reason;
  final bool fatal;
  final DateTime timestamp;

  RecordedError({
    required this.error,
    required this.stackTrace,
    this.reason,
    required this.fatal,
  }) : timestamp = DateTime.now();
}

/// In-memory mock crash reporting service for unit and widget testing.
class MockCrashReportingService implements CrashReportingService {
  final List<RecordedError> recordedErrors = [];
  bool isInitialized = false;
  String? environmentContext;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    recordedErrors.add(RecordedError(
      error: error,
      stackTrace: stackTrace,
      reason: reason,
      fatal: fatal,
    ));
  }

  @override
  Future<void> recordFatalError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    await recordError(error, stackTrace, reason: reason, fatal: true);
  }

  @override
  Future<void> setUserContext({String? environment}) async {
    environmentContext = environment;
  }

  void clear() {
    recordedErrors.clear();
  }
}