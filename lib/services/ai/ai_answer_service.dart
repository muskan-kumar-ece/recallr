import 'dart:async';
import '../../core/errors/data_exceptions.dart';
import '../../features/ask/models/ai_answer_models.dart';
import '../../features/ask/models/memory_retrieval_models.dart';
import '../retrieval/memory_retrieval_service.dart';
import 'ai_answer_generator.dart';
import 'answer_grounding_service.dart';
import 'deterministic_ai_answer_generator.dart';

/// Abstract service for answering natural language questions grounded in personal relationship memory.
abstract class AiAnswerService {
  /// Generate a grounded AI answer for the requested query.
  Future<AiAnswer> answer(AiAnswerRequest request);

  /// Release any generator or service resources.
  void dispose();
}

/// Production implementation of AiAnswerService orchestrating retrieval, grounding, and answer generation.
class DeterministicAiAnswerService implements AiAnswerService {
  final MemoryRetrievalService retrievalService;
  final AiAnswerGenerator generator;
  final AnswerGroundingService groundingService;

  const DeterministicAiAnswerService({
    required this.retrievalService,
    this.generator = const DeterministicAiAnswerGenerator(),
    this.groundingService = const AnswerGroundingService(),
  });

  @override
  Future<AiAnswer> answer(AiAnswerRequest request) async {
    try {
      // 1. Retrieve Personal Memory Context via Phase 13E-01
      final searchResult = await retrievalService.retrieve(
        request.query,
        maxEvidence: request.maxEvidence,
      );

      // 2. Short-circuit if retrieval failed
      if (searchResult.status == MemoryRetrievalStatus.failed) {
        AiErrorType mappedError = AiErrorType.aiUnavailable;
        if (searchResult.errorType == DataErrorType.networkUnavailable) {
          mappedError = AiErrorType.networkUnavailable;
        } else if (searchResult.errorType == DataErrorType.unauthenticated) {
          mappedError = AiErrorType.unauthenticated;
        } else if (searchResult.errorType == DataErrorType.invalidData) {
          mappedError = AiErrorType.invalidData;
        }

        return AiAnswer(
          answer: 'Unable to retrieve memory context at this time.',
          status: AiAnswerStatus.failed,
          query: request.query,
          confidence: 0.0,
          errorMessage: searchResult.errorMessage,
          errorType: mappedError,
          generatedAt: DateTime.now(),
        );
      }

      // 3. Short-circuit if retrieval returned empty
      if (searchResult.status == MemoryRetrievalStatus.empty || searchResult.context.isEmpty) {
        return AiAnswer(
          answer: "I don't have enough information in your Recallr memory to answer that confidently.",
          status: AiAnswerStatus.empty,
          query: request.query,
          intent: searchResult.query.intent,
          confidence: 0.0,
          evidence: const [],
          mentionedPeople: const [],
          mentionedCompanies: const [],
          suggestedActions: const ['Capture a visiting card or voice note to add new memories'],
          errorType: AiErrorType.insufficientEvidence,
          generatedAt: DateTime.now(),
        );
      }

      // 4. Generate Grounded AI Answer
      return await generator.generateAnswer(
        request: request,
        context: searchResult.context,
      );
    } on RecallrDataException catch (e) {
      if (e.type == DataErrorType.unauthenticated) {
        rethrow;
      }
      AiErrorType mappedError = AiErrorType.aiUnavailable;
      if (e.type == DataErrorType.networkUnavailable) {
        mappedError = AiErrorType.networkUnavailable;
      } else if (e.type == DataErrorType.invalidData) {
        mappedError = AiErrorType.invalidData;
      }
      return AiAnswer(
        answer: 'Failed to synthesize answer: ${e.message}',
        status: AiAnswerStatus.failed,
        query: request.query,
        confidence: 0.0,
        errorMessage: e.message,
        errorType: mappedError,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      return AiAnswer(
        answer: 'Failed to synthesize answer.',
        status: AiAnswerStatus.failed,
        query: request.query,
        confidence: 0.0,
        errorMessage: e.toString(),
        errorType: AiErrorType.aiUnavailable,
        generatedAt: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    generator.dispose();
  }
}

/// Deterministic mock service for testing and offline widget mocks.
class MockAiAnswerService implements AiAnswerService {
  bool shouldFail;
  String errorMessage;
  Duration simulatedDelay;
  AiAnswer? forcedAnswer;
  int answerCalls = 0;
  final AiAnswerGenerator generator;

  MockAiAnswerService({
    this.shouldFail = false,
    this.errorMessage = 'Simulated AI service failure',
    this.simulatedDelay = Duration.zero,
    this.forcedAnswer,
    AiAnswerGenerator? generator,
  }) : generator = generator ?? const DeterministicAiAnswerGenerator();

  @override
  Future<AiAnswer> answer(AiAnswerRequest request) async {
    answerCalls++;

    if (shouldFail) {
      throw RecallrDataException.networkUnavailable(errorMessage);
    }

    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (forcedAnswer == null) {
      return AiAnswer(
        answer: "No memory context available in test/offline mode.",
        status: AiAnswerStatus.empty,
        query: request.query,
        confidence: 0.0,
        evidence: const [],
        mentionedPeople: const [],
        mentionedCompanies: const [],
        generatedAt: DateTime.now(),
      );
    }

    return forcedAnswer!;
  }

  @override
  void dispose() {
    generator.dispose();
  }
}