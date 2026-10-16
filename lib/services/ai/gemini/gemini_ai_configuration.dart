/// Configuration settings for production Gemini AI Provider.
class GeminiAiConfiguration {
  /// The Gemini API Key. Can be injected via runtime config or `String.fromEnvironment`.
  final String apiKey;

  /// The Gemini model name to use (e.g. 'gemini-1.5-flash', 'gemini-1.5-pro').
  final String model;

  /// Generation temperature. Lower value (e.g. 0.2) is preferred for factual personal memory Q&A.
  final double temperature;

  /// Maximum output tokens to generate in response.
  final int maxOutputTokens;

  /// Timeout duration for Gemini API network calls.
  final Duration timeout;

  /// Maximum number of retries for transient failures.
  final int maxRetries;

  const GeminiAiConfiguration({
    this.apiKey = '',
    this.model = 'gemini-1.5-flash',
    this.temperature = 0.2,
    this.maxOutputTokens = 1024,
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 2,
  });

  /// Creates a configuration pulling the API key from `String.fromEnvironment('GEMINI_API_KEY')`.
  factory GeminiAiConfiguration.fromEnvironment({
    String? apiKey,
    String? model,
    double? temperature,
    int? maxOutputTokens,
    Duration? timeout,
    int? maxRetries,
  }) {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    return GeminiAiConfiguration(
      apiKey: apiKey ?? envKey,
      model: model ?? 'gemini-1.5-flash',
      temperature: temperature ?? 0.2,
      maxOutputTokens: maxOutputTokens ?? 1024,
      timeout: timeout ?? const Duration(seconds: 15),
      maxRetries: maxRetries ?? 2,
    );
  }

  /// Returns true if a valid, non-empty API key is provided.
  bool get isConfigured => apiKey.trim().isNotEmpty;

  /// Creates a copy with the given fields replaced.
  GeminiAiConfiguration copyWith({
    String? apiKey,
    String? model,
    double? temperature,
    int? maxOutputTokens,
    Duration? timeout,
    int? maxRetries,
  }) {
    return GeminiAiConfiguration(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'temperature': temperature,
      'maxOutputTokens': maxOutputTokens,
      'timeoutMs': timeout.inMilliseconds,
      'maxRetries': maxRetries,
      'isConfigured': isConfigured,
    };
  }
}