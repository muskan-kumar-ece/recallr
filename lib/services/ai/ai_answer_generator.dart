import '../../features/ask/models/ai_answer_models.dart';
import '../../features/ask/models/memory_retrieval_models.dart';

/// Provider-agnostic abstraction for AI answer generation over personal memory context.
abstract class AiAnswerGenerator {
  /// Generate a grounded AI answer using the provided request and retrieved MemoryContext.
  Future<AiAnswer> generateAnswer({
    required AiAnswerRequest request,
    required MemoryContext context,
  });

  /// Cleanup any generator resources when no longer needed.
  void dispose();
}