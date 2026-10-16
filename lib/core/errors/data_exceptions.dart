/// Standardized classification for data access errors in Recallr.
enum DataErrorType {
  /// User is not authenticated or session has expired.
  unauthenticated,

  /// User does not have permission to access the target document or collection.
  permissionDenied,

  /// Target document or entity was not found.
  notFound,

  /// Network is unavailable or operation timed out.
  networkUnavailable,

  /// Data payload is malformed, missing required fields, or fails schema validation.
  invalidData,

  /// An unexpected or unclassified error occurred.
  unknown;

  String get defaultMessage {
    switch (this) {
      case DataErrorType.unauthenticated:
        return 'You must be signed in to perform this operation.';
      case DataErrorType.permissionDenied:
        return 'You do not have permission to access this data.';
      case DataErrorType.notFound:
        return 'The requested record could not be found.';
      case DataErrorType.networkUnavailable:
        return 'Network is unavailable. Changes will sync when reconnected.';
      case DataErrorType.invalidData:
        return 'The data is invalid or malformed.';
      case DataErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

/// Standard exception thrown by Recallr data repositories and services.
class RecallrDataException implements Exception {
  final DataErrorType type;
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const RecallrDataException({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  factory RecallrDataException.unauthenticated([String? customMessage]) {
    return RecallrDataException(
      type: DataErrorType.unauthenticated,
      message: customMessage ?? DataErrorType.unauthenticated.defaultMessage,
    );
  }

  factory RecallrDataException.permissionDenied([String? customMessage, Object? originalError]) {
    return RecallrDataException(
      type: DataErrorType.permissionDenied,
      message: customMessage ?? DataErrorType.permissionDenied.defaultMessage,
      originalError: originalError,
    );
  }

  factory RecallrDataException.notFound(String entityName, [String? id]) {
    final idPart = id != null ? ' ($id)' : '';
    return RecallrDataException(
      type: DataErrorType.notFound,
      message: '$entityName$idPart not found.',
    );
  }

  factory RecallrDataException.invalidData(String details) {
    return RecallrDataException(
      type: DataErrorType.invalidData,
      message: 'Invalid data: $details',
    );
  }

  factory RecallrDataException.networkUnavailable([Object? originalError]) {
    return RecallrDataException(
      type: DataErrorType.networkUnavailable,
      message: DataErrorType.networkUnavailable.defaultMessage,
      originalError: originalError,
    );
  }

  factory RecallrDataException.fromException(Object error, [StackTrace? stackTrace]) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('permission-denied') || errorString.contains('permission denied')) {
      return RecallrDataException(
        type: DataErrorType.permissionDenied,
        message: DataErrorType.permissionDenied.defaultMessage,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (errorString.contains('unauthenticated') || errorString.contains('not authenticated')) {
      return RecallrDataException(
        type: DataErrorType.unauthenticated,
        message: DataErrorType.unauthenticated.defaultMessage,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (errorString.contains('not-found') || errorString.contains('not found')) {
      return RecallrDataException(
        type: DataErrorType.notFound,
        message: DataErrorType.notFound.defaultMessage,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (errorString.contains('unavailable') ||
        errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('offline')) {
      return RecallrDataException(
        type: DataErrorType.networkUnavailable,
        message: DataErrorType.networkUnavailable.defaultMessage,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    return RecallrDataException(
      type: DataErrorType.unknown,
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => 'RecallrDataException($type): $message';
}