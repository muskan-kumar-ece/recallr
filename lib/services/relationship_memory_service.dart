import 'dart:async';
import '../features/activity/models/activity_models.dart';
import '../features/capture/models/capture_models.dart';
import '../features/capture/models/ocr_models.dart';
import '../features/follow_ups/models/follow_up_models.dart';
import '../features/people/models/person_item.dart';
import '../features/person_detail/models/person_profile_model.dart';
import '../features/person_detail/models/relationship_memory_models.dart';
import '../repositories/follow_up_repository.dart';
import '../repositories/people_repository.dart';
import '../repositories/person_detail_repository.dart';

/// Abstract service contract for enriching relationship memory, timeline, and commitments.
abstract class RelationshipMemoryService {
  Future<RelationshipMemoryResult> enrichMemory({
    required CaptureItem capture,
    required PersonItem person,
    ActivityItem? activity,
    OcrExtractedEntities? entities,
    bool autoCreateFollowUp = true,
  });
}

/// Deterministic, production-ready implementation of RelationshipMemoryService.
class DeterministicRelationshipMemoryService implements RelationshipMemoryService {
  final PersonDetailRepository personDetailRepository;
  final FollowUpRepository? followUpRepository;
  final PeopleRepository? peopleRepository;
  final Duration simulatedLatency;

  const DeterministicRelationshipMemoryService({
    required this.personDetailRepository,
    this.followUpRepository,
    this.peopleRepository,
    this.simulatedLatency = Duration.zero,
  });

