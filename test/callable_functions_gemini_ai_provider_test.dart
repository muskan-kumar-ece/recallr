import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/services/ai/gemini/callable_functions_gemini_ai_provider.dart';
import 'package:recaller/services/ai/gemini/gemini_ai_configuration.dart';
import 'package:recaller/services/ai/gemini/gemini_ai_provider.dart';
import 'package:recaller/services/ai/gemini/google_sdk_gemini_ai_provider.dart';

void main() {
  group('CallableFunctionsGeminiAiProvider Tests (Trusted Backend Migration)', () {
    test('1. Successful generation calls backend and parses structured response', () async {
      Map<String, dynamic>? receivedPayload;

      final provider = CallableFunctionsGeminiAiProvider(
        customCaller: (payload) async {
          receivedPayload = payload;
          return {
            'text': '{\n  "answer": "Sarah Chen is VP of AI.",\n  "confidence": 0.95\n}',
            'finishReason': 'STOP',
            'promptTokens': 450,
            'candidateTokens': 85,
          };
        },
      );

      final result = await provider.generate(
        systemInstruction: 'You are Recallr AI.',
        prompt: 'Who is Sarah?',
        temperature: 0.1,
        maxOutputTokens: 512,
      );

      expect(receivedPayload, isNotNull);
      expect(receivedPayload!['systemInstruction'], equals('You are Recallr AI.'));
      expect(receivedPayload!['prompt'], equals('Who is Sarah?'));
      expect(receivedPayload!['temperature'], equals(0.1));
      expect(receivedPayload!['maxOutputTokens'], equals(512));

      expect(result.text, contains('Sarah Chen is VP of AI.'));
      expect(result.finishReason, equals('STOP'));
      expect(result.promptTokens, equals(450));
      expect(result.candidateTokens, equals(85));
    });

    test('2. Empty response text throws GeminiInvalidResponseException', () async {
      final provider = CallableFunctionsGeminiAiProvider(
        configuration: const GeminiAiConfiguration(maxRetries: 0),
        customCaller: (payload) async {
          return {'text': '   '};
        },
      );

      expect(
        () => provider.generate(systemInstruction: 'sys', prompt: 'prompt'),
        throwsA(isA<GeminiInvalidResponseException>()),
      );
    });

    test('3. FirebaseFunctionsException unauthenticated throws GeminiAuthenticationException', () async {
      final provider = CallableFunctionsGeminiAiProvider(
        configuration: const GeminiAiConfiguration(maxRetries: 0),
        customCaller: (payload) async {
          throw FirebaseFunctionsException(
            message: 'Session expired',
            code: 'unauthenticated',
          );
        },
      );

      expect(
        () => provider.generate(systemInstruction: 'sys', prompt: 'prompt'),
        throwsA(isA<GeminiAuthenticationException>()),
      );
    });

    test('4. FirebaseFunctionsException resource-exhausted throws GeminiRateLimitException', () async {
      final provider = CallableFunctionsGeminiAiProvider(
        configuration: const GeminiAiConfiguration(maxRetries: 0),
        customCaller: (payload) async {
          throw FirebaseFunctionsException(
            message: 'Daily quota exceeded',
            code: 'resource-exhausted',
          );
        },
      );

      expect(
        () => provider.generate(systemInstruction: 'sys', prompt: 'prompt'),
        throwsA(isA<GeminiRateLimitException>()),
      );
    });

    test('5. Timeout throws GeminiTimeoutException after retries', () async {
      final provider = CallableFunctionsGeminiAiProvider(
        configuration: const GeminiAiConfiguration(
          timeout: Duration(milliseconds: 10),
          maxRetries: 1,
        ),
        customCaller: (payload) async {
          throw TimeoutException('Request timed out');
        },
      );

      expect(
        () => provider.generate(systemInstruction: 'sys', prompt: 'prompt'),
        throwsA(isA<GeminiTimeoutException>()),
      );
    });

    test('6. RecallrDependencies.production wires CallableFunctionsGeminiAiProvider when unconfigured', () {
      // When no GEMINI_API_KEY is defined in environment, configuration is unconfigured
      const unconfigured = GeminiAiConfiguration(apiKey: '');
      expect(unconfigured.isConfigured, isFalse);

      final deps = RecallrDependencies.production(
        geminiAiConfiguration: unconfigured,
      );

      expect(deps.geminiAiProvider, isA<CallableFunctionsGeminiAiProvider>());
    });

    test('7. RecallrDependencies.production wires GoogleSdkGeminiAiProvider when explicitly configured', () {
      const configured = GeminiAiConfiguration(apiKey: 'local-test-key');
      expect(configured.isConfigured, isTrue);

      final deps = RecallrDependencies.production(
        geminiAiConfiguration: configured,
      );

      expect(deps.geminiAiProvider, isA<GoogleSdkGeminiAiProvider>());
    });
  });
}
