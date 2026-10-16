import 'dart:async';
import '../features/activity/models/activity_models.dart';
import '../features/capture/models/capture_models.dart';
import '../features/capture/models/entity_resolution_models.dart';
import '../features/capture/models/ocr_models.dart';
import '../features/people/models/person_item.dart';
import '../repositories/activity_repository.dart';
import '../repositories/people_repository.dart';

import 'relationship_memory_service.dart';

/// Abstract contract for resolving captured entities to canonical People and Relationship records.
abstract class EntityResolutionService {
  Future<EntityResolutionResult> resolveAndLink({
    required CaptureItem capture,
    required OcrExtractedEntities entities,
    bool autoCreatePerson = true,
    bool autoLinkActivity = true,
  });
}

/// Deterministic, production-ready implementation of EntityResolutionService.
/// Resolves extracted people against canonical network directory without external AI dependencies.
class DeterministicEntityResolutionService implements EntityResolutionService {
  final PeopleRepository peopleRepository;
  final ActivityRepository? activityRepository;
  final RelationshipMemoryService? relationshipMemoryService;
  final Duration simulatedLatency;

  const DeterministicEntityResolutionService({
    required this.peopleRepository,
    this.activityRepository,
    this.relationshipMemoryService,
    this.simulatedLatency = Duration.zero,
  });

