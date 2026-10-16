import 'package:flutter/foundation.dart';
import '../security/environment_config.dart';

/// Supported log severity levels for Recallr.
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Production-hardened logger that enforces token/credential redaction
/// and suppresses debug logs in production.
class SafeLogger {
  final String tag;
  final EnvironmentConfig config;
  final void Function(String message)? outputPrinter;

  SafeLogger(this.tag, {EnvironmentConfig? config, this.outputPrinter})
      : config = config ?? EnvironmentConfig.current();

  /// Logs debug-level message (suppressed in production unless verbose logging is enabled).
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Logs informational message.
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Logs warning message.
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Logs error message with optional stack trace.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  void _log(LogLevel level, String rawMessage, Object? error, StackTrace? stackTrace) {
    // In production, suppress debug logs; and suppress info/warning logs unless verbose logging is enabled
    if (config.isProduction && !config.enableVerboseLogging) {
      if (level == LogLevel.debug || level == LogLevel.info || level == LogLevel.warning) {
        return;
      }
    } else if (level == LogLevel.debug && !config.shouldLogDebug) {
      return;
    }

    final sanitizedMessage = EnvironmentConfig.sanitizeForLog(rawMessage);
    final sanitizedError = error != null ? EnvironmentConfig.sanitizeForLog(error.toString()) : null;

    final buffer = StringBuffer();
    buffer.write('[${level.name.toUpperCase()}][$tag] $sanitizedMessage');
    if (sanitizedError != null) {
      buffer.write(' | Error: $sanitizedError');
    }
    if (stackTrace != null && !config.isProduction) {
      buffer.write('\n$stackTrace');
    }

    final logOutput = buffer.toString();
    if (outputPrinter != null) {
      outputPrinter!(logOutput);
    } else {
      debugPrint(logOutput);
    }
  }
}