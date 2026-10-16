/// Result wrapper for raw Gemini generation.
class GeminiGenerationResult {
  final String text;
  final String? finishReason;
  final int? promptTokens;
  final int? candidateTokens;

  const GeminiGenerationResult({
    required this.text,
    this.finishReason,
    this.promptTokens,
    this.candidateTokens,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'finishReason': finishReason,
      'promptTokens': promptTokens,
      'candidateTokens': candidateTokens,
    };
  }
}

/// Abstract provider interface for calling Gemini AI.
abstract class GeminiAiProvider {
  /// Generate a completion given a system instruction and user prompt.
  Future<GeminiGenerationResult> generate({
    required String systemInstruction,
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
  });

  /// Dispose any underlying client or network connections.
  void dispose();
}

/// Base exception for all Gemini provider operations.
class GeminiProviderException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const GeminiProviderException(this.message, {this.originalError, this.stackTrace});

  @override
  String toString() => 'GeminiProviderException: $message';
}

/// Thrown when a Gemini API request times out.
class GeminiTimeoutException extends GeminiProviderException {
  const GeminiTimeoutException(super.message, {super.originalError, super.stackTrace});

  @override
  String toString() => 'GeminiTimeoutException: $message';
}

/// Thrown when the Gemini API returns an HTTP 429 Rate Limit error.
class GeminiRateLimitException extends GeminiProviderException {
  final Duration? retryAfter;

  const GeminiRateLimitException(super.message, {this.retryAfter, super.originalError, super.stackTrace});

  @override
  String toString() => 'GeminiRateLimitException: $message';
}

/// Thrown when the API key is invalid or unauthenticated.
class GeminiAuthenticationException extends GeminiProviderException {
  const GeminiAuthenticationException(super.message, {super.originalError, super.stackTrace});

  @override
  String toString() => 'GeminiAuthenticationException: $message';
}

/// Thrown when Gemini returns an empty or unparseable response payload.
class GeminiInvalidResponseException extends GeminiProviderException {
  final String? rawResponse;

  const GeminiInvalidResponseException(super.message, {this.rawResponse, super.originalError, super.stackTrace});

  @override
  String toString() => 'GeminiInvalidResponseException: $message';
}

/// Thrown when the network is unavailable or the Gemini service cannot be reached.
class GeminiUnavailableException extends GeminiProviderException {
  const GeminiUnavailableException(super.message, {super.originalError, super.stackTrace});

  @override
  String toString() => 'GeminiUnavailableException: $message';
}