  @override
  Future<EntityResolutionResult> resolveAndLink({
    required CaptureItem capture,
    required OcrExtractedEntities entities,
    bool autoCreatePerson = true,
    bool autoLinkActivity = true,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    final extractedMap = entities.toMap();
    final conflicts = <EntityConflict>[];
    final matchedFields = <String>[];

    // Signal 1: Explicit ID on capture
    if (capture.personId != null && capture.personId!.isNotEmpty) {
      final existing = await peopleRepository.getPerson(capture.personId!);
      if (existing != null) {
        matchedFields.add('personId');
        final enriched = await _enrichExistingPerson(existing, entities, conflicts);
        final activityId = autoLinkActivity ? await _linkActivity(capture, enriched) : null;
        await _triggerRelationshipMemoryEnrichment(capture, enriched, activityId, entities);
        return EntityResolutionResult(
          matchedPersonId: existing.id,
          matchType: EntityMatchType.explicitId,
          status: EntityResolutionStatus.resolvedExisting,
          confidence: 1.0,
          resolvedPerson: enriched,
          matchedFields: matchedFields,
          extractedFields: extractedMap,
          conflicts: conflicts,
          createdActivityId: activityId,
          resolvedAt: DateTime.now(),
        );
      }
    }

    // Signal 2: Exact Email Match
    if (entities.email != null && entities.email!.trim().isNotEmpty) {
      final existing = await peopleRepository.findPersonByEmail(entities.email!);
      if (existing != null) {
        matchedFields.add('email');
        final enriched = await _enrichExistingPerson(existing, entities, conflicts);
        final activityId = autoLinkActivity ? await _linkActivity(capture, enriched) : null;
        await _triggerRelationshipMemoryEnrichment(capture, enriched, activityId, entities);
        return EntityResolutionResult(
          matchedPersonId: existing.id,
          matchType: EntityMatchType.exactEmail,
          status: EntityResolutionStatus.resolvedExisting,
          confidence: 0.99,
          resolvedPerson: enriched,
          matchedFields: matchedFields,
          extractedFields: extractedMap,
          conflicts: conflicts,
          createdActivityId: activityId,
          resolvedAt: DateTime.now(),
        );
      }
    }

    // Signal 3: Exact Phone Match
    if (entities.phone != null && entities.phone!.trim().isNotEmpty) {
      final existing = await peopleRepository.findPersonByPhone(entities.phone!);
      if (existing != null) {
        matchedFields.add('phone');
        final enriched = await _enrichExistingPerson(existing, entities, conflicts);
        final activityId = autoLinkActivity ? await _linkActivity(capture, enriched) : null;
        await _triggerRelationshipMemoryEnrichment(capture, enriched, activityId, entities);
        return EntityResolutionResult(
          matchedPersonId: existing.id,
          matchType: EntityMatchType.exactPhone,
          status: EntityResolutionStatus.resolvedExisting,
          confidence: 0.96,
          resolvedPerson: enriched,
          matchedFields: matchedFields,
          extractedFields: extractedMap,
          conflicts: conflicts,
          createdActivityId: activityId,
          resolvedAt: DateTime.now(),
        );
      }
    }

    // Signal 4: Strong Name + Company Match
    final candidateName = entities.name ?? capture.personName;
    final candidateCompany = entities.company ?? capture.companyName;

    if (candidateName != null && candidateName.trim().isNotEmpty &&
        candidateCompany != null && candidateCompany.trim().isNotEmpty) {
      final matches = await peopleRepository.findCandidatesByNameAndCompany(
        candidateName,
        candidateCompany,
      );
      if (matches.length == 1) {
        final existing = matches.first;
        matchedFields.addAll(['name', 'company']);
        final enriched = await _enrichExistingPerson(existing, entities, conflicts);
        final activityId = autoLinkActivity ? await _linkActivity(capture, enriched) : null;
        await _triggerRelationshipMemoryEnrichment(capture, enriched, activityId, entities);
        return EntityResolutionResult(
          matchedPersonId: existing.id,
          matchType: EntityMatchType.strongNameCompany,
          status: EntityResolutionStatus.resolvedExisting,
          confidence: 0.93,
          resolvedPerson: enriched,
          matchedFields: matchedFields,
          extractedFields: extractedMap,
          conflicts: conflicts,
          createdActivityId: activityId,
          resolvedAt: DateTime.now(),
        );
      } else if (matches.length > 1) {
        // Multiple matches with same name & company -> Requires Review
        final candidates = matches
            .map((p) => EntityResolutionCandidate(
                  personId: p.id,
                  person: p,
                  matchType: EntityMatchType.ambiguous,
                  confidence: 0.70,
                  matchedFields: ['name', 'company'],
                ))
            .toList();
        return EntityResolutionResult(
          matchType: EntityMatchType.ambiguous,
          status: EntityResolutionStatus.requiresReview,
          confidence: 0.65,
          requiresReview: true,
          candidates: candidates,
          matchedFields: ['name', 'company'],
          extractedFields: extractedMap,
          resolvedAt: DateTime.now(),
        );
      }
    }

    // Signal 5: Contextual Name Match
    if (candidateName != null && candidateName.trim().isNotEmpty) {
      final nameMatches = await peopleRepository.findCandidatesByName(candidateName);
      if (nameMatches.length == 1) {
        final existing = nameMatches.first;
        matchedFields.add('name');
        final enriched = await _enrichExistingPerson(existing, entities, conflicts);
        final activityId = autoLinkActivity ? await _linkActivity(capture, enriched) : null;
        await _triggerRelationshipMemoryEnrichment(capture, enriched, activityId, entities);
        return EntityResolutionResult(
          matchedPersonId: existing.id,
          matchType: EntityMatchType.contextualName,
          status: EntityResolutionStatus.resolvedExisting,
          confidence: 0.85,
          resolvedPerson: enriched,
          matchedFields: matchedFields,
          extractedFields: extractedMap,
          conflicts: conflicts,
          createdActivityId: activityId,
          resolvedAt: DateTime.now(),
        );
      } else if (nameMatches.length > 1) {
        // Ambiguous multiple people with same name -> Never auto-merge!
        final candidates = nameMatches
            .map((p) => EntityResolutionCandidate(
                  personId: p.id,
                  person: p,
                  matchType: EntityMatchType.ambiguous,
                  confidence: 0.50,
                  matchedFields: ['name'],
                ))
            .toList();
        return EntityResolutionResult(
          matchType: EntityMatchType.ambiguous,
          status: EntityResolutionStatus.requiresReview,
          confidence: 0.50,
          requiresReview: true,
          candidates: candidates,
          matchedFields: ['name'],
          extractedFields: extractedMap,
          resolvedAt: DateTime.now(),
        );
      }
    }

    // Signal 6: No Match Found -> Create New Person if requested and name is present
    if (autoCreatePerson && candidateName != null && candidateName.trim().isNotEmpty) {
      final newPerson = PersonItem(
        id: 'per_cap_${capture.id}',
        name: candidateName.trim(),
        role: entities.role ?? capture.personRole ?? '',
        company: candidateCompany ?? '',
        email: entities.email,
        phone: entities.phone,
        locationOrEvent: entities.location ?? capture.location,
        contextSnippet: 'Captured via ${capture.type.label} on ${capture.timestamp}',
        lastInteraction: 'Captured ${capture.title}',
        lastInteractionDate: DateTime.now(),
        initials: PersonItem.computeInitials(candidateName),
        capabilities: entities.keyPoints.take(3).toList(),
        relationshipType: RelationshipContextType.collaborator,
      );

      final created = await peopleRepository.createPersonFromCapture(newPerson);
      final activityId = autoLinkActivity ? await _linkActivity(capture, created) : null;
      await _triggerRelationshipMemoryEnrichment(capture, created, activityId, entities);

      return EntityResolutionResult(
        matchedPersonId: created.id,
        matchType: EntityMatchType.none,
        status: EntityResolutionStatus.resolvedNew,
        confidence: 0.90,
        isNewPerson: true,
        resolvedPerson: created,
        matchedFields: const [],
        extractedFields: extractedMap,
        createdActivityId: activityId,
        resolvedAt: DateTime.now(),
      );
    }

    // Skipped / No Name Detected
    return EntityResolutionResult(
      matchType: EntityMatchType.none,
      status: EntityResolutionStatus.skipped,
      confidence: 0.0,
      extractedFields: extractedMap,
      resolvedAt: DateTime.now(),
    );
  }

  Future<void> _triggerRelationshipMemoryEnrichment(
    CaptureItem capture,
    PersonItem person,
    String? activityId,
    OcrExtractedEntities entities,
  ) async {
    if (relationshipMemoryService == null) return;
    try {
      await relationshipMemoryService!.enrichMemory(
        capture: capture,
        person: person,
        entities: entities,
      );
    } catch (_) {}
  }

  Future<PersonItem> _enrichExistingPerson(
    PersonItem existing,
    OcrExtractedEntities incoming,
    List<EntityConflict> conflicts,
  ) async {
    final updates = <String, dynamic>{};

    // Safe enrichment: fill missing fields only
    if (existing.email == null && incoming.email != null) {
      updates['email'] = incoming.email;
    } else if (existing.email != null && incoming.email != null &&
        existing.email!.toLowerCase() != incoming.email!.toLowerCase()) {
      conflicts.add(EntityConflict(
        fieldName: 'email',
        existingValue: existing.email,
        incomingValue: incoming.email,
        confidence: 0.8,
      ));
    }

    if (existing.phone == null && incoming.phone != null) {
      updates['phone'] = incoming.phone;
    }

    if (existing.role.isEmpty && incoming.role != null) {
      updates['role'] = incoming.role;
    }

    if (existing.company.isEmpty && incoming.company != null) {
      updates['company'] = incoming.company;
    } else if (existing.company.isNotEmpty && incoming.company != null &&
        !existing.company.toLowerCase().contains(incoming.company!.toLowerCase()) &&
        !incoming.company!.toLowerCase().contains(existing.company.toLowerCase())) {
      conflicts.add(EntityConflict(
        fieldName: 'company',
        existingValue: existing.company,
        incomingValue: incoming.company,
        confidence: 0.6,
      ));
    }

    if (existing.locationOrEvent == null && incoming.location != null) {
      updates['locationOrEvent'] = incoming.location;
    }

    updates['lastInteraction'] = 'Updated via capture interaction';
    updates['lastInteractionDate'] = DateTime.now();

    if (incoming.keyPoints.isNotEmpty) {
      updates['capabilities'] = incoming.keyPoints.take(2).toList();
    }

    return peopleRepository.enrichPerson(existing.id, updates);
  }

  Future<String?> _linkActivity(CaptureItem capture, PersonItem person) async {
    if (activityRepository == null) return null;

    final activityId = 'act_cap_${capture.id}';
    final existingActivity = await activityRepository!.getActivity(activityId);
    if (existingActivity != null) {
      return existingActivity.id;
    }

    final activity = ActivityItem(
      id: activityId,
      type: _mapCaptureTypeToActivity(capture.type),
      period: TimelinePeriod.today,
      timestamp: capture.timestamp.isNotEmpty ? capture.timestamp : 'Just now',
      title: capture.title.isNotEmpty ? capture.title : 'Captured Encounter: ${person.name}',
      summary: capture.summary ?? capture.description,
      personName: person.name,
      personId: person.id,
      companyName: person.company.isNotEmpty ? person.company : capture.companyName,
      location: person.locationOrEvent ?? capture.location,
      targetRoute: '/person/${person.id}',
      actionLabel: 'View Dossier',
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await activityRepository!.addActivity(activity);
    return activity.id;
  }

  ActivityType _mapCaptureTypeToActivity(CaptureType type) {
    switch (type) {
      case CaptureType.businessCard:
        return ActivityType.capture;
      case CaptureType.voice:
        return ActivityType.call;
      case CaptureType.note:
        return ActivityType.note;
      case CaptureType.photo:
        return ActivityType.encounter;
      case CaptureType.document:
        return ActivityType.file;
    }
  }
}