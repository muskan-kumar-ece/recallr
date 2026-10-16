import '../../features/ask/models/memory_retrieval_models.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/relationship_intelligence/models/models.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/capture_repository.dart';
import '../../repositories/follow_up_repository.dart';
import '../../repositories/people_repository.dart';
import '../../repositories/person_detail_repository.dart';
import 'memory_relevance_ranker.dart';

/// Service responsible for assembling full 360-degree structured personal context for a person or topic.
class RelationshipContextAssembler {
  final PeopleRepository peopleRepository;
  final PersonDetailRepository personDetailRepository;
  final ActivityRepository? activityRepository;
  final FollowUpRepository? followUpRepository;
  final CaptureRepository? captureRepository;
  final MemoryRelevanceRanker ranker;

  const RelationshipContextAssembler({
    required this.peopleRepository,
    required this.personDetailRepository,
    this.activityRepository,
    this.followUpRepository,
    this.captureRepository,
    this.ranker = const MemoryRelevanceRanker(),
  });

  /// Assembles complete relationship context for a specific Person ID.
  Future<MemoryContext> assembleForPerson({
    required String personId,
    required MemoryQuery query,
    int maxEvidence = 20,
    UnifiedPersonRelationshipIntelligence? intelligence,
  }) async {
    final person = await peopleRepository.getPerson(personId);
    final profile = await personDetailRepository.getProfile(personId);

    final rawEvidence = <MemoryEvidence>[];

    // 1. Person Profile Evidence
    if (person != null) {
      rawEvidence.add(MemoryEvidence(
        id: 'ev_person_${person.id}',
        sourceType: MemorySourceType.person,
        sourceId: person.id,
        personId: person.id,
        personName: person.name,
        timestamp: person.lastInteraction,
        content: '${person.name} is ${person.role} at ${person.company}. Location: ${person.locationOrEvent ?? "Unknown"}. Capabilities: ${person.capabilities.join(", ")}.',
        relevanceScore: 1.0,
        matchReason: 'Canonical Person Profile',
      ));
    }

    // 1b. Unified Relationship Intelligence Evidence
    if (profile != null && intelligence != null) {
      final intelFormatted = formatProfileContext(profile, intelligence: intelligence);
      rawEvidence.add(MemoryEvidence(
        id: 'ev_intel_$personId',
        sourceType: MemorySourceType.person,
        sourceId: personId,
        personId: personId,
        personName: person?.name ?? profile.name,
        timestamp: intelligence.generatedAt.toIso8601String(),
        content: intelFormatted,
        relevanceScore: 0.95,
        matchReason: 'Unified Relationship Intelligence',
      ));
    }

    // 2. Timeline Encounters
    final timelineItems = profile?.timeline ?? <TimelineItem>[];
    for (final item in timelineItems) {
      rawEvidence.add(MemoryEvidence(
        id: 'ev_tl_${item.id}',
        sourceType: MemorySourceType.timeline,
        sourceId: item.id,
        personId: personId,
        personName: person?.name,
        timestamp: item.date,
        content: '${item.title} (${item.date}): ${item.summary} Key points: ${item.keyBullets.join("; ")}',
        relevanceScore: 0.85,
        matchReason: 'Chronological Timeline Interaction',
      ));
    }

    // 3. Memory Claims
    final memoryItems = profile?.memories ?? <MemoryItem>[];
    for (final mem in memoryItems) {
      rawEvidence.add(MemoryEvidence(
        id: 'ev_mem_${mem.id}',
        sourceType: MemorySourceType.memory,
        sourceId: mem.id,
        personId: personId,
        personName: person?.name,
        timestamp: mem.timestamp,
        content: '[${mem.category}] ${mem.text} (Source: ${mem.source})',
        relevanceScore: 0.80,
        matchReason: 'Atomic Memory Claim',
      ));
    }

    // 4. Follow-up Commitments
    final followUps = profile?.followUps ?? <FollowUpItem>[];
    for (final fu in followUps) {
      rawEvidence.add(MemoryEvidence(
        id: 'ev_fu_${fu.id}',
        sourceType: MemorySourceType.followUp,
        sourceId: fu.id,
        personId: personId,
        personName: person?.name,
        timestamp: fu.dueDate,
        content: '${fu.commitmentType.badgeText}: ${fu.title}. Due: ${fu.dueDate}. Status: ${fu.status.label}. Context: ${fu.context}',
        relevanceScore: 0.90,
        matchReason: 'Active Follow-up Commitment',
      ));
    }

    // 5. Relationship Intelligence Evidence
    if (profile != null && profile.id == personId && (profile.relationshipStrength.isNotEmpty || profile.totalInteractions > 0)) {
      rawEvidence.add(MemoryEvidence(
        id: 'ev_rel_intel_$personId',
        sourceType: MemorySourceType.person,
        sourceId: personId,
        personId: personId,
        personName: person?.name ?? profile.name,
        timestamp: profile.lastInteraction,
        content: 'Relationship with ${person?.name ?? profile.name}: Strength ${profile.relationshipStrength}, Total encounters ${profile.totalInteractions}, Last encounter ${profile.lastInteraction}.',
        relevanceScore: 0.85,
        matchReason: 'Grounded Relationship Intelligence',
      ));
    }

    // Rank and budget evidence
    final rankedEvidence = ranker.rank(
      query: query,
      candidateEvidence: rawEvidence,
      maxResults: maxEvidence,
    );

    final wasTruncated = rawEvidence.length > rankedEvidence.length;

    return MemoryContext(
      query: query,
      targetPerson: person,
      targetProfile: profile,
      evidenceItems: rankedEvidence,
      relevantPeople: person != null ? [person] : const [],
      relevantTimeline: timelineItems,
      relevantMemories: memoryItems,
      relevantFollowUps: followUps,
      wasTruncated: wasTruncated,
      originalCount: rawEvidence.length,
      returnedCount: rankedEvidence.length,
      assembledAt: DateTime.now(),
    );
  }

