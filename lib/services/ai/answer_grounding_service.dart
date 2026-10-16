import '../../features/ask/models/ai_answer_models.dart';
import '../../features/ask/models/ask_models.dart';
import '../../features/ask/models/memory_retrieval_models.dart';

/// Service responsible for transforming raw retrieved memory context into
/// verified, grounded evidence structures with confidence metrics and entity references.
class AnswerGroundingService {
  final AiAnswerConfiguration configuration;

  const AnswerGroundingService({
    this.configuration = const AiAnswerConfiguration(),
  });

  /// Transforms MemoryContext into structured, deduplicated, and budgeted AI evidence.
  List<AiAnswerEvidence> extractEvidence(MemoryContext context, {int? maxItems}) {
    final limit = maxItems ?? configuration.maxEvidenceItems;
    final evidenceList = <AiAnswerEvidence>[];
    final seenSources = <String>{};

    // 1. Convert explicit evidence items
    for (final ev in context.evidenceItems) {
      if (seenSources.contains(ev.sourceId)) continue;
      seenSources.add(ev.sourceId);

      final route = _determineRoute(ev.sourceType, ev.sourceId, ev.personId);

      evidenceList.add(AiAnswerEvidence(
        sourceType: ev.sourceType,
        sourceId: ev.sourceId,
        personId: ev.personId,
        personName: ev.personName,
        title: _formatTitle(ev),
        content: ev.content,
        timestamp: ev.timestamp,
        relevanceScore: ev.relevanceScore,
        matchReason: ev.matchReason,
        targetRoute: route,
      ));
    }

    // 2. If targetPerson is present but not in evidence list, prepend as primary evidence
    if (context.targetPerson != null && !seenSources.contains(context.targetPerson!.id)) {
      final p = context.targetPerson!;
      evidenceList.insert(
        0,
        AiAnswerEvidence(
          sourceType: MemorySourceType.person,
          sourceId: p.id,
          personId: p.id,
          personName: p.name,
          title: '${p.name} · ${p.role}',
          content: '${p.name} is ${p.role} at ${p.company}. Capabilities: ${p.capabilities.join(", ")}.',
          timestamp: p.lastInteraction,
          relevanceScore: 1.0,
          matchReason: 'Direct Person Entity Match',
          targetRoute: '/person/${p.id}',
        ),
      );
      seenSources.add(p.id);
    }

    // 3. If relevantPeople contains candidates not yet in evidence, append them
    for (final p in context.relevantPeople) {
      if (!seenSources.contains(p.id)) {
        seenSources.add(p.id);
        evidenceList.add(
          AiAnswerEvidence(
            sourceType: MemorySourceType.person,
            sourceId: p.id,
            personId: p.id,
            personName: p.name,
            title: '${p.name} · ${p.role}',
            content: '${p.name} is ${p.role} at ${p.company}.',
            timestamp: p.lastInteraction,
            relevanceScore: 0.90,
            matchReason: 'Relevant Person Match',
            targetRoute: '/person/${p.id}',
          ),
        );
      }
    }

    return evidenceList.take(limit).toList();
  }

  /// Deterministically calculates answer confidence score between 0.0 and 1.0.
  double calculateConfidence({
    required MemoryContext context,
    required List<AiAnswerEvidence> evidence,
  }) {
    if (context.isEmpty && evidence.isEmpty) return 0.0;
    if (evidence.isEmpty) return 0.20;

    double score = 0.50; // Base score for having evidence

    // High confidence signals
    if (context.targetPerson != null) {
      score += 0.25;
    }

    final topScore = evidence.first.relevanceScore;
    score += (topScore * 0.15);

    if (evidence.length >= 3) {
      score += 0.10;
    }

    return double.parse(score.clamp(0.0, 1.0).toStringAsFixed(2));
  }

  /// Extracts PersonReference objects for UI chips from context and evidence.
  List<PersonReference> extractMentionedPeople(MemoryContext context, List<AiAnswerEvidence> evidence) {
    final people = <PersonReference>[];
    final seenPersonIds = <String>{};

    if (context.targetPerson != null) {
      final p = context.targetPerson!;
      seenPersonIds.add(p.id);
      people.add(PersonReference(
        id: p.id,
        name: p.name,
        role: p.role,
        company: p.company,
        initials: p.initials,
        relationshipContext: p.relationshipType?.name.toUpperCase() ?? 'COLLABORATOR',
        targetRoute: '/person/${p.id}',
      ));
    }

    for (final ev in evidence) {
      if (ev.personId != null && !seenPersonIds.contains(ev.personId!)) {
        seenPersonIds.add(ev.personId!);
        final name = ev.personName ?? 'Contact';
        final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();
        people.add(PersonReference(
          id: ev.personId!,
          name: name,
          role: 'Referenced in Memory',
          company: '',
          initials: initials.isNotEmpty ? initials : 'RC',
          relationshipContext: 'CITED IN MEMORY',
          targetRoute: '/person/${ev.personId}',
        ));
      }
    }

    return people;
  }

  /// Extracts mentioned company names from context.
  List<String> extractMentionedCompanies(MemoryContext context, List<AiAnswerEvidence> evidence) {
    final companies = <String>{};
    if (context.targetPerson?.company.isNotEmpty == true) {
      companies.add(context.targetPerson!.company);
    }
    for (final p in context.relevantPeople) {
      if (p.company.isNotEmpty) companies.add(p.company);
    }
    return companies.toList();
  }

  /// Extracts actionable next steps or suggestions based on context.
  List<String> extractSuggestedActions(MemoryContext context, List<AiAnswerEvidence> evidence) {
    final actions = <String>[];

    if (context.relevantFollowUps.isNotEmpty) {
      final nextFu = context.relevantFollowUps.first;
      actions.add('Follow up on: "${nextFu.title}" (Due: ${nextFu.dueDate})');
    }

    if (context.targetPerson != null) {
      actions.add('View full 360° dossier for ${context.targetPerson!.name}');
    }

    if (actions.isEmpty && evidence.isNotEmpty) {
      actions.add('Capture a new encounter or update memory notes');
    }

    return actions;
  }

  String _formatTitle(MemoryEvidence ev) {
    switch (ev.sourceType) {
      case MemorySourceType.person:
        return '${ev.personName ?? "Person"} Profile';
      case MemorySourceType.activity:
        return 'Interaction Note';
      case MemorySourceType.capture:
        return 'Omni-Capture Intake';
      case MemorySourceType.memory:
        return 'Structured Memory Claim';
      case MemorySourceType.followUp:
        return 'Actionable Commitment';
      case MemorySourceType.timeline:
        return 'Timeline Encounter';
    }
  }

  String _determineRoute(MemorySourceType type, String sourceId, String? personId) {
    switch (type) {
      case MemorySourceType.person:
        return '/person/${personId ?? sourceId}';
      case MemorySourceType.followUp:
        return '/follow-up/$sourceId';
      case MemorySourceType.activity:
        return '/interaction/$sourceId';
      case MemorySourceType.capture:
        return '/file/$sourceId';
      case MemorySourceType.memory:
      case MemorySourceType.timeline:
        return personId != null ? '/person/$personId' : '/people';
    }
  }
}