import 'dart:async';
import '../core/errors/data_exceptions.dart';
import '../features/activity/models/activity_models.dart';
import '../features/capture/models/capture_models.dart';
import '../features/capture/models/ocr_models.dart';
import '../features/people/models/person_item.dart';
import '../features/person_detail/models/person_profile_model.dart';
import '../features/person_detail/models/relationship_memory_models.dart';
import 'relationship_memory_service.dart';

/// Deterministic mock of RelationshipMemoryService for headless testing and previews.
class MockRelationshipMemoryService implements RelationshipMemoryService {
  bool shouldFail;
  String errorMessage;
  Duration simulatedDelay;
  RelationshipMemoryResult? forcedResult;
  int enrichCalls = 0;

  MockRelationshipMemoryService({
    this.shouldFail = false,
    this.errorMessage = 'Simulated relationship memory enrichment failure',
    this.simulatedDelay = Duration.zero,
    this.forcedResult,
  });

  @override
  Future<RelationshipMemoryResult> enrichMemory({
    required CaptureItem capture,
    required PersonItem person,
    ActivityItem? activity,
    OcrExtractedEntities? entities,
    bool autoCreateFollowUp = true,
  }) async {
    enrichCalls++;

    if (shouldFail) {
      throw RecallrDataException.networkUnavailable(errorMessage);
    }

    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (forcedResult != null) {
      return forcedResult!;
    }

    final timelineItem = TimelineItem(
      id: 'tl_cap_${capture.id}',
      type: TimelineType.meeting,
      title: capture.title.isNotEmpty ? capture.title : 'Captured Encounter: ${person.name}',
      subtitle: person.company.isNotEmpty ? person.company : person.role,
      date: capture.timestamp.isNotEmpty ? capture.timestamp : 'Today',
      locationOrEvent: capture.location ?? person.locationOrEvent,
      summary: capture.summary ?? capture.description,
      keyBullets: entities?.keyPoints ?? const [],
      targetRoute: '/person/${person.id}',
    );

    final memoryItem = MemoryItem(
      id: 'mem_cap_${capture.id}',
      category: 'Interaction Context',
      text: capture.summary ?? capture.description,
      source: capture.type.label,
      timestamp: capture.timestamp,
    );

    final profile = PersonProfile(
      id: person.id,
      name: person.name,
      role: person.role,
      company: person.company,
      location: person.locationOrEvent ?? '',
      initials: person.initials,
      relationshipType: person.relationshipType ?? RelationshipContextType.collaborator,
      relationshipStrength: 'Active Collaborator',
      firstMet: 'Recent Capture',
      lastInteraction: capture.timestamp.isNotEmpty ? capture.timestamp : 'Today',
      totalInteractions: 2,
      sharedEventsCount: 0,
      aiSummary: 'Profile active with enriched interaction memories.',
      timeline: [timelineItem],
      memories: [memoryItem],
    );

    return RelationshipMemoryResult(
      personId: person.id,
      captureId: capture.id,
      status: RelationshipMemoryStatus.completed,
      createdTimelineItem: timelineItem,
      createdMemories: [memoryItem],
      updatedProfile: profile,
      processedAt: DateTime.now(),
    );
  }
}