  @override
  Future<RelationshipMemoryResult> enrichMemory({
    required CaptureItem capture,
    required PersonItem person,
    ActivityItem? activity,
    OcrExtractedEntities? entities,
    bool autoCreateFollowUp = true,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    try {
      final textContent = '${capture.title} ${capture.description} ${capture.extractedText ?? ""}';

      // 1. Generate Timeline Item (Idempotent ID)
      final timelineItem = _buildTimelineItem(capture, person, entities);

      // 2. Extract Structured Memory Items
      final memories = _extractMemories(capture, person, entities, textContent);

      // 3. Detect Potential Follow-up Commitment
      FollowUpItem? followUp;
      if (autoCreateFollowUp) {
        followUp = _detectFollowUp(capture, person, textContent);
        if (followUp != null && followUpRepository != null) {
          final existingFu = await followUpRepository!.getFollowUp(followUp.id);
          if (existingFu == null) {
            await followUpRepository!.addFollowUp(followUp);
          }
        }
      }

      // 4. Calculate Relationship Metrics
      final existingProfile = await personDetailRepository.getProfile(person.id);
      final existingTimelineIds = existingProfile?.timeline.map((t) => t.id).toSet() ?? <String>{};
      final isNewInteraction = !existingTimelineIds.contains(timelineItem.id);

      final totalInteractions = (existingProfile?.totalInteractions ?? 0) + (isNewInteraction ? 1 : 0);
      final relationshipStrength = _computeRelationshipStrength(totalInteractions);

      // 5. Build Memory Update & Enrich Profile
      final update = RelationshipMemoryUpdate(
        personId: person.id,
        captureId: capture.id,
        activityId: activity?.id ?? 'act_cap_${capture.id}',
        timelineItem: timelineItem,
        memories: memories,
        followUpCandidate: followUp,
        newCapabilities: entities?.keyPoints ?? const [],
        relationshipStrength: relationshipStrength,
        totalInteractions: totalInteractions,
        lastInteraction: capture.timestamp.isNotEmpty ? capture.timestamp : 'Today',
      );

      final updatedProfile = await personDetailRepository.enrichRelationshipMemory(
        personId: person.id,
        update: update,
      );

      // 6. Update People Directory metadata if available
      if (peopleRepository != null && isNewInteraction) {
        await peopleRepository!.enrichPerson(person.id, {
          'lastInteraction': capture.timestamp.isNotEmpty ? capture.timestamp : 'Today',
          'lastInteractionDate': DateTime.now(),
        });
      }

      return RelationshipMemoryResult(
        personId: person.id,
        captureId: capture.id,
        status: RelationshipMemoryStatus.completed,
        createdTimelineItem: timelineItem,
        createdMemories: memories,
        createdFollowUp: followUp,
        updatedProfile: updatedProfile,
        processedAt: DateTime.now(),
      );
    } catch (e) {
      return RelationshipMemoryResult(
        personId: person.id,
        captureId: capture.id,
        status: RelationshipMemoryStatus.failed,
        errorMessage: e.toString(),
        processedAt: DateTime.now(),
      );
    }
  }

  TimelineItem _buildTimelineItem(
    CaptureItem capture,
    PersonItem person,
    OcrExtractedEntities? entities,
  ) {
    final type = _mapCaptureTypeToTimelineType(capture.type);
    final subtitle = person.company.isNotEmpty
        ? person.company
        : (person.role.isNotEmpty ? person.role : type.label);

    final bullets = <String>[];
    if (entities != null && entities.keyPoints.isNotEmpty) {
      bullets.addAll(entities.keyPoints);
    } else if (capture.summary != null && capture.summary!.isNotEmpty) {
      bullets.add(capture.summary!);
    }

    return TimelineItem(
      id: 'tl_cap_${capture.id}',
      type: type,
      title: capture.title.isNotEmpty ? capture.title : 'Captured Encounter: ${person.name}',
      subtitle: subtitle,
      date: capture.timestamp.isNotEmpty ? capture.timestamp : 'Today',
      locationOrEvent: capture.location ?? person.locationOrEvent,
      summary: capture.summary ?? (capture.description.isNotEmpty ? capture.description : 'Captured encounter recorded.'),
      keyBullets: bullets,
      targetRoute: '/person/${person.id}',
    );
  }

  List<MemoryItem> _extractMemories(
    CaptureItem capture,
    PersonItem person,
    OcrExtractedEntities? entities,
    String textContent,
  ) {
    final memories = <MemoryItem>[];

    // 1. Encounter / Discussion Context Memory
    if (capture.description.isNotEmpty || capture.summary != null) {
      final summaryText = capture.summary ?? capture.description;
      memories.add(MemoryItem(
        id: 'mem_cap_${capture.id}_context',
        category: 'Interaction Context',
        text: summaryText,
        source: '${capture.type.label} · ${capture.timestamp.isNotEmpty ? capture.timestamp : "Recent"}',
        timestamp: capture.timestamp,
        isVerified: true,
      ));
    }

    // 2. Technical Capabilities / Topics Memory
    if (entities != null && entities.keyPoints.isNotEmpty) {
      memories.add(MemoryItem(
        id: 'mem_cap_${capture.id}_topics',
        category: 'Capabilities & Focus',
        text: 'Key focus areas: ${entities.keyPoints.join(", ")}',
        source: 'Entity Intelligence',
        timestamp: capture.timestamp,
        isVerified: true,
      ));
    }

    // 3. Organization & Coordinate Memory
    if (entities != null && (entities.company != null || entities.email != null || entities.phone != null)) {
      final details = <String>[];
      if (entities.role != null) details.add(entities.role!);
      if (entities.company != null) details.add(entities.company!);
      if (entities.email != null) details.add(entities.email!);
      if (entities.phone != null) details.add(entities.phone!);

      memories.add(MemoryItem(
        id: 'mem_cap_${capture.id}_contact',
        category: 'Organization & Role',
        text: details.join(' · '),
        source: 'Contact Card Metadata',
        timestamp: capture.timestamp,
        isVerified: true,
      ));
    }

    return memories;
  }

  FollowUpItem? _detectFollowUp(
    CaptureItem capture,
    PersonItem person,
    String text,
  ) {
    final lower = text.toLowerCase();

    final theyPromisedKeywords = [
      "promised to",
      "he will send",
      "she will send",
      "they will send",
      "will share the",
      "will email",
      "they will follow up",
      "she will follow up",
      "he will follow up",
    ];

    final iPromisedKeywords = [
      "i'll send",
      "i will send",
      "i promised",
      "send over",
      "send the proposal",
      "email the deck",
      "follow up with",
      "schedule another meeting",
      "agreed to send",
      "review the proposal",
      "provide feedback",
    ];

    bool isIPromised = false;
    bool isTheyPromised = false;
    String matchedPhrase = '';

    for (final kw in theyPromisedKeywords) {
      if (lower.contains(kw)) {
        isTheyPromised = true;
        matchedPhrase = kw;
        break;
      }
    }

    if (!isTheyPromised) {
      for (final kw in iPromisedKeywords) {
        if (lower.contains(kw)) {
          isIPromised = true;
          matchedPhrase = kw;
          break;
        }
      }
    }

    if (!isIPromised && !isTheyPromised) {
      return null;
    }

    // Extract due date heuristic
    String dueDate = 'Next Week';
    if (lower.contains('tomorrow')) {
      dueDate = 'Tomorrow';
    } else if (lower.contains('friday')) {
      dueDate = 'This Friday';
    } else if (lower.contains('monday')) {
      dueDate = 'Next Monday';
    } else if (lower.contains('next week')) {
      dueDate = 'Next Week';
    } else if (lower.contains('end of week') || lower.contains('eow')) {
      dueDate = 'End of Week';
    }

    final commitmentType = isIPromised ? CommitmentType.iPromised : CommitmentType.theyPromised;
    final actionTitle = isIPromised
        ? 'Send commitment deliverables to ${person.name}'
        : 'Follow up with ${person.name} on promised deliverables';

    return FollowUpItem(
      id: 'fu_cap_${capture.id}',
      title: actionTitle,
      context: 'Commitment detected from ${capture.type.label}: "$matchedPhrase" in discussion with ${person.name}.',
      commitmentType: commitmentType,
      status: FollowUpStatus.upcoming,
      priority: FollowUpPriority.high,
      dueDate: dueDate,
      createdDate: capture.timestamp.isNotEmpty ? capture.timestamp : 'Today',
      personId: person.id,
      personName: person.name,
      personRole: person.role,
      companyId: person.company,
      companyName: person.company,
      sourceInteractionId: capture.id,
      sourceMemoryTitle: capture.title,
      targetRoute: '/person/${person.id}',
    );
  }

  String _computeRelationshipStrength(int totalInteractions) {
    if (totalInteractions <= 1) {
      return 'Emerging Connection';
    } else if (totalInteractions <= 3) {
      return 'Active Collaborator';
    } else if (totalInteractions <= 6) {
      return 'Strong Connection';
    } else {
      return 'Core Network / High Trust';
    }
  }

  TimelineType _mapCaptureTypeToTimelineType(CaptureType type) {
    switch (type) {
      case CaptureType.businessCard:
        return TimelineType.cardScan;
      case CaptureType.voice:
        return TimelineType.voiceNote;
      case CaptureType.note:
        return TimelineType.conversation;
      case CaptureType.photo:
        return TimelineType.meeting;
      case CaptureType.document:
        return TimelineType.fileNote;
    }
  }
}