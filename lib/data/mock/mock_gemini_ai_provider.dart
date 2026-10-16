import 'dart:async';
import '../../services/ai/gemini/gemini_ai_provider.dart';

/// Mock implementation of GeminiAiProvider for deterministic testing and offline development.
class MockGeminiAiProvider implements GeminiAiProvider {
  int generateCalls = 0;
  GeminiGenerationResult? forcedResult;
  String? forcedResponseText;
  bool shouldFail = false;
  bool shouldTimeout = false;
  bool shouldReturnMalformedJson = false;
  bool shouldRateLimit = false;
  bool shouldFailAuth = false;
  bool shouldBeUnavailable = false;
  Duration simulatedLatency = Duration.zero;

  final List<String> recordedPrompts = [];
  final List<String> recordedSystemInstructions = [];

  MockGeminiAiProvider({
    this.forcedResult,
    this.forcedResponseText,
    this.shouldFail = false,
    this.shouldTimeout = false,
    this.shouldReturnMalformedJson = false,
    this.shouldRateLimit = false,
    this.shouldFailAuth = false,
    this.shouldBeUnavailable = false,
    this.simulatedLatency = Duration.zero,
  });

  @override
  Future<GeminiGenerationResult> generate({
    required String systemInstruction,
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    generateCalls++;
    recordedPrompts.add(prompt);
    recordedSystemInstructions.add(systemInstruction);

    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    if (shouldTimeout) {
      throw const GeminiTimeoutException('Simulated Gemini API timeout.');
    }

    if (shouldFailAuth) {
      throw const GeminiAuthenticationException('Simulated Gemini API authentication failure.');
    }

    if (shouldRateLimit) {
      throw const GeminiRateLimitException('Simulated Gemini API rate limit (HTTP 429).');
    }

    if (shouldBeUnavailable) {
      throw const GeminiUnavailableException('Simulated Gemini service unavailable.');
    }

    if (shouldFail) {
      throw const GeminiProviderException('Simulated Gemini provider error.');
    }

    if (shouldReturnMalformedJson) {
      return const GeminiGenerationResult(
        text: 'This is not valid JSON at all: { answer = incomplete ...',
        finishReason: 'STOP',
      );
    }

    if (forcedResult != null) {
      return forcedResult!;
    }

    if (forcedResponseText != null) {
      return GeminiGenerationResult(
        text: forcedResponseText!,
        finishReason: 'STOP',
      );
    }

    // Default mock valid structured JSON response
    const defaultJson = '''
{
  "answer": "Mock Gemini grounded answer based on verified personal memory.",
  "confidence": 0.90,
  "evidenceIds": [],
  "mentionedPeople": [],
  "suggestedActions": []
}
''';

    return const GeminiGenerationResult(
      text: defaultJson,
      finishReason: 'STOP',
      promptTokens: 120,
      candidateTokens: 65,
    );
  }

  @override
  void dispose() {
    recordedPrompts.clear();
    recordedSystemInstructions.clear();
  }
}