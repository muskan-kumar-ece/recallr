import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'gemini_ai_configuration.dart';
import 'gemini_ai_provider.dart';

/// Official Google SDK implementation of GeminiAiProvider.
class GoogleSdkGeminiAiProvider implements GeminiAiProvider {
  final GeminiAiConfiguration configuration;
  final GenerativeModel? _injectedModel;

  GoogleSdkGeminiAiProvider({
    required this.configuration,
    GenerativeModel? injectedModel,
  }) : _injectedModel = injectedModel;

  @override
  Future<GeminiGenerationResult> generate({
    required String systemInstruction,
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    if (!configuration.isConfigured && _injectedModel == null) {
      throw const GeminiAuthenticationException('Gemini API key is not configured.');
    }

    final effectiveTemp = temperature ?? configuration.temperature;
    final effectiveMaxTokens = maxOutputTokens ?? configuration.maxOutputTokens;

    final model = _injectedModel ??
        GenerativeModel(
          model: configuration.model,
          apiKey: configuration.apiKey,
          generationConfig: GenerationConfig(
            temperature: effectiveTemp,
            maxOutputTokens: effectiveMaxTokens,
            responseMimeType: 'application/json',
          ),
          systemInstruction: Content.system(systemInstruction),
        );

    int attempts = 0;
    final maxAttempts = configuration.maxRetries + 1;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final content = [Content.text(prompt)];
        final response = await model
            .generateContent(content)
            .timeout(configuration.timeout);

        final text = response.text?.trim() ?? '';
        if (text.isEmpty) {
          throw const GeminiInvalidResponseException('Received empty response text from Gemini API.');
        }

        final finishReason = response.candidates.isNotEmpty
            ? response.candidates.first.finishReason?.name
            : null;

        return GeminiGenerationResult(
          text: text,
          finishReason: finishReason,
          promptTokens: response.usageMetadata?.promptTokenCount,
          candidateTokens: response.usageMetadata?.candidatesTokenCount,
        );
      } on TimeoutException catch (e, st) {
        if (attempts >= maxAttempts) {
          throw GeminiTimeoutException(
            'Gemini API request timed out after ${configuration.timeout.inSeconds}s (attempts: $attempts).',
            originalError: e,
            stackTrace: st,
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 200 * attempts));
      } on GeminiProviderException {
        rethrow;
      } catch (e, st) {
        final errStr = e.toString().toLowerCase();

        // 1. Authentication / Permission errors (Do not retry)
        if (errStr.contains('api_key_invalid') ||
            errStr.contains('unauthenticated') ||
            errStr.contains('permission_denied') ||
            errStr.contains('401') ||
            errStr.contains('403')) {
          throw GeminiAuthenticationException(
            'Gemini API authentication failed: $e',
            originalError: e,
            stackTrace: st,
          );
        }

        // 2. Rate Limiting (Do not retry immediately)
        if (errStr.contains('429') ||
            errStr.contains('resource_exhausted') ||
            errStr.contains('quota')) {
          throw GeminiRateLimitException(
            'Gemini API rate limit exceeded: $e',
            originalError: e,
            stackTrace: st,
          );
        }

        // 3. Transient Network / Unavailable
        if (attempts >= maxAttempts) {
          if (errStr.contains('socket') ||
              errStr.contains('network') ||
              errStr.contains('unavailable') ||
              errStr.contains('failed host lookup')) {
            throw GeminiUnavailableException(
              'Gemini service is currently unavailable: $e',
              originalError: e,
              stackTrace: st,
            );
          }
          throw GeminiProviderException(
            'Gemini API generation failed: $e',
            originalError: e,
            stackTrace: st,
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 200 * attempts));
      }
    }

    throw const GeminiProviderException('Exhausted all retries without receiving a response.');
  }

  @override
  void dispose() {
    // GenerativeModel does not require explicit connection disposal in SDK
  }
}