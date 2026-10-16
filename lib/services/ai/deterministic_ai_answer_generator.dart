import '../../features/ask/models/ai_answer_models.dart';
import '../../features/ask/models/memory_retrieval_models.dart';
import 'ai_answer_generator.dart';
import 'answer_grounding_service.dart';

/// Production-ready deterministic AI answer synthesizer that grounds responses
/// purely on verified personal memory context with zero external LLM dependencies.
class DeterministicAiAnswerGenerator implements AiAnswerGenerator {
  final AnswerGroundingService groundingService;

  const DeterministicAiAnswerGenerator({
    this.groundingService = const AnswerGroundingService(),
  });

  @override
  Future<AiAnswer> generateAnswer({
    required AiAnswerRequest request,
    required MemoryContext context,
  }) async {
    final evidence = groundingService.extractEvidence(context, maxItems: request.maxEvidence);
    final confidence = groundingService.calculateConfidence(context: context, evidence: evidence);
    final people = groundingService.extractMentionedPeople(context, evidence);
    final companies = groundingService.extractMentionedCompanies(context, evidence);
    final actions = groundingService.extractSuggestedActions(context, evidence);

    // Rule 3 & 4: Empty retrieval -> Zero hallucination uncertainty response
    if (evidence.isEmpty && context.targetPerson == null) {
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

    final queryIntent = context.query.intent;
    final generatedText = _synthesizeGroundedAnswer(
      intent: queryIntent,
      context: context,
      evidence: evidence,
    );

    return AiAnswer(
      answer: generatedText,
      status: AiAnswerStatus.completed,
      query: request.query,
      intent: queryIntent,
      confidence: confidence,
      evidence: evidence,
      mentionedPeople: people,
      mentionedCompanies: companies,
      suggestedActions: actions,
      generatedAt: DateTime.now(),
      wasTruncated: context.wasTruncated,
    );
  }

  String _synthesizeGroundedAnswer({
    required MemoryQueryIntent intent,
    required MemoryContext context,
    required List<AiAnswerEvidence> evidence,
  }) {
    final person = context.targetPerson;
    final profile = context.targetProfile;

    switch (intent) {
      case MemoryQueryIntent.personLookup:
        if (person != null) {
          final loc = person.locationOrEvent != null ? ' (${person.locationOrEvent})' : '';
          final caps = person.capabilities.isNotEmpty
              ? ' Their core capabilities include: ${person.capabilities.join(", ")}.'
              : '';
          final last = person.lastInteraction != null
              ? ' You last interacted ${person.lastInteraction}.'
              : '';
          return '${person.name} is ${person.role} at ${person.company}$loc.$caps$last';
        }
        break;

      case MemoryQueryIntent.companyLookup:
        if (context.relevantPeople.isNotEmpty) {
          final contacts = context.relevantPeople
              .map((p) => '${p.name} (${p.role})')
              .join(', ');
          final companyName = context.targetPerson?.company ??
              context.query.targetCompanyName ??
              'this organization';
          return 'In your network at $companyName, you are connected with $contacts.';
        }
        break;

      case MemoryQueryIntent.interactionLookup:
        if (context.relevantTimeline.isNotEmpty) {
          final topEvent = context.relevantTimeline.first;
          return 'According to your interaction timeline with ${person?.name ?? "your contact"}, you met for "${topEvent.title}" on ${topEvent.date}. Key takeaways: ${topEvent.summary}';
        } else if (evidence.any((e) => e.sourceType == MemorySourceType.activity)) {
          final actEv = evidence.firstWhere((e) => e.sourceType == MemorySourceType.activity);
          return 'Your recent interaction note: ${actEv.content}';
        }
        break;

      case MemoryQueryIntent.memoryLookup:
        if (context.relevantMemories.isNotEmpty) {
          final mems = context.relevantMemories.take(2).map((m) => '"${m.text}"').join(' and ');
          return 'Based on your recorded memories for ${person?.name ?? "this topic"}: $mems.';
        }
        break;

      case MemoryQueryIntent.followUpLookup:
        if (context.relevantFollowUps.isNotEmpty) {
          final fu = context.relevantFollowUps.first;
          final personName = person?.name ?? fu.personName ?? 'your contact';
          return 'You have an active commitment regarding $personName: "${fu.title}", which is due ${fu.dueDate}. Context: ${fu.context}';
        }
        break;

      case MemoryQueryIntent.recentInteraction:
        if (evidence.isNotEmpty) {
          final items = evidence
              .take(3)
              .map((e) => e.personName != null ? '${e.personName} (${e.timestamp ?? "recently"})' : e.title)
              .join(', ');
          return 'Your most recent network interactions include: $items.';
        }
        break;

      case MemoryQueryIntent.relationshipOverview:
        if (person != null) {
          final stats = profile != null
              ? 'Relationship Strength: ${profile.relationshipStrength.toUpperCase()} with ${profile.totalInteractions} total interactions.'
              : '';
          final recentNote = profile?.timeline.isNotEmpty == true
              ? ' Last encounter was on ${profile!.timeline.first.date} regarding "${profile.timeline.first.title}".'
              : '';
          final pendingFu = context.relevantFollowUps.isNotEmpty
              ? ' Pending commitment: "${context.relevantFollowUps.first.title}".'
              : '';
          return 'Here is your 360° briefing for ${person.name} (${person.role} at ${person.company}): $stats$recentNote$pendingFu';
        }
        break;

      case MemoryQueryIntent.projectLookup:
      case MemoryQueryIntent.generalSearch:
        if (evidence.isNotEmpty) {
          final topEvidence = evidence.take(2).map((e) => e.content).join(' ');
          return 'Based on your personal memory records: $topEvidence';
        }
        break;
    }

    // Fallback: ground over top available evidence
    if (evidence.isNotEmpty) {
      final summary = evidence.first.content;
      return 'Found in your relationship memory: $summary';
    }

    return "I don't have enough information in your Recallr memory to answer that confidently.";
  }

  @override
  void dispose() {}
}