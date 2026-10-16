import 'dart:async';
import '../../core/errors/data_exceptions.dart';
import '../../features/ask/models/ai_answer_models.dart';
import '../../features/ask/models/memory_retrieval_models.dart';
import '../../services/ai/ai_answer_generator.dart';
import '../../services/ai/answer_grounding_service.dart';

/// Deterministic mock AI answer generator for unit tests and offline widget previews.
class MockAiAnswerGenerator implements AiAnswerGenerator {
  bool shouldFail;
  String errorMessage;
  Duration simulatedDelay;
  AiAnswer? forcedAnswer;
  double? forcedConfidence;
  int generateCalls = 0;
  final AnswerGroundingService groundingService;

  MockAiAnswerGenerator({
    this.shouldFail = false,
    this.errorMessage = 'Simulated AI generation failure',
    this.simulatedDelay = Duration.zero,
    this.forcedAnswer,
    this.forcedConfidence,
    this.groundingService = const AnswerGroundingService(),
  });

  @override
  Future<AiAnswer> generateAnswer({
    required AiAnswerRequest request,
    required MemoryContext context,
  }) async {
    generateCalls++;

    if (shouldFail) {
      throw RecallrDataException.networkUnavailable(errorMessage);
    }

    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (forcedAnswer != null) {
      return forcedAnswer!;
    }

    if (context.isEmpty) {
      return AiAnswer(
        answer: "I don't have enough information in your Recallr memory to answer that confidently.",
        status: AiAnswerStatus.empty,
        query: request.query,
        confidence: 0.0,
        evidence: const [],
        generatedAt: DateTime.now(),
      );
    }

    final evidence = groundingService.extractEvidence(context, maxItems: request.maxEvidence);
    final confidence = forcedConfidence ?? groundingService.calculateConfidence(context: context, evidence: evidence);
    final people = groundingService.extractMentionedPeople(context, evidence);
    final companies = groundingService.extractMentionedCompanies(context, evidence);
    final actions = groundingService.extractSuggestedActions(context, evidence);

    final personName = context.targetPerson?.name ?? 'your contact';

    return AiAnswer(
      answer: 'Mock grounded answer for "${request.query}" regarding $personName backed by ${evidence.length} evidence items.',
      status: AiAnswerStatus.completed,
      query: request.query,
      intent: context.query.intent,
      confidence: confidence,
      evidence: evidence,
      mentionedPeople: people,
      mentionedCompanies: companies,
      suggestedActions: actions,
      generatedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {}
}