  /// Assembles general search context across all repositories.
  Future<MemoryContext> assembleGeneralContext({
    required MemoryQuery query,
    required List<MemoryEvidence> candidateEvidence,
    int maxEvidence = 20,
  }) async {
    final rankedEvidence = ranker.rank(
      query: query,
      candidateEvidence: candidateEvidence,
      maxResults: maxEvidence,
    );

    final wasTruncated = candidateEvidence.length > rankedEvidence.length;

    return MemoryContext(
      query: query,
      evidenceItems: rankedEvidence,
      wasTruncated: wasTruncated,
      originalCount: candidateEvidence.length,
      returnedCount: rankedEvidence.length,
      assembledAt: DateTime.now(),
    );
  }

  /// Formats profile context including rich relationship intelligence evidence.
  String formatProfileContext(
    PersonProfile profile, {
    UnifiedPersonRelationshipIntelligence? intelligence,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('${profile.name} (${profile.role} at ${profile.company})');
    if (intelligence != null) {
      buffer.writeln('Strength: ${intelligence.strengthScore.toStringAsFixed(1)} (${intelligence.relationshipState.displayName})');
      buffer.writeln('State: ${intelligence.relationshipState.displayName}');
      buffer.writeln('Momentum: ${intelligence.momentumDirection.name}');
      if (intelligence.isBridge) {
        buffer.writeln('Bridge Contact: Yes');
      }
      if (intelligence.clusterIds.isNotEmpty) {
        buffer.writeln('Clusters: ${intelligence.clusterIds.join(", ")}');
      }
      if (intelligence.primaryAction != null) {
        buffer.writeln('Recommended Action: ${intelligence.primaryAction!.title}');
      }
    }
    if (profile.memories.isNotEmpty) {
      for (final mem in profile.memories) {
        buffer.writeln('Memory: ${mem.text}');
      }
    }
    return buffer.toString();
  }
}