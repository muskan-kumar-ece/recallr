import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'gemini_ai_configuration.dart';
import 'gemini_ai_provider.dart';

/// Production Gemini AI provider that invokes the trusted Firebase Cloud Function `generateGroundedAnswer`.
///
/// Keeps Gemini API keys completely off client mobile devices. The client only sends
/// sanitized prompt payloads over authenticated HTTPS Callable protocol (with automatic
/// Firebase Auth JWT and App Check attestation token embedding).
class CallableFunctionsGeminiAiProvider implements GeminiAiProvider {
  final FirebaseFunctions? _functions;
  final String functionName;
  final GeminiAiConfiguration configuration;
  final Future<Map<dynamic, dynamic>> Function(Map<String, dynamic> payload)? _customCaller;

  CallableFunctionsGeminiAiProvider({
    FirebaseFunctions? functions,
    this.functionName = 'generateGroundedAnswer',
    this.configuration = const GeminiAiConfiguration(),
    Future<Map<dynamic, dynamic>> Function(Map<String, dynamic> payload)? customCaller,
  })  : _functions = functions,
        _customCaller = customCaller;

  @override
  Future<GeminiGenerationResult> generate({
    required String systemInstruction,
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    final effectiveTemp = temperature ?? configuration.temperature;
    final effectiveMaxTokens = maxOutputTokens ?? configuration.maxOutputTokens;

    int attempts = 0;
    final maxAttempts = configuration.maxRetries + 1;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final Map<dynamic, dynamic> data;
        if (_customCaller != null) {
          data = await _customCaller({
            'prompt': prompt,
            'systemInstruction': systemInstruction,
            'model': configuration.model,
            'temperature': effectiveTemp,
            'maxOutputTokens': effectiveMaxTokens,
          });
        } else {
          final functions = _functions ?? FirebaseFunctions.instance;
          final callable = functions.httpsCallable(
            functionName,
            options: HttpsCallableOptions(
              timeout: configuration.timeout,
            ),
          );
          final result = await callable.call<Map<dynamic, dynamic>>({
            'prompt': prompt,
            'systemInstruction': systemInstruction,
            'model': configuration.model,
            'temperature': effectiveTemp,
            'maxOutputTokens': effectiveMaxTokens,
          });
          data = result.data;
        }

        final text = (data['text'] as String?)?.trim() ?? '';

        if (text.isEmpty) {
          throw const GeminiInvalidResponseException(
            'Received empty response text from trusted backend function.',
          );
        }

        return GeminiGenerationResult(
          text: text,
          finishReason: data['finishReason'] as String?,
          promptTokens: data['promptTokens'] as int?,
          candidateTokens: data['candidateTokens'] as int?,
        );
      } on FirebaseFunctionsException catch (e, st) {
        // Map Firebase Cloud Functions error codes into standard Recallr GeminiProviderException hierarchy
        switch (e.code) {
          case 'unauthenticated':
            throw GeminiAuthenticationException(
              'User session unauthenticated: ${e.message}',
              originalError: e,
              stackTrace: st,
            );
          case 'resource-exhausted':
            throw GeminiRateLimitException(
              'Rate limit exceeded on backend: ${e.message}',
              originalError: e,
              stackTrace: st,
            );
          case 'deadline-exceeded':
            if (attempts >= maxAttempts) {
              throw GeminiTimeoutException(
                'Cloud function timed out: ${e.message}',
                originalError: e,
                stackTrace: st,
              );
            }
            break;
          case 'unavailable':
            if (attempts >= maxAttempts) {
              throw GeminiUnavailableException(
                'Backend AI service unavailable: ${e.message}',
                originalError: e,
                stackTrace: st,
              );
            }
            break;
          case 'invalid-argument':
            throw GeminiInvalidResponseException(
              'Invalid argument sent to backend: ${e.message}',
              originalError: e,
              stackTrace: st,
            );
          default:
            if (attempts >= maxAttempts) {
              throw GeminiProviderException(
                'Backend AI function failed [${e.code}]: ${e.message}',
                originalError: e,
                stackTrace: st,
              );
            }
        }
        await Future<void>.delayed(Duration(milliseconds: 200 * attempts));
      } on TimeoutException catch (e, st) {
        if (attempts >= maxAttempts) {
          throw GeminiTimeoutException(
            'Client call to backend function timed out after ${configuration.timeout.inSeconds}s.',
            originalError: e,
            stackTrace: st,
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 200 * attempts));
      } catch (e, st) {
        if (e is GeminiProviderException) {
          rethrow;
        }

        if (attempts >= maxAttempts) {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('network') ||
              errStr.contains('socket') ||
              errStr.contains('unavailable')) {
            throw GeminiUnavailableException(
              'Network error connecting to backend AI function: $e',
              originalError: e,
              stackTrace: st,
            );
          }
          throw GeminiProviderException(
            'Unexpected error calling backend AI function: $e',
            originalError: e,
            stackTrace: st,
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 200 * attempts));
      }
    }

    throw const GeminiProviderException('Exhausted all retries calling trusted AI backend.');
  }

  @override
  void dispose() {
    // Stateless callable does not require stream disposal
  }
}
