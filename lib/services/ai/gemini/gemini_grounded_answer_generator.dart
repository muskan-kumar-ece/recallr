import '../../../features/ask/models/ai_answer_models.dart';
import '../../../features/ask/models/memory_retrieval_models.dart';
import '../ai_answer_generator.dart';
import '../deterministic_ai_answer_generator.dart';
import 'gemini_ai_configuration.dart';
import 'gemini_ai_provider.dart';
import 'gemini_prompt_builder.dart';
import 'gemini_response_parser.dart';
import 'grounded_answer_validator.dart';

/// Production Gemini-backed Grounded Answer Generator with guaranteed deterministic fallback.
class GeminiGroundedAnswerGenerator implements AiAnswerGenerator {
  final GeminiAiConfiguration configuration;
  final GeminiAiProvider provider;
  final GeminiPromptBuilder promptBuilder;
  final GeminiResponseParser responseParser;
  final GroundedAnswerValidator validator;
  final DeterministicAiAnswerGenerator fallbackGenerator;

  const GeminiGroundedAnswerGenerator({
    required this.configuration,
    required this.provider,
    this.promptBuilder = const GeminiPromptBuilder(),
    this.responseParser = const GeminiResponseParser(),
    this.validator = const GroundedAnswerValidator(),
    this.fallbackGenerator = const DeterministicAiAnswerGenerator(),
  });

  @override
  Future<AiAnswer> generateAnswer({
    required AiAnswerRequest request,
    required MemoryContext context,
  }) async {
    // 1. Fast path: Empty context -> Zero hallucination uncertainty response without making API calls
    if (context.isEmpty) {
      return AiAnswer(
        answer: "I don't have enough information in your Recallr memory to answer that confidently.",
        status: AiAnswerStatus.empty,
        query: request.query,
        intent: context.query.intent,
        confidence: 0.0,
        evidence: const [],
        mentionedPeople: const [],
        mentionedCompanies: const [],
        suggestedActions: const ['Capture a visiting card or voice note to add new memories'],
        generatedAt: DateTime.now(),
      );
    }

    try {
      // 2. Build bounded grounded prompt
      final prompt = promptBuilder.build(
        request: request,
        context: context,
      );

      // 4. Generate completion via Gemini provider
      final result = await provider.generate(
        systemInstruction: prompt.systemInstruction,
        prompt: prompt.userPrompt,
        temperature: configuration.temperature,
        maxOutputTokens: configuration.maxOutputTokens,
      );

      // 5. Parse structured output
      final parsed = responseParser.parse(result.text);
      if (!parsed.isSuccess) {
        // Fall back deterministically on malformed output
        return await fallbackGenerator.generateAnswer(request: request, context: context);
      }

      // 6. Validate output against Recallr evidence to prevent hallucinations
      final validated = validator.validate(
        parsed: parsed,
        context: context,
        request: request,
      );

      return validated;
    } catch (_) {
      // 7. Intelligent Fallback: On any provider failure, timeout, 429, or network error,
      // fallback to deterministic grounded answer generation smoothly without crashing
      return await fallbackGenerator.generateAnswer(request: request, context: context);
    }
  }

  @override
  void dispose() {
    provider.dispose();
    fallbackGenerator.dispose();
  }
}