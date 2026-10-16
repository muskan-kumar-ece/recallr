import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/data/firestore/firestore_people_repository.dart';
import 'package:recaller/data/mock/mock_activity_repository.dart';
import 'package:recaller/data/mock/mock_people_repository.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/models/capture_processing_models.dart';
import 'package:recaller/features/capture/models/entity_resolution_models.dart';
import 'package:recaller/features/capture/models/ocr_models.dart';
import 'package:recaller/features/capture/widgets/capture_success_view.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/services/capture_processing_service.dart';
import 'package:recaller/services/entity_resolution_service.dart';
import 'package:recaller/services/mock_entity_resolution_service.dart';

void main() {
  group('Phase 13D-05: Entity Resolution Domain Models Tests', () {
    test('1. EntityResolutionResult serializes and deserializes symmetrically', () {
      final now = DateTime(2026, 8, 28, 12, 0);
      final person = PersonItem(
        id: 'per_test_1',
        name: 'Sarah Chen',
        role: 'VP of System Architecture',
        company: 'Mosaic Neuromorphic',
        email: 'sarah.chen@mosaic-neuro.io',
        phone: '+1 415 555 0188',
        initials: 'SC',
      );

      final candidate = EntityResolutionCandidate(
        personId: 'per_test_1',
        person: person,
        matchType: EntityMatchType.strongNameCompany,
        confidence: 0.93,
        matchedFields: ['name', 'company'],
      );

      final conflict = EntityConflict(
        fieldName: 'company',
        existingValue: 'Mosaic Neuromorphic',
        incomingValue: 'Mosaic Neuro Inc',
        confidence: 0.7,
      );

      final result = EntityResolutionResult(
        matchedPersonId: 'per_test_1',
        matchType: EntityMatchType.strongNameCompany,
        status: EntityResolutionStatus.resolvedExisting,
        confidence: 0.93,
        isNewPerson: false,
        requiresReview: false,
        resolvedPerson: person,
        candidates: [candidate],
        conflicts: [conflict],
        matchedFields: ['name', 'company'],
        extractedFields: {'name': 'Sarah Chen', 'company': 'Mosaic Neuromorphic'},
        createdActivityId: 'act_cap_123',
        resolvedAt: now,
      );

      final map = result.toMap();
      expect(map['matchedPersonId'], equals('per_test_1'));
      expect(map['matchType'], equals('strongNameCompany'));
      expect(map['status'], equals('resolvedExisting'));
      expect(map['confidence'], equals(0.93));
      expect(map['isNewPerson'], isFalse);

      final restored = EntityResolutionResult.fromMap(map);
      expect(restored.matchedPersonId, equals('per_test_1'));
      expect(restored.matchType, equals(EntityMatchType.strongNameCompany));
      expect(restored.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(restored.resolvedPerson?.name, equals('Sarah Chen'));
      expect(restored.candidates.length, equals(1));
      expect(restored.candidates.first.personId, equals('per_test_1'));
      expect(restored.conflicts.length, equals(1));
      expect(restored.conflicts.first.fieldName, equals('company'));
      expect(restored.createdActivityId, equals('act_cap_123'));
    });

    test('2. EntityConflict formatting and string representations', () {
      final conflict = EntityConflict(
        fieldName: 'email',
        existingValue: 'old@example.com',
        incomingValue: 'new@example.com',
      );
      expect(conflict.toString(), contains('email'));
      expect(conflict.toString(), contains('old@example.com'));
      expect(conflict.toString(), contains('new@example.com'));
    });

    test('3. CaptureItem with entity resolution fields roundtrips correctly', () {
      final capture = CaptureItem(
        id: 'cap_res_101',
        type: CaptureType.businessCard,
        title: 'Business Card: Sarah Chen',
        description: 'VP Architecture at Mosaic',
        timestamp: 'Today at 2:30 PM',
        targetRoute: '/interaction/cap_res_101',
        resolvedPersonId: 'per_sarah_c',
        entityResolutionStatus: 'resolvedExisting',
        entityResolutionConfidence: 0.95,
        entityResolutionAt: DateTime(2026, 8, 28),
        entityResolutionSource: 'Omni-Capture Intelligence',
        linkedActivityId: 'act_cap_101',
      );

      final map = capture.toMap();
      expect(map['resolvedPersonId'], equals('per_sarah_c'));
      expect(map['entityResolutionStatus'], equals('resolvedExisting'));
      expect(map['linkedActivityId'], equals('act_cap_101'));

      final restored = CaptureItem.fromMap(map);
      expect(restored.resolvedPersonId, equals('per_sarah_c'));
      expect(restored.entityResolutionStatus, equals('resolvedExisting'));
      expect(restored.linkedActivityId, equals('act_cap_101'));
      expect(restored.entityResolutionConfidence, equals(0.95));
    });
  });

  group('Phase 13D-05: Deterministic Entity Resolution Service Tests', () {
    late MockPeopleRepository peopleRepo;
    late MockActivityRepository activityRepo;
    late DeterministicEntityResolutionService service;

    final existingSarah = PersonItem(
      id: 'per_sarah_01',
      name: 'Sarah Chen',
      role: 'VP of Architecture',
      company: 'Mosaic Neuromorphic',
      email: 'sarah.chen@mosaic-neuro.io',
      phone: '+1 415 555 0101',
      initials: 'SC',
    );

    final existingElena = PersonItem(
      id: 'per_elena_02',
      name: 'Elena Rostova',
      role: 'Chief Scientist',
      company: 'Apex Photonics',
      email: 'elena.rostova@apex-photonics.ch',
      phone: '+41 44 632 1102',
      initials: 'ER',
    );

    setUp(() {
      peopleRepo = MockPeopleRepository(initialPeople: [existingSarah, existingElena]);
      activityRepo = MockActivityRepository();
      service = DeterministicEntityResolutionService(
        peopleRepository: peopleRepo,
        activityRepository: activityRepo,
      );
    });

    test('4. Resolves by explicit personId with confidence 1.0', () async {
      final capture = CaptureItem(
        id: 'cap_01',
        type: CaptureType.note,
        title: 'Meeting Note',
        description: 'Discussed roadmaps',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_01',
        personId: 'per_sarah_01',
      );

      final entities = OcrExtractedEntities(name: 'Sarah Chen');
      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(result.matchedPersonId, equals('per_sarah_01'));
      expect(result.confidence, equals(1.0));
      expect(result.matchType, equals(EntityMatchType.explicitId));
      expect(result.matchedFields, contains('personId'));
    });

    test('5. Resolves by exact email match (case-insensitive) with confidence 0.99', () async {
      final capture = CaptureItem(
        id: 'cap_02',
        type: CaptureType.businessCard,
        title: 'Scanned Card',
        description: 'Card scan',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_02',
      );

      final entities = OcrExtractedEntities(
        name: 'Sarah Chen',
        email: 'SARAH.CHEN@MOSAIC-NEURO.IO',
      );

      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(result.matchedPersonId, equals('per_sarah_01'));
      expect(result.confidence, equals(0.99));
      expect(result.matchType, equals(EntityMatchType.exactEmail));
      expect(result.matchedFields, contains('email'));
    });

    test('6. Resolves by exact phone match (normalized digits) with confidence 0.96', () async {
      final capture = CaptureItem(
        id: 'cap_03',
        type: CaptureType.businessCard,
        title: 'Card',
        description: 'Card',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_03',
      );

      final entities = OcrExtractedEntities(
        name: 'Elena',
        phone: '+41 (44) 632-1102',
      );

      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(result.matchedPersonId, equals('per_elena_02'));
      expect(result.confidence, equals(0.96));
      expect(result.matchType, equals(EntityMatchType.exactPhone));
      expect(result.matchedFields, contains('phone'));
    });

    test('7. Resolves by Strong Name + Company match with confidence 0.93', () async {
      final capture = CaptureItem(
        id: 'cap_04',
        type: CaptureType.photo,
        title: 'Whiteboard',
        description: 'Notes',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_04',
      );

      final entities = OcrExtractedEntities(
        name: 'Sarah Chen',
        company: 'Mosaic Neuromorphic',
      );

      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(result.matchedPersonId, equals('per_sarah_01'));
      expect(result.confidence, equals(0.93));
      expect(result.matchType, equals(EntityMatchType.strongNameCompany));
      expect(result.matchedFields, containsAll(['name', 'company']));
    });

    test('8. Resolves by Contextual Name match when single unique match exists', () async {
      final capture = CaptureItem(
        id: 'cap_05',
        type: CaptureType.note,
        title: 'Note',
        description: 'Meeting',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_05',
      );

      final entities = OcrExtractedEntities(name: 'Elena Rostova');
      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(result.matchedPersonId, equals('per_elena_02'));
      expect(result.confidence, equals(0.85));
      expect(result.matchType, equals(EntityMatchType.contextualName));
    });

    test('9. Ambiguous Name Match with multiple candidates does NOT merge and sets requiresReview', () async {
      // Add another Sarah Chen
      await peopleRepo.addPerson(PersonItem(
        id: 'per_sarah_other',
        name: 'Sarah Chen',
        role: 'Marketing Director',
        company: 'Global Media Labs',
        initials: 'SC',
      ));

      final capture = CaptureItem(
        id: 'cap_06',
        type: CaptureType.note,
        title: 'Sarah note',
        description: 'Chat with Sarah',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_06',
      );

      final entities = OcrExtractedEntities(name: 'Sarah Chen');
      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.requiresReview));
      expect(result.requiresReview, isTrue);
      expect(result.matchType, equals(EntityMatchType.ambiguous));
      expect(result.candidates.length, equals(2));
      expect(result.matchedPersonId, isNull);
    });

    test('10. No match creates new PersonItem deterministically when name is present', () async {
      final capture = CaptureItem(
        id: 'cap_07',
        type: CaptureType.businessCard,
        title: 'Dr. Marcus Vance Card',
        description: 'Card',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_07',
      );

      final entities = OcrExtractedEntities(
        name: 'Marcus Vance',
        role: 'Head of Quantum Algorithms',
        company: 'Qubits Infinite',
        email: 'marcus@qubits.ai',
        phone: '+1 650 555 9922',
        location: 'Mountain View, CA',
        keyPoints: ['Quantum error mitigation', 'Surface codes'],
      );

      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedNew));
      expect(result.isNewPerson, isTrue);
      expect(result.resolvedPerson, isNotNull);
      expect(result.resolvedPerson!.name, equals('Marcus Vance'));
      expect(result.resolvedPerson!.company, equals('Qubits Infinite'));
      expect(result.resolvedPerson!.email, equals('marcus@qubits.ai'));
      expect(result.resolvedPerson!.phone, equals('+1 650 555 9922'));

      // Verify person was persisted in repo
      final createdInRepo = await peopleRepo.getPerson(result.matchedPersonId!);
      expect(createdInRepo, isNotNull);
      expect(createdInRepo!.name, equals('Marcus Vance'));
    });

    test('11. Safe enrichment updates missing fields and protects existing verified data', () async {
      final partialPerson = PersonItem(
        id: 'per_partial_01',
        name: 'David Kester',
        role: '',
        company: '',
        email: null,
        phone: null,
        initials: 'DK',
      );
      await peopleRepo.addPerson(partialPerson);

      final capture = CaptureItem(
        id: 'cap_08',
        type: CaptureType.businessCard,
        title: 'David Card',
        description: 'Card',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_08',
      );

      final entities = OcrExtractedEntities(
        name: 'David Kester',
        role: 'Director of Foundry Operations',
        company: 'TSMC Ecosystem',
        email: 'david.kester@tsmc-ecosystem.com',
        phone: '+1 408 555 3300',
        location: 'Hsinchu / San Jose',
      );

      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(result.resolvedPerson!.email, equals('david.kester@tsmc-ecosystem.com'));
      expect(result.resolvedPerson!.phone, equals('+1 408 555 3300'));
      expect(result.resolvedPerson!.role, equals('Director of Foundry Operations'));
      expect(result.resolvedPerson!.company, equals('TSMC Ecosystem'));
    });

    test('12. Conflict detection records conflicts when incoming data contradicts existing', () async {
      final capture = CaptureItem(
        id: 'cap_09',
        type: CaptureType.businessCard,
        title: 'Sarah Card',
        description: 'Card',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_09',
      );

      final entities = OcrExtractedEntities(
        name: 'Sarah Chen',
        company: 'Quantum Matrix Systems', // Contradicts 'Mosaic Neuromorphic'
        email: 'sarah.new@othercompany.io', // Contradicts existing email
      );

      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(result.conflicts.length, greaterThanOrEqualTo(1));
      expect(result.conflicts.any((c) => c.fieldName == 'company' || c.fieldName == 'email'), isTrue);
    });

    test('13. Activity linking creates chronological ActivityItem linked to person', () async {
      final capture = CaptureItem(
        id: 'cap_10',
        type: CaptureType.businessCard,
        title: 'Card Intake: Sarah Chen',
        description: 'Card scanned at Stanford Conference',
        timestamp: 'Today at 3:15 PM',
        targetRoute: '/interaction/cap_10',
        companyName: 'Mosaic Neuromorphic',
      );

      final entities = OcrExtractedEntities(
        name: 'Sarah Chen',
        email: 'sarah.chen@mosaic-neuro.io',
      );

      final result = await service.resolveAndLink(capture: capture, entities: entities);

      expect(result.createdActivityId, equals('act_cap_cap_10'));
      final createdAct = await activityRepo.getActivity('act_cap_cap_10');
      expect(createdAct, isNotNull);
      expect(createdAct!.personName, equals('Sarah Chen'));
      expect(createdAct.personId, equals('per_sarah_01'));
      expect(createdAct.type, equals(ActivityType.capture));
    });

    test('14. Retry idempotency does not create duplicate Person or Activity records', () async {
      final capture = CaptureItem(
        id: 'cap_11',
        type: CaptureType.businessCard,
        title: 'New Contact',
        description: 'Card',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_11',
      );

      final entities = OcrExtractedEntities(
        name: 'Yuki Tanaka',
        role: 'Hardware Lead',
        company: 'Kyoto Semiconductor',
      );

      // Pass 1
      final res1 = await service.resolveAndLink(capture: capture, entities: entities);
      expect(res1.status, equals(EntityResolutionStatus.resolvedNew));
      final initialPeopleCount = (await peopleRepo.findCandidatesByName('Yuki Tanaka')).length;
      expect(initialPeopleCount, equals(1));

      // Pass 2 (Retry)
      final res2 = await service.resolveAndLink(capture: capture, entities: entities);
      expect(res2.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(res2.matchedPersonId, equals(res1.matchedPersonId));

      final finalPeopleCount = (await peopleRepo.findCandidatesByName('Yuki Tanaka')).length;
      expect(finalPeopleCount, equals(1)); // No duplicate person created!
    });
  });

  group('Phase 13D-05: MockEntityResolutionService Tests', () {
    test('15. Mock service returns deterministic matches and counts calls', () async {
      final mockService = MockEntityResolutionService();
      final capture = CaptureItem(
        id: 'cap_mock_1',
        type: CaptureType.photo,
        title: 'Snapshot',
        description: 'Photo',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_mock_1',
      );

      final entities = OcrExtractedEntities(name: 'Sarah Chen');
      final result = await mockService.resolveAndLink(capture: capture, entities: entities);

      expect(mockService.resolveCalls, equals(1));
      expect(result.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(result.resolvedPerson?.name, equals('Sarah Chen'));
    });

    test('16. Mock service throws when shouldFail is true', () async {
      final mockService = MockEntityResolutionService(shouldFail: true);
      final capture = CaptureItem(
        id: 'cap_mock_2',
        type: CaptureType.note,
        title: 'Note',
        description: 'Note',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_mock_2',
      );

      expect(
        () => mockService.resolveAndLink(capture: capture, entities: OcrExtractedEntities(name: 'Test')),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('17. Mock service returns forcedResult when configured', () async {
      final forced = EntityResolutionResult(
        matchedPersonId: 'forced_id',
        status: EntityResolutionStatus.requiresReview,
        requiresReview: true,
      );
      final mockService = MockEntityResolutionService(forcedResult: forced);

      final result = await mockService.resolveAndLink(
        capture: CaptureItem(
          id: 'c',
          type: CaptureType.note,
          title: 't',
          description: 'd',
          timestamp: 'now',
          targetRoute: '/t',
        ),
        entities: OcrExtractedEntities(),
      );

      expect(result.matchedPersonId, equals('forced_id'));
      expect(result.requiresReview, isTrue);
    });
  });

  group('Phase 13D-05: FirestorePeopleRepository Resolution Unauthenticated Fail-Closed Tests', () {
    test('18. FirestorePeopleRepository throws unauthenticated on findPersonByEmail when logged out', () async {
      final repo = FirestorePeopleRepository();
      expect(
        () => repo.findPersonByEmail('test@test.com'),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('19. FirestorePeopleRepository throws unauthenticated on findPersonByPhone when logged out', () async {
      final repo = FirestorePeopleRepository();
      expect(
        () => repo.findPersonByPhone('1234567890'),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('20. FirestorePeopleRepository throws unauthenticated on createPersonFromCapture when logged out', () async {
      final repo = FirestorePeopleRepository();
      final person = PersonItem(
        id: 'p1',
        name: 'Test',
        role: 'Role',
        company: 'Comp',
        initials: 'T',
      );
      expect(
        () => repo.createPersonFromCapture(person),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('21. FirestorePeopleRepository throws unauthenticated on enrichPerson when logged out', () async {
      final repo = FirestorePeopleRepository();
      expect(
        () => repo.enrichPerson('p1', {'role': 'New Role'}),
        throwsA(isA<RecallrDataException>()),
      );
    });
  });

  group('Phase 13D-05: Capture Processing & Entity Resolution Integration Tests', () {
    test('22. DeterministicCaptureProcessingService triggers identity resolution for Business Card', () async {
      final peopleRepo = MockPeopleRepository();
      final resolutionService = DeterministicEntityResolutionService(peopleRepository: peopleRepo);
      final processingService = DeterministicCaptureProcessingService(
        entityResolutionService: resolutionService,
        simulatedLatency: Duration.zero,
      );

      final capture = CaptureItem(
        id: 'cap_proc_card',
        type: CaptureType.businessCard,
        title: 'Scanned Card',
        description: 'Card',
        timestamp: 'Just now',
        personName: 'Elena Rostova',
        targetRoute: '/interaction/cap_proc_card',
      );

      final result = await processingService.processCapture(capture);
      expect(result.status, equals(CaptureProcessingStatus.completed));
      expect(result.metadata?['entityResolutionStatus'], isNotNull);
      expect(result.metadata?['resolvedPersonId'], isNotNull);
    });

    test('23. DeterministicCaptureProcessingService triggers identity resolution for Note', () async {
      final peopleRepo = MockPeopleRepository();
      final resolutionService = DeterministicEntityResolutionService(peopleRepository: peopleRepo);
      final processingService = DeterministicCaptureProcessingService(
        entityResolutionService: resolutionService,
        simulatedLatency: Duration.zero,
      );

      final capture = CaptureItem(
        id: 'cap_proc_note',
        type: CaptureType.note,
        title: 'Meeting Note with Sarah Chen',
        description: 'Met with Sarah Chen (sarah.chen@mosaic-neuro.io) regarding chip packaging.',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_proc_note',
      );

      final result = await processingService.processCapture(capture);
      expect(result.status, equals(CaptureProcessingStatus.completed));
      expect(result.detectedPeople, contains('Sarah Chen'));
      expect(result.metadata?['resolvedPersonId'], isNotNull);
    });

    test('24. DeterministicCaptureProcessingService skips identity resolution for Voice Memo with no STT', () async {
      final peopleRepo = MockPeopleRepository();
      final resolutionService = DeterministicEntityResolutionService(peopleRepository: peopleRepo);
      final processingService = DeterministicCaptureProcessingService(
        entityResolutionService: resolutionService,
        simulatedLatency: Duration.zero,
      );

      final capture = CaptureItem(
        id: 'cap_proc_voice',
        type: CaptureType.voice,
        title: 'Voice Takeaway',
        description: 'Discussed architecture roadmap with Alex Rivera at Synapse AI.',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_proc_voice',
      );

      final result = await processingService.processCapture(capture);
      expect(result.status, equals(CaptureProcessingStatus.completed));
      expect(result.detectedPeople, isEmpty);
      expect(result.metadata?['entityResolutionStatus'], isNull);
    });
  });

  group('Phase 13D-05: Capture UI Entity Resolution Badge Tests', () {
    testWidgets('25. CaptureSuccessView renders "Matched to {Person Name}" for resolvedExisting', (tester) async {
      final item = CaptureItem(
        id: 'cap_ui_1',
        type: CaptureType.businessCard,
        title: 'Card: Sarah Chen',
        description: 'Description',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_ui_1',
        personName: 'Sarah Chen',
        processingStatus: CaptureProcessingStatus.completed,
        entityResolutionStatus: 'resolvedExisting',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaptureSuccessView(
              item: item,
              onDone: () {},
              onViewMemory: () {},
            ),
          ),
        ),
      );

      expect(find.text('Matched to Sarah Chen'), findsOneWidget);
    });

    testWidgets('26. CaptureSuccessView renders "New person detected · {Person Name}" for resolvedNew', (tester) async {
      final item = CaptureItem(
        id: 'cap_ui_2',
        type: CaptureType.businessCard,
        title: 'Card: Marcus Vance',
        description: 'Description',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_ui_2',
        personName: 'Marcus Vance',
        processingStatus: CaptureProcessingStatus.completed,
        entityResolutionStatus: 'resolvedNew',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaptureSuccessView(
              item: item,
              onDone: () {},
              onViewMemory: () {},
            ),
          ),
        ),
      );

      expect(find.text('New person detected · Marcus Vance'), findsOneWidget);
    });

    testWidgets('27. CaptureSuccessView renders "Possible matches found · Review" for requiresReview', (tester) async {
      final item = CaptureItem(
        id: 'cap_ui_3',
        type: CaptureType.photo,
        title: 'Photo',
        description: 'Description',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_ui_3',
        personName: 'Sarah Chen',
        processingStatus: CaptureProcessingStatus.completed,
        entityResolutionStatus: 'requiresReview',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaptureSuccessView(
              item: item,
              onDone: () {},
              onViewMemory: () {},
            ),
          ),
        ),
      );

      expect(find.text('Possible matches found · Review'), findsOneWidget);
    });

    testWidgets('28. CaptureSuccessView renders "Processed & Indexed" fallback when no person is attached', (tester) async {
      final item = CaptureItem(
        id: 'cap_ui_4',
        type: CaptureType.note,
        title: 'General Note',
        description: 'Description',
        timestamp: 'Just now',
        targetRoute: '/interaction/cap_ui_4',
        processingStatus: CaptureProcessingStatus.completed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaptureSuccessView(
              item: item,
              onDone: () {},
              onViewMemory: () {},
            ),
          ),
        ),
      );

      expect(find.text('Processed & Indexed'), findsOneWidget);
    });
  });
}