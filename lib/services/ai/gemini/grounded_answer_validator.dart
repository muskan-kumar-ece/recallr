import '../../../features/ask/models/ai_answer_models.dart';
import '../../../features/ask/models/ask_models.dart';
import '../../../features/ask/models/memory_retrieval_models.dart';
import '../answer_grounding_service.dart';
import 'gemini_response_parser.dart';

/// Validates raw Gemini output against authoritative Recallr MemoryContext to prevent hallucinations.
class GroundedAnswerValidator {
  final AnswerGroundingService groundingService;

  const GroundedAnswerValidator({
    this.groundingService = const AnswerGroundingService(),
  });

  /// Validates a parsed Gemini answer and transforms it into an authoritative `AiAnswer`.
  AiAnswer validate({
    required ParsedGeminiAnswer parsed,
    required MemoryContext context,
    required AiAnswerRequest request,
  }) {
    // 1. Extract all verified candidate evidence from Recallr's context
    final candidateEvidence = groundingService.extractEvidence(
      context,
      maxItems: request.maxEvidence,
    );
    final candidateEvidenceMap = {for (final e in candidateEvidence) e.sourceId: e};

    // 2. Validate Evidence IDs - Reject any ID not provided by Recallr
    final validatedEvidence = <AiAnswerEvidence>[];
    final seenIds = <String>{};

    for (final evidenceId in parsed.evidenceIds) {
      if (candidateEvidenceMap.containsKey(evidenceId) && !seenIds.contains(evidenceId)) {
        seenIds.add(evidenceId);
        validatedEvidence.add(candidateEvidenceMap[evidenceId]!);
      }
    }

    // When no specific evidence IDs were provided, or when valid context exists for a known person,
    // retain candidate evidence from Recallr's context to ground the response.
    if (validatedEvidence.isEmpty && candidateEvidence.isNotEmpty) {
      if (parsed.evidenceIds.isEmpty) {
        validatedEvidence.addAll(candidateEvidence);
      } else if (context.targetPerson != null) {
        // Fallback retains candidate context when target person is verified
        validatedEvidence.addAll(candidateEvidence);
      }
    }

    // Track whether citations were attempted but completely ungrounded in context
    final bool hadHallucinatedEvidence = parsed.evidenceIds.isNotEmpty &&
        validatedEvidence.isEmpty &&
        candidateEvidence.isEmpty;

    // 4. Validate Mentioned People - Reject any person not in Recallr context
    final validPeople = <PersonReference>[];
    final knownPeopleMap = <String, PersonReference>{};

    if (context.targetPerson != null) {
      final p = context.targetPerson!;
      knownPeopleMap[p.id] = PersonReference(
        id: p.id,
        name: p.name,
        role: p.role,
        company: p.company,
        initials: p.initials,
        relationshipContext: p.relationshipType?.name ?? 'collaborator',
        targetRoute: '/person/${p.id}',
      );
    }

    for (final p in context.relevantPeople) {
      knownPeopleMap[p.id] = PersonReference(
        id: p.id,
        name: p.name,
        role: p.role,
        company: p.company,
        initials: p.initials,
        relationshipContext: p.relationshipType?.name ?? 'collaborator',
        targetRoute: '/person/${p.id}',
      );
    }

    for (final item in parsed.mentionedPeople) {
      final personId = item['personId'] ?? '';
      final name = item['name'] ?? '';

      // Match by exact ID or exact Name
      PersonReference? matchedRef;
      if (personId.isNotEmpty && knownPeopleMap.containsKey(personId)) {
        matchedRef = knownPeopleMap[personId];
      } else if (name.isNotEmpty) {
        matchedRef = knownPeopleMap.values.cast<PersonReference?>().firstWhere(
              (ref) => ref?.name.toLowerCase() == name.toLowerCase(),
              orElse: () => null,
            );
      }

      if (matchedRef != null && !validPeople.any((r) => r.id == matchedRef!.id)) {
        validPeople.add(matchedRef);
      }
    }

    if (validPeople.isEmpty && validatedEvidence.isNotEmpty) {
      validPeople.addAll(groundingService.extractMentionedPeople(context, validatedEvidence));
    }

    final bool hadHallucinatedPeople =
        parsed.mentionedPeople.isNotEmpty && validPeople.isEmpty;

    // 5. Calibrate Confidence - Grounded in Recallr evidence, capped by deterministic score
    final deterministicConf = groundingService.calculateConfidence(
      context: context,
      evidence: validatedEvidence,
    );

    double finalConfidence = parsed.confidence;
    if (finalConfidence <= 0.0) {
      finalConfidence = deterministicConf;
    } else {
      // Never allow Gemini to claim higher confidence than underlying evidence supports (+0.05 tolerance)
      finalConfidence = finalConfidence.clamp(0.0, (deterministicConf + 0.05).clamp(0.0, 1.0));
    }

    // 6. Anti-Hallucination Status Evaluation
    final cleanAnswer = parsed.answer.trim();
    final isUncertainty = cleanAnswer.toLowerCase().contains("don't have enough information") ||
        cleanAnswer.toLowerCase().contains("not enough information") ||
        cleanAnswer.toLowerCase().contains("no memory found") ||
        cleanAnswer.isEmpty;

    // Fail closed if:
    // a) All evidence citations were hallucinations with no candidate context
    // b) All mentioned people were hallucinations with no known entities in context
    // c) No validated evidence exists and there is no target person in context
    if (hadHallucinatedEvidence ||
        hadHallucinatedPeople ||
        (validatedEvidence.isEmpty && context.targetPerson == null)) {
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
        errorType: AiErrorType.insufficientEvidence,
        generatedAt: DateTime.now(),
      );
    }

    final status = isUncertainty ? AiAnswerStatus.empty : AiAnswerStatus.completed;

    // 6. Actionable Next Steps
    var suggestedActions = parsed.suggestedActions;
    if (suggestedActions.isEmpty) {
      suggestedActions = groundingService.extractSuggestedActions(context, validatedEvidence);
    }

    return AiAnswer(
      answer: cleanAnswer.isNotEmpty ? cleanAnswer : "I don't have enough information in your Recallr memory to answer that confidently.",
      status: status,
      query: request.query,
      intent: context.query.intent,
      confidence: status == AiAnswerStatus.empty ? 0.0 : finalConfidence,
      evidence: validatedEvidence,
      mentionedPeople: validPeople,
      mentionedCompanies: groundingService.extractMentionedCompanies(context, validatedEvidence),
      suggestedActions: suggestedActions,
      wasTruncated: context.wasTruncated,
      generatedAt: DateTime.now(),
    );
  }
}