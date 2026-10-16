import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/data/firestore/firestore_person_detail_repository.dart';
import 'package:recaller/data/mock/mock_activity_repository.dart';
import 'package:recaller/data/mock/mock_follow_up_repository.dart';
import 'package:recaller/data/mock/mock_people_repository.dart';
import 'package:recaller/data/mock/mock_person_detail_repository.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/models/entity_resolution_models.dart';
import 'package:recaller/features/capture/models/ocr_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/models/relationship_memory_models.dart';
import 'package:recaller/services/entity_resolution_service.dart';
import 'package:recaller/services/mock_relationship_memory_service.dart';
import 'package:recaller/services/relationship_memory_service.dart';

void main() {
  group('Phase 13D-06: Relationship Memory Domain Models & Serialization Tests', () {
    test('1. RelationshipMemoryUpdate serializes and deserializes symmetrically', () {
      final timeline = TimelineItem(
        id: 'tl_test_1',
        type: TimelineType.cardScan,
        title: 'Card Scanned: Sarah Chen',
        subtitle: 'Mosaic Neuromorphic',
        date: 'Today',
        summary: 'Met at Stanford Tech Summit.',
        keyBullets: ['Synaptic crossbars', 'Silicon photonics'],
      );

      final memory = MemoryItem(
        id: 'mem_test_1',
        category: 'Capabilities & Focus',
        text: 'Key focus areas: Synaptic crossbars, Silicon photonics',
        source: 'Business Card · Today',
      );

      final update = RelationshipMemoryUpdate(
        personId: 'per_sarah_01',
        captureId: 'cap_01',
        activityId: 'act_cap_01',
        timelineItem: timeline,
        memories: [memory],
        newCapabilities: ['Synaptic crossbars', 'Silicon photonics'],
        relationshipStrength: 'Strong Connection',
        totalInteractions: 5,
        lastInteraction: 'Today at 4:00 PM',
      );

      final map = update.toMap();
      expect(map['personId'], equals('per_sarah_01'));
      expect(map['captureId'], equals('cap_01'));
      expect(map['totalInteractions'], equals(5));

      final restored = RelationshipMemoryUpdate.fromMap(map);
      expect(restored.personId, equals('per_sarah_01'));
      expect(restored.captureId, equals('cap_01'));
      expect(restored.timelineItem?.title, equals('Card Scanned: Sarah Chen'));
      expect(restored.memories.length, equals(1));
      expect(restored.memories.first.category, equals('Capabilities & Focus'));
      expect(restored.newCapabilities, contains('Synaptic crossbars'));
    });

    test('2. RelationshipMemoryResult serializes and deserializes cleanly', () {
      final now = DateTime(2026, 8, 28, 14, 0);
      final result = RelationshipMemoryResult(
        personId: 'per_sarah_01',
        captureId: 'cap_01',
        status: RelationshipMemoryStatus.completed,
        processedAt: now,
      );

      final map = result.toMap();
      expect(map['personId'], equals('per_sarah_01'));
      expect(map['status'], equals('completed'));

      final restored = RelationshipMemoryResult.fromMap(map);
      expect(restored.personId, equals('per_sarah_01'));
      expect(restored.status, equals(RelationshipMemoryStatus.completed));
      expect(restored.isSuccessful, isTrue);
    });
  });

  group('Phase 13D-06: Deterministic Relationship Memory Service Tests', () {
    late MockPersonDetailRepository personDetailRepo;
    late MockFollowUpRepository followUpRepo;
    late MockPeopleRepository peopleRepo;
    late DeterministicRelationshipMemoryService service;

    final sarahPerson = PersonItem(
      id: 'per_sarah_01',
      name: 'Sarah Chen',
      role: 'VP of System Architecture',
      company: 'Mosaic Neuromorphic',
      email: 'sarah.chen@mosaic-neuro.io',
      phone: '+1 415 555 0101',
      locationOrEvent: 'San Francisco, CA',
      initials: 'SC',
    );

    setUp(() {
      personDetailRepo = MockPersonDetailRepository();
      followUpRepo = MockFollowUpRepository();
      peopleRepo = MockPeopleRepository(initialPeople: [sarahPerson]);
      service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
        followUpRepository: followUpRepo,
        peopleRepository: peopleRepo,
      );
    });

    test('3. Enriches person profile with chronological timeline item', () async {
      final capture = CaptureItem(
        id: 'cap_card_01',
        type: CaptureType.businessCard,
        title: 'Business Card: Sarah Chen',
        description: 'Scanned contact card at Hot Chips 36.',
        timestamp: 'Aug 28, 2026',
        targetRoute: '/interaction/cap_card_01',
        location: 'Cupertino, CA',
      );

      final entities = OcrExtractedEntities(
        name: 'Sarah Chen',
        role: 'VP of System Architecture',
        company: 'Mosaic Neuromorphic',
        keyPoints: ['RISC-V Synaptic Array', '40nm tapeout'],
      );

      final result = await service.enrichMemory(
        capture: capture,
        person: sarahPerson,
        entities: entities,
      );

      expect(result.status, equals(RelationshipMemoryStatus.completed));
      expect(result.createdTimelineItem, isNotNull);
      expect(result.createdTimelineItem!.id, equals('tl_cap_cap_card_01'));
      expect(result.createdTimelineItem!.type, equals(TimelineType.cardScan));
      expect(result.createdTimelineItem!.keyBullets, contains('RISC-V Synaptic Array'));

      final profile = await personDetailRepo.getProfile(sarahPerson.id);
      expect(profile, isNotNull);
      expect(profile!.timeline.any((t) => t.id == 'tl_cap_cap_card_01'), isTrue);
    });

    test('4. Timeline creation is idempotent on retry (no duplicates)', () async {
      final capture = CaptureItem(
        id: 'cap_retry_01',
        type: CaptureType.photo,
        title: 'Whiteboard Diagram',
        description: 'Synaptic array layout.',
        timestamp: 'Aug 28, 2026',
        targetRoute: '/interaction/cap_retry_01',
      );

      // Pass 1
      await service.enrichMemory(capture: capture, person: sarahPerson);
      final profilePass1 = await personDetailRepo.getProfile(sarahPerson.id);
      final countPass1 = profilePass1!.timeline.where((t) => t.id == 'tl_cap_cap_retry_01').length;
      expect(countPass1, equals(1));

      // Pass 2 (Retry)
      await service.enrichMemory(capture: capture, person: sarahPerson);
      final profilePass2 = await personDetailRepo.getProfile(sarahPerson.id);
      final countPass2 = profilePass2!.timeline.where((t) => t.id == 'tl_cap_cap_retry_01').length;
      expect(countPass2, equals(1)); // No duplicate timeline entries created!
    });

    test('5. Extracts structured memories with categories and provenance', () async {
      final capture = CaptureItem(
        id: 'cap_memo_01',
        type: CaptureType.voice,
        title: 'Voice Debrief: Foundry Partnership',
        description: 'Discussed Q4 test vehicle packaging with Sarah.',
        timestamp: 'Today at 3:30 PM',
        targetRoute: '/interaction/cap_memo_01',
      );

      final entities = OcrExtractedEntities(
        company: 'Mosaic Neuromorphic',
        email: 'sarah.chen@mosaic-neuro.io',
        keyPoints: ['TSMC CoWoS packaging', 'Thermal dissipation target < 15W'],
      );

      final result = await service.enrichMemory(
        capture: capture,
        person: sarahPerson,
        entities: entities,
      );

      expect(result.createdMemories.length, greaterThanOrEqualTo(2));
      expect(result.createdMemories.any((m) => m.category == 'Capabilities & Focus'), isTrue);
      expect(result.createdMemories.any((m) => m.category == 'Organization & Role'), isTrue);
    });

    test('6. Memory creation is idempotent on retry (no duplicate memory claims)', () async {
      final capture = CaptureItem(
        id: 'cap_mem_dup_01',
        type: CaptureType.note,
        title: 'Strategy Note',
        description: 'Aligned on compiler release cycle.',
        timestamp: 'Today',
        targetRoute: '/interaction/cap_mem_dup_01',
      );

      await service.enrichMemory(capture: capture, person: sarahPerson);
      final profile1 = await personDetailRepo.getProfile(sarahPerson.id);
      final memCount1 = profile1!.memories.length;

      await service.enrichMemory(capture: capture, person: sarahPerson);
      final profile2 = await personDetailRepo.getProfile(sarahPerson.id);
      final memCount2 = profile2!.memories.length;

      expect(memCount2, equals(memCount1)); // No duplicate memory items!
    });

    test('7. Detects first-person commitment from capture and creates FollowUpItem', () async {
      final capture = CaptureItem(
        id: 'cap_fu_01',
        type: CaptureType.voice,
        title: 'Voice Memo: Partner Alignment',
        description: "Met with Sarah. I'll send the proposal tomorrow morning with pricing tiers.",
        timestamp: 'Today',
        targetRoute: '/interaction/cap_fu_01',
      );

      final result = await service.enrichMemory(
        capture: capture,
        person: sarahPerson,
        autoCreateFollowUp: true,
      );

      expect(result.createdFollowUp, isNotNull);
      expect(result.createdFollowUp!.id, equals('fu_cap_cap_fu_01'));
      expect(result.createdFollowUp!.commitmentType, equals(CommitmentType.iPromised));
      expect(result.createdFollowUp!.dueDate, equals('Tomorrow'));
      expect(result.createdFollowUp!.personId, equals(sarahPerson.id));

      // Verify added to follow up repo
      final repoItem = await followUpRepo.getFollowUp('fu_cap_cap_fu_01');
      expect(repoItem, isNotNull);
      expect(repoItem!.title, contains('Sarah Chen'));
    });

    test('8. Detects third-person commitment from capture and creates FollowUpItem', () async {
      final capture = CaptureItem(
        id: 'cap_fu_02',
        type: CaptureType.note,
        title: 'Meeting Takeaway',
        description: 'Discussed evaluation criteria. Sarah promised to send updated NDA draft by Friday.',
        timestamp: 'Today',
        targetRoute: '/interaction/cap_fu_02',
      );

      final result = await service.enrichMemory(
        capture: capture,
        person: sarahPerson,
        autoCreateFollowUp: true,
      );

      expect(result.createdFollowUp, isNotNull);
      expect(result.createdFollowUp!.commitmentType, equals(CommitmentType.theyPromised));
      expect(result.createdFollowUp!.dueDate, equals('This Friday'));
    });

    test('9. Ambiguous text without explicit commitment verbs does NOT create follow-up', () async {
      final capture = CaptureItem(
        id: 'cap_no_fu',
        type: CaptureType.photo,
        title: 'Coffee Encounter',
        description: 'Great catching up on industry news and semiconductor foundry trends.',
        timestamp: 'Today',
        targetRoute: '/interaction/cap_no_fu',
      );

      final result = await service.enrichMemory(
        capture: capture,
        person: sarahPerson,
        autoCreateFollowUp: true,
      );

      expect(result.createdFollowUp, isNull);
    });

    test('10. Correctly computes deterministic relationship strength tiers based on interactions', () async {
      final capture = CaptureItem(
        id: 'cap_tier_01',
        type: CaptureType.note,
        title: 'Note',
        description: 'Meeting context.',
        timestamp: 'Today',
        targetRoute: '/interaction/cap_tier_01',
      );

      final res = await service.enrichMemory(capture: capture, person: sarahPerson);
      expect(res.updatedProfile, isNotNull);
      expect(res.updatedProfile!.relationshipStrength, isNotEmpty);
    });
  });

  group('Phase 13D-06: MockRelationshipMemoryService Tests', () {
    test('11. Mock service returns completed result and counts enrichCalls', () async {
      final mockService = MockRelationshipMemoryService();
      final capture = CaptureItem(
        id: 'cap_mock_01',
        type: CaptureType.note,
        title: 'Note',
        description: 'Desc',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final person = PersonItem(
        id: 'p1',
        name: 'Alex Rivera',
        role: 'Founder',
        company: 'Synapse AI',
        initials: 'AR',
      );

      final result = await mockService.enrichMemory(capture: capture, person: person);
      expect(mockService.enrichCalls, equals(1));
      expect(result.status, equals(RelationshipMemoryStatus.completed));
      expect(result.createdTimelineItem, isNotNull);
    });

    test('12. Mock service throws when shouldFail is true', () async {
      final mockService = MockRelationshipMemoryService(shouldFail: true);
      final capture = CaptureItem(
        id: 'cap_mock_02',
        type: CaptureType.note,
        title: 'Note',
        description: 'Desc',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final person = PersonItem(
        id: 'p1',
        name: 'Alex Rivera',
        role: 'Founder',
        company: 'Synapse AI',
        initials: 'AR',
      );

      expect(
        () => mockService.enrichMemory(capture: capture, person: person),
        throwsA(isA<RecallrDataException>()),
      );
    });
  });

  group('Phase 13D-06: FirestorePersonDetailRepository Unauthenticated Fail-Closed Tests', () {
    test('13. FirestorePersonDetailRepository throws unauthenticated on enrichRelationshipMemory when logged out', () async {
      final repo = FirestorePersonDetailRepository();
      final update = RelationshipMemoryUpdate(
        personId: 'per_01',
        captureId: 'cap_01',
      );

      expect(
        () => repo.enrichRelationshipMemory(personId: 'per_01', update: update),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('14. FirestorePersonDetailRepository throws unauthenticated on updateRelationshipStats when logged out', () async {
      final repo = FirestorePersonDetailRepository();
      expect(
        () => repo.updateRelationshipStats('per_01', totalInteractions: 3),
        throwsA(isA<RecallrDataException>()),
      );
    });
  });

  group('Phase 13D-06: End-to-End Pipeline Integration Tests', () {
    test('15. Full pipeline: Capture -> Resolve Person -> Create Activity -> Enrich Memory -> Timeline in Profile', () async {
      final peopleRepo = MockPeopleRepository();
      final activityRepo = MockActivityRepository();
      final personDetailRepo = MockPersonDetailRepository();
      final followUpRepo = MockFollowUpRepository();

      final relMemoryService = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
        followUpRepository: followUpRepo,
        peopleRepository: peopleRepo,
      );

      final resolutionService = DeterministicEntityResolutionService(
        peopleRepository: peopleRepo,
        activityRepository: activityRepo,
        relationshipMemoryService: relMemoryService,
      );

      final capture = CaptureItem(
        id: 'cap_e2e_01',
        type: CaptureType.businessCard,
        title: 'Scanned Card',
        description: 'Meeting at conference. I will send the proposal by Friday.',
        timestamp: 'Aug 28, 2026',
        targetRoute: '/interaction/cap_e2e_01',
      );

      final entities = OcrExtractedEntities(
        name: 'Dr. Elena Rostova',
        role: 'Chief Scientist',
        company: 'Apex Photonics',
        email: 'elena.rostova@apex-photonics.ch',
        phone: '+41 44 632 1102',
        keyPoints: ['Photonic interconnects', 'Silicon photonics'],
      );

      // Execute entity resolution & automatic memory enrichment
      final res = await resolutionService.resolveAndLink(capture: capture, entities: entities);
      expect(res.status, equals(EntityResolutionStatus.resolvedNew));
      expect(res.matchedPersonId, isNotNull);

      // Verify Activity was created
      final activity = await activityRepo.getActivity('act_cap_cap_e2e_01');
      expect(activity, isNotNull);
      expect(activity!.personName, equals('Dr. Elena Rostova'));

      // Verify Person Profile received Timeline and Memories
      final profile = await personDetailRepo.getProfile(res.matchedPersonId!);
      expect(profile, isNotNull);
      expect(profile!.timeline.length, greaterThanOrEqualTo(1));
      expect(profile.timeline.first.id, equals('tl_cap_cap_e2e_01'));
      expect(profile.memories.length, greaterThanOrEqualTo(1));

      // Verify Follow-up was detected
      final followUp = await followUpRepo.getFollowUp('fu_cap_cap_e2e_01');
      expect(followUp, isNotNull);
      expect(followUp!.dueDate, equals('This Friday'));
    });

    test('16. Partial failure in memory service is non-destructive to entity resolution', () async {
      final peopleRepo = MockPeopleRepository();
      final activityRepo = MockActivityRepository();
      final failingMemService = MockRelationshipMemoryService(shouldFail: true);

      final resolutionService = DeterministicEntityResolutionService(
        peopleRepository: peopleRepo,
        activityRepository: activityRepo,
        relationshipMemoryService: failingMemService,
      );

      final capture = CaptureItem(
        id: 'cap_fail_soft_01',
        type: CaptureType.businessCard,
        title: 'Business Card',
        description: 'Card scan.',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final entities = OcrExtractedEntities(
        name: 'Marcus Vance',
        role: 'CTO',
        company: 'Vance Dynamics',
      );

      // Person resolution should still succeed!
      final res = await resolutionService.resolveAndLink(capture: capture, entities: entities);
      expect(res.status, equals(EntityResolutionStatus.resolvedNew));
      expect(res.resolvedPerson?.name, equals('Marcus Vance'));

      // Activity should still be created!
      final activity = await activityRepo.getActivity('act_cap_cap_fail_soft_01');
      expect(activity, isNotNull);
    });

    test('17. Multiple captures enrich timeline in reverse-chronological order', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final followUpRepo = MockFollowUpRepository();
      final peopleRepo = MockPeopleRepository();

      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
        followUpRepository: followUpRepo,
        peopleRepository: peopleRepo,
      );

      final person = PersonItem(
        id: 'per_multi_01',
        name: 'David Kim',
        role: 'Partner',
        company: 'Founders Fund',
        initials: 'DK',
      );

      final cap1 = CaptureItem(
        id: 'cap_seq_1',
        type: CaptureType.businessCard,
        title: 'Initial Encounter',
        description: 'First meeting at Summit.',
        timestamp: 'Aug 10, 2026',
        targetRoute: '/int/1',
      );

      final cap2 = CaptureItem(
        id: 'cap_seq_2',
        type: CaptureType.voice,
        title: 'Follow-up Call',
        description: 'Discussed term sheet.',
        timestamp: 'Aug 28, 2026',
        targetRoute: '/int/2',
      );

      await service.enrichMemory(capture: cap1, person: person);
      await service.enrichMemory(capture: cap2, person: person);

      final profile = await personDetailRepo.getProfile('per_multi_01');
      expect(profile, isNotNull);
      expect(profile!.timeline.first.id, equals('tl_cap_cap_seq_2')); // Most recent first
      expect(profile.timeline[1].id, equals('tl_cap_cap_seq_1')); // Second most recent
      expect(profile.totalInteractions, greaterThanOrEqualTo(2));
    });

    test('18. Capability tags are deduplicated during multiple memory updates', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(
        id: 'per_tags_01',
        name: 'Zoe Vance',
        role: 'Lead ML',
        company: 'Anthropic',
        initials: 'ZV',
      );

      final cap1 = CaptureItem(
        id: 'cap_tag_1',
        type: CaptureType.note,
        title: 'Note 1',
        description: 'Discussed RLHF.',
        timestamp: 'Today',
        targetRoute: '/int/1',
      );

      final cap2 = CaptureItem(
        id: 'cap_tag_2',
        type: CaptureType.note,
        title: 'Note 2',
        description: 'Discussed RLHF and Constitutional AI.',
        timestamp: 'Today',
        targetRoute: '/int/2',
      );

      await service.enrichMemory(
        capture: cap1,
        person: person,
        entities: OcrExtractedEntities(keyPoints: ['RLHF', 'Alignment']),
      );

      await service.enrichMemory(
        capture: cap2,
        person: person,
        entities: OcrExtractedEntities(keyPoints: ['RLHF', 'Constitutional AI']),
      );

      final profile = await personDetailRepo.getProfile('per_tags_01');
      expect(profile, isNotNull);
      expect(profile!.capabilities.where((c) => c == 'RLHF').length, equals(1)); // Deduplicated!
      expect(profile.capabilities, contains('Constitutional AI'));
    });

    test('19. Document capture maps to TimelineType.fileNote', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(id: 'p_doc', name: 'Alice', role: '', company: '', initials: 'A');
      final cap = CaptureItem(
        id: 'cap_doc_01',
        type: CaptureType.document,
        title: 'Tech Spec',
        description: 'Specs PDF',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final res = await service.enrichMemory(capture: cap, person: person);
      expect(res.createdTimelineItem?.type, equals(TimelineType.fileNote));
    });

    test('20. Voice memo capture maps to TimelineType.voiceNote', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(id: 'p_voice', name: 'Bob', role: '', company: '', initials: 'B');
      final cap = CaptureItem(
        id: 'cap_voice_01',
        type: CaptureType.voice,
        title: 'Debrief Memo',
        description: 'Voice note audio',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final res = await service.enrichMemory(capture: cap, person: person);
      expect(res.createdTimelineItem?.type, equals(TimelineType.voiceNote));
    });

    test('21. Note capture maps to TimelineType.conversation', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(id: 'p_note', name: 'Charlie', role: '', company: '', initials: 'C');
      final cap = CaptureItem(
        id: 'cap_note_01',
        type: CaptureType.note,
        title: 'Quick Chat',
        description: 'Met over coffee',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final res = await service.enrichMemory(capture: cap, person: person);
      expect(res.createdTimelineItem?.type, equals(TimelineType.conversation));
    });

    test('22. Photo capture maps to TimelineType.meeting', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(id: 'p_photo', name: 'Dana', role: '', company: '', initials: 'D');
      final cap = CaptureItem(
        id: 'cap_photo_01',
        type: CaptureType.photo,
        title: 'Whiteboard Photo',
        description: 'Architecture sync',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final res = await service.enrichMemory(capture: cap, person: person);
      expect(res.createdTimelineItem?.type, equals(TimelineType.meeting));
    });

    test('23. Update relationship stats manually with updateRelationshipStats', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final person = PersonItem(id: 'p_stat', name: 'Eve', role: '', company: '', initials: 'E');
      final cap = CaptureItem(
        id: 'cap_stat_01',
        type: CaptureType.note,
        title: 'Note',
        description: 'Desc',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      await service.enrichMemory(capture: cap, person: person);
      await personDetailRepo.updateRelationshipStats(
        'p_stat',
        relationshipStrength: 'Core Network / High Trust',
        sharedEventsCount: 3,
      );

      final profile = await personDetailRepo.getProfile('p_stat');
      expect(profile?.relationshipStrength, equals('Core Network / High Trust'));
      expect(profile?.sharedEventsCount, equals(3));
    });

    test('24. FollowUp detection parses "email the deck" keyword', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(id: 'p_deck', name: 'Frank', role: '', company: '', initials: 'F');
      final cap = CaptureItem(
        id: 'cap_deck_01',
        type: CaptureType.note,
        title: 'Deck Request',
        description: 'Agreed to email the deck by Monday.',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final res = await service.enrichMemory(capture: cap, person: person);
      expect(res.createdFollowUp, isNotNull);
      expect(res.createdFollowUp?.dueDate, equals('Next Monday'));
      expect(res.createdFollowUp?.commitmentType, equals(CommitmentType.iPromised));
    });

    test('25. FollowUp detection parses "schedule another meeting" keyword', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(id: 'p_sched', name: 'Grace', role: '', company: '', initials: 'G');
      final cap = CaptureItem(
        id: 'cap_sched_01',
        type: CaptureType.voice,
        title: 'Meeting wrap',
        description: 'Great discussion. Will schedule another meeting next week.',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final res = await service.enrichMemory(capture: cap, person: person);
      expect(res.createdFollowUp, isNotNull);
      expect(res.createdFollowUp?.dueDate, equals('Next Week'));
    });

    test('26. FollowUp detection handles "they will follow up" properly', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(id: 'p_tfu', name: 'Harry', role: '', company: '', initials: 'H');
      final cap = CaptureItem(
        id: 'cap_tfu_01',
        type: CaptureType.note,
        title: 'Meeting Note',
        description: 'Harry mentioned they will follow up by end of week with benchmarks.',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final res = await service.enrichMemory(capture: cap, person: person);
      expect(res.createdFollowUp, isNotNull);
      expect(res.createdFollowUp?.commitmentType, equals(CommitmentType.theyPromised));
      expect(res.createdFollowUp?.dueDate, equals('End of Week'));
    });

    test('27. Memory claims include contact coordinates when available', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(id: 'p_contact', name: 'Iris', role: '', company: '', initials: 'I');
      final cap = CaptureItem(
        id: 'cap_contact_01',
        type: CaptureType.businessCard,
        title: 'Card Scan',
        description: 'Card',
        timestamp: 'Today',
        targetRoute: '/int',
      );

      final entities = OcrExtractedEntities(
        role: 'Director of AI',
        company: 'Cohere',
        email: 'iris@cohere.com',
        phone: '+1 415 888 9999',
      );

      final res = await service.enrichMemory(capture: cap, person: person, entities: entities);
      expect(res.createdMemories.any((m) => m.category == 'Organization & Role'), isTrue);
      final orgMem = res.createdMemories.firstWhere((m) => m.category == 'Organization & Role');
      expect(orgMem.text, contains('Cohere'));
      expect(orgMem.text, contains('Director of AI'));
      expect(orgMem.text, contains('iris@cohere.com'));
    });

    test('28. RelationshipMemoryStatus extension provides clean user-facing labels', () {
      expect(RelationshipMemoryStatus.pending.label, contains('Pending'));
      expect(RelationshipMemoryStatus.enriching.label, contains('Building'));
      expect(RelationshipMemoryStatus.completed.label, contains('Updated'));
      expect(RelationshipMemoryStatus.failed.label, contains('Failed'));
      expect(RelationshipMemoryStatus.skipped.label, contains('Skipped'));
    });

    test('29. Empty capture details fall back gracefully to default encounter summary', () async {
      final personDetailRepo = MockPersonDetailRepository();
      final service = DeterministicRelationshipMemoryService(
        personDetailRepository: personDetailRepo,
      );

      final person = PersonItem(id: 'p_empty', name: 'Jack', role: '', company: '', initials: 'J');
      final cap = CaptureItem(
        id: 'cap_empty_01',
        type: CaptureType.note,
        title: '',
        description: '',
        timestamp: '',
        targetRoute: '/int',
      );

      final res = await service.enrichMemory(capture: cap, person: person);
      expect(res.status, equals(RelationshipMemoryStatus.completed));
      expect(res.createdTimelineItem?.title, equals('Captured Encounter: Jack'));
      expect(res.createdTimelineItem?.date, equals('Today'));
    });

    test('30. Profile copyWith creates updated instance with modified relationship properties', () {
      final initial = PersonProfile(
        id: 'p_copy',
        name: 'Kathy',
        role: 'Engineer',
        company: 'Stripe',
        location: 'SF',
        initials: 'K',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Emerging',
        firstMet: 'Today',
        lastInteraction: 'Today',
        totalInteractions: 1,
        sharedEventsCount: 0,
        aiSummary: 'Summary',
      );

      final updated = initial.copyWith(
        relationshipStrength: 'Strong Connection',
        totalInteractions: 5,
        sharedEventsCount: 2,
      );

      expect(updated.id, equals('p_copy'));
      expect(updated.relationshipStrength, equals('Strong Connection'));
      expect(updated.totalInteractions, equals(5));
      expect(updated.sharedEventsCount, equals(2));
    });
  });
}