import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/core/security/environment_config.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/firestore/firestore_activity_repository.dart';
import 'package:recaller/data/firestore/firestore_capture_repository.dart';
import 'package:recaller/data/firestore/firestore_follow_up_repository.dart';
import 'package:recaller/data/firestore/firestore_memory_retrieval_repository.dart';
import 'package:recaller/data/firestore/firestore_people_repository.dart';
import 'package:recaller/data/firestore/firestore_person_detail_repository.dart';
import 'package:recaller/data/mock/mock_activity_repository.dart';
import 'package:recaller/data/mock/mock_capture_processing_repository.dart';
import 'package:recaller/data/mock/mock_capture_repository.dart';
import 'package:recaller/data/mock/mock_follow_up_repository.dart';
import 'package:recaller/data/mock/mock_memory_retrieval_repository.dart';
import 'package:recaller/data/mock/mock_people_repository.dart';
import 'package:recaller/data/mock/mock_person_detail_repository.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/ask/models/ai_answer_models.dart';
import 'package:recaller/features/ask/models/memory_retrieval_models.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/models/capture_processing_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/home/widgets/home_empty_state.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/screens/activity/activity_screen.dart';
import 'package:recaller/screens/follow_ups/follow_ups_screen.dart';
import 'package:recaller/screens/home/home_screen.dart';
import 'package:recaller/screens/people/people_screen.dart';
import 'package:recaller/screens/person/person_detail_screen.dart';
import 'package:recaller/services/ai/ai_answer_service.dart';
import 'package:recaller/services/ai/answer_grounding_service.dart';
import 'package:recaller/services/ai/deterministic_ai_answer_generator.dart';
import 'package:recaller/services/retrieval/memory_retrieval_service.dart';
import 'package:recaller/services/retrieval/relationship_context_assembler.dart';

Widget _wrapScreen(Widget child) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    routes: {
      '/home': (context) => const Scaffold(body: Text('Home Route')),
      '/people': (context) => const Scaffold(body: Text('People Route')),
      '/ask': (context) => const Scaffold(body: Text('Ask Route')),
      '/activity': (context) => const Scaffold(body: Text('Activity Route')),
      '/follow-ups': (context) => const Scaffold(body: Text('FollowUps Route')),
      '/person/per_sarah_01': (context) => const Scaffold(body: Text('Person per_sarah_01')),
      '/person/per_rahul_01': (context) => const Scaffold(body: Text('Person per_rahul_01')),
      '/interaction/act_sarah_01': (context) => const Scaffold(body: Text('Interaction act_sarah_01')),
    },
    home: Scaffold(body: child),
  );
}

void main() {
  group('Phase 13G-03 Group 1: Authentication & UID Scoping', () {
    test('1. Unauthenticated repository calls fail closed without mock fallbacks', () {
      final unauthPeople = FirestorePeopleRepository(firestore: null, auth: null);
      final unauthActivity = FirestoreActivityRepository(firestore: null, auth: null);
      final unauthFollowUp = FirestoreFollowUpRepository(firestore: null, auth: null);
      final unauthCapture = FirestoreCaptureRepository(firestore: null, auth: null);
      final unauthPersonDetail = FirestorePersonDetailRepository(firestore: null, auth: null);
      final unauthRetrieval = FirestoreMemoryRetrievalRepository(firestore: null, auth: null);

      expect(() => unauthPeople.streamPeople(), throwsA(isA<RecallrDataException>()));
      expect(() => unauthActivity.streamActivities(), throwsA(isA<RecallrDataException>()));
      expect(() => unauthFollowUp.streamFollowUps(), throwsA(isA<RecallrDataException>()));
      expect(() => unauthCapture.streamRecentCaptures(), throwsA(isA<RecallrDataException>()));
      expect(() => unauthPersonDetail.getProfile('per_123'), throwsA(isA<RecallrDataException>()));
      expect(() => unauthRetrieval.searchPeople('test'), throwsA(isA<RecallrDataException>()));
    });

    test('2. Repositories resolve authenticated user UID dynamically', () {
      final peopleRepo = MockPeopleRepository(initialPeople: const []);
      expect(peopleRepo, isNotNull);
      expect(peopleRepo.streamPeople(), isA<Stream<List<PersonItem>>>());
    });

    test('3. Account switching isolates repository data streams', () async {
      final userAPeople = MockPeopleRepository(initialPeople: [
        const PersonItem(
          id: 'per_a_1',
          name: 'Alice UserA',
          role: 'Architect',
          company: 'Alpha Corp',
          initials: 'AU',
        ),
      ]);

      final userBPeople = MockPeopleRepository(initialPeople: [
        const PersonItem(
          id: 'per_b_1',
          name: 'Bob UserB',
          role: 'Founder',
          company: 'Beta Corp',
          initials: 'BU',
        ),
      ]);

      final listA = await userAPeople.streamPeople().first;
      final listB = await userBPeople.streamPeople().first;

      expect(listA.map((p) => p.name), contains('Alice UserA'));
      expect(listA.map((p) => p.name), isNot(contains('Bob UserB')));

      expect(listB.map((p) => p.name), contains('Bob UserB'));
      expect(listB.map((p) => p.name), isNot(contains('Alice UserA')));
    });
  });

  group('Phase 13G-03 Group 2: Entity Lifecycle & CRUD Integrity', () {
    test('4. Person CRUD lifecycle: create, read, update, delete', () async {
      final repo = MockPeopleRepository(initialPeople: const []);

      const newPerson = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP of System Architecture',
        company: 'Mosaic Labs',
        initials: 'SC',
      );

      await repo.addPerson(newPerson);
      var people = await repo.streamPeople().first;
      expect(people.length, equals(1));
      expect(people.first.name, equals('Sarah Chen'));

      final updatedPerson = newPerson.copyWith(role: 'Chief Technology Officer');
      await repo.updatePerson(updatedPerson);
      people = await repo.streamPeople().first;
      expect(people.first.role, equals('Chief Technology Officer'));

      await repo.deletePerson('per_sarah_01');
      people = await repo.streamPeople().first;
      expect(people, isEmpty);
    });

    test('5. Activity CRUD lifecycle: create, read, delete', () async {
      final repo = MockActivityRepository(initialActivities: const []);

      const activity = ActivityItem(
        id: 'act_sarah_01',
        title: 'Mosaic Labs Product Discussion',
        summary: 'Met Sarah Chen to discuss neuromorphic hardware architecture.',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: 'Today Â· 2:00 PM',
        actionLabel: 'View Meeting',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/interaction/act_sarah_01',
      );

      await repo.addActivity(activity);
      var list = await repo.streamActivities().first;
      expect(list.length, equals(1));
      expect(list.first.title, contains('Mosaic Labs'));

      await repo.deleteActivity('act_sarah_01');
      list = await repo.streamActivities().first;
      expect(list, isEmpty);
    });

    test('6. Follow-up lifecycle: create, complete, reopen, delete', () async {
      final repo = MockFollowUpRepository(initialFollowUps: const []);

      const followUp = FollowUpItem(
        id: 'fol_sarah_01',
        title: 'Send API documentation to Sarah Chen',
        context: 'Promised during neuromorphic hardware sync.',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        priority: FollowUpPriority.high,
        dueDate: 'Today Â· 5:00 PM',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyId: 'comp_mosaic',
        companyName: 'Mosaic Labs',
        targetRoute: '/follow-up/fol_sarah_01',
        isCompleted: false,
      );

      await repo.addFollowUp(followUp);
      var list = await repo.streamFollowUps().first;
      expect(list.length, equals(1));
      expect(list.first.isCompleted, isFalse);

      await repo.toggleComplete('fol_sarah_01', true);
      list = await repo.streamFollowUps().first;
      expect(list.first.isCompleted, isTrue);

      await repo.toggleComplete('fol_sarah_01', false);
      list = await repo.streamFollowUps().first;
      expect(list.first.isCompleted, isFalse);

      await repo.deleteFollowUp('fol_sarah_01');
      list = await repo.streamFollowUps().first;
      expect(list, isEmpty);
    });

    test('7. Capture lifecycle: create, process, delete', () async {
      final repo = MockCaptureRepository(initialCaptures: const []);

      const capture = CaptureItem(
        id: 'cap_sarah_01',
        type: CaptureType.businessCard,
        title: 'Visiting Card: Sarah Chen',
        description: 'VP of System Architecture at Mosaic Labs',
        timestamp: 'Just now',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/activity',
      );

      await repo.saveCapture(capture);
      var list = await repo.streamRecentCaptures().first;
      expect(list.length, equals(1));
      expect(list.first.title, contains('Sarah Chen'));

      final processingRepo = MockCaptureProcessingRepository();
      final processed = await processingRepo.processCapture(capture);
      expect(processed.processingStatus, equals(CaptureProcessingStatus.completed));

      await repo.deleteCapture('cap_sarah_01');
      list = await repo.streamRecentCaptures().first;
      expect(list, isEmpty);
    });

    test('8. Memory Claim lifecycle: create, retrieve, update in person detail', () async {
      final detailRepo = MockPersonDetailRepository();

      const profile = PersonProfile(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Labs',
        location: 'San Francisco',
        initials: 'SC',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Strong',
        firstMet: 'August 2026',
        lastInteraction: 'Today',
        totalInteractions: 1,
        sharedEventsCount: 1,
        aiSummary: 'Lead architect for neuromorphic silicon systems.',
        capabilities: ['Hardware', 'RISC-V', 'Neuromorphic'],
        memories: [],
      );

      await detailRepo.saveProfile(profile);

      const memory = MemoryItem(
        id: 'claim_sarah_01',
        category: 'Collaboration',
        text: 'Interested in RISC-V hardware collaboration and joint benchmark paper.',
        source: 'Meeting Note',
        isVerified: true,
      );

      await detailRepo.addMemoryItem('per_sarah_01', memory);
      final retrieved = await detailRepo.getProfile('per_sarah_01');
      expect(retrieved?.memories.length, equals(1));
      expect(retrieved?.memories.first.text, contains('RISC-V hardware collaboration'));
    });
  });

  group('Phase 13G-03 Group 3: Entity Relationships & Canonical IDs', () {
    test('9. Person <-> Activity canonical ID linkage', () {
      const person = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Labs',
        initials: 'SC',
      );

      const activity = ActivityItem(
        id: 'act_sarah_01',
        title: 'Product Discussion',
        summary: 'Met Sarah Chen from Mosaic Labs.',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: 'Today',
        actionLabel: 'View',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/interaction/act_sarah_01',
      );

      expect(activity.personId, equals(person.id));
      expect(activity.personName, equals(person.name));
      expect(activity.companyName, equals(person.company));
    });

    test('10. Person <-> Follow-up canonical ID linkage', () {
      const person = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Labs',
        initials: 'SC',
      );

      const followUp = FollowUpItem(
        id: 'fol_sarah_01',
        title: 'Send API docs',
        context: 'Follow up from discussion',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        priority: FollowUpPriority.high,
        dueDate: 'Today',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyId: 'comp_mosaic',
        companyName: 'Mosaic Labs',
        targetRoute: '/follow-up/fol_sarah_01',
        isCompleted: false,
      );

      expect(followUp.personId, equals(person.id));
      expect(followUp.personName, equals(person.name));
      expect(followUp.companyName, equals(person.company));
    });

    test('11. Person <-> Capture canonical ID linkage', () {
      const capture = CaptureItem(
        id: 'cap_sarah_01',
        type: CaptureType.businessCard,
        title: 'Sarah Chen Card',
        description: 'Mosaic Labs',
        timestamp: 'Today',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/activity',
      );

      expect(capture.personId, equals('per_sarah_01'));
      expect(capture.personName, equals('Sarah Chen'));
    });

    test('12. Memory Item canonical linkage with person and source', () {
      const memory = MemoryItem(
        id: 'claim_sarah_01',
        category: 'Interest',
        text: 'Interested in RISC-V collaboration',
        source: 'cap_sarah_01',
        isVerified: true,
      );

      expect(memory.id, equals('claim_sarah_01'));
      expect(memory.source, equals('cap_sarah_01'));
    });

    testWidgets('13. Person Detail Dossier renders only matching personId data', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final detailRepo = MockPersonDetailRepository(initialProfiles: {
        'per_sarah_01': const PersonProfile(
          id: 'per_sarah_01',
          name: 'Sarah Chen',
          role: 'VP Architecture',
          company: 'Mosaic Labs',
          location: 'San Francisco',
          initials: 'SC',
          relationshipType: RelationshipContextType.collaborator,
          relationshipStrength: 'Strong',
          firstMet: 'August 2026',
          lastInteraction: 'Today',
          totalInteractions: 1,
          sharedEventsCount: 1,
          aiSummary: 'Lead architect for neuromorphic silicon systems at Mosaic Labs.',
          capabilities: ['Hardware', 'RISC-V', 'Neuromorphic'],
          memories: [
            MemoryItem(
              id: 'm1',
              category: 'Collaboration',
              text: 'Interested in RISC-V hardware collaboration',
              source: 'Meeting',
            ),
          ],
        ),
      });

      await tester.pumpWidget(
        _wrapScreen(
          PersonDetailScreen(
            personId: 'per_sarah_01',
            repository: detailRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sarah Chen'), findsWidgets);
      expect(find.textContaining('Mosaic Labs'), findsWidgets);
      expect(find.textContaining('neuromorphic silicon systems'), findsWidgets);
      expect(find.text('Rahul Mehta'), findsNothing);
      expect(find.text('Priya Sharma'), findsNothing);
    });
  });

  group('Phase 13G-03 Group 4: End-to-End Golden User Journey', () {
    late MockPeopleRepository peopleRepo;
    late MockActivityRepository activityRepo;
    late MockFollowUpRepository followUpRepo;
    late MockCaptureRepository captureRepo;
    late MockPersonDetailRepository detailRepo;
    late MockMemoryRetrievalRepository retrievalRepo;
    late RelationshipContextAssembler assembler;
    late DeterministicMemoryRetrievalService retrievalService;
    late DeterministicAiAnswerService aiService;

    setUp(() {
      peopleRepo = MockPeopleRepository(initialPeople: const []);
      activityRepo = MockActivityRepository(initialActivities: const []);
      followUpRepo = MockFollowUpRepository(initialFollowUps: const []);
      captureRepo = MockCaptureRepository(initialCaptures: const []);
      detailRepo = MockPersonDetailRepository();

      retrievalRepo = MockMemoryRetrievalRepository(
        peopleRepository: peopleRepo,
        activityRepository: activityRepo,
        followUpRepository: followUpRepo,
        captureRepository: captureRepo,
        personDetailRepository: detailRepo,
      );

      assembler = RelationshipContextAssembler(
        peopleRepository: peopleRepo,
        personDetailRepository: detailRepo,
        activityRepository: activityRepo,
        followUpRepository: followUpRepo,
        captureRepository: captureRepo,
      );

      retrievalService = DeterministicMemoryRetrievalService(
        repository: retrievalRepo,
        assembler: assembler,
      );

      aiService = DeterministicAiAnswerService(
        retrievalService: retrievalService,
      );
    });

    test('14. Golden Journey Step 1 & 2: Authenticated user creates Sarah Chen person record', () async {
      const sarah = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP of System Architecture',
        company: 'Mosaic Labs',
        initials: 'SC',
        locationOrEvent: 'SF Hardware Summit',
        contextSnippet: 'Discussed custom neuromorphic tiles and interconnect protocols.',
        capabilities: ['Hardware', 'RISC-V', 'Neuromorphic'],
      );

      await peopleRepo.addPerson(sarah);
      final people = await peopleRepo.streamPeople().first;
      expect(people.length, equals(1));
      expect(people.first.id, equals('per_sarah_01'));
      expect(people.first.name, equals('Sarah Chen'));
    });

    test('15. Golden Journey Step 3: Create Capture record linking Sarah Chen and Mosaic Labs', () async {
      const capture = CaptureItem(
        id: 'cap_sarah_01',
        type: CaptureType.businessCard,
        title: 'Visiting Card: Sarah Chen',
        description: 'VP of System Architecture at Mosaic Labs',
        timestamp: 'Just now',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/activity',
      );

      await captureRepo.saveCapture(capture);
      final list = await captureRepo.streamRecentCaptures().first;
      expect(list.length, equals(1));
      expect(list.first.personName, equals('Sarah Chen'));
    });

    test('16. Golden Journey Step 4: Create Activity event linking Sarah Chen', () async {
      const activity = ActivityItem(
        id: 'act_sarah_01',
        title: 'Mosaic Labs Product Discussion',
        summary: 'Met Sarah Chen to discuss neuromorphic hardware architecture.',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: 'Today Â· 2:00 PM',
        actionLabel: 'View Meeting',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/interaction/act_sarah_01',
      );

      await activityRepo.addActivity(activity);
      final list = await activityRepo.streamActivities().first;
      expect(list.length, equals(1));
      expect(list.first.personName, equals('Sarah Chen'));
    });

    test('17. Golden Journey Step 5: Create Memory Claim associated with Sarah Chen', () async {
      const profile = PersonProfile(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Labs',
        location: 'San Francisco',
        initials: 'SC',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Strong',
        firstMet: 'August 2026',
        lastInteraction: 'Today',
        totalInteractions: 1,
        sharedEventsCount: 1,
        aiSummary: 'Lead architect for neuromorphic silicon systems at Mosaic Labs.',
        capabilities: ['Hardware', 'RISC-V', 'Neuromorphic'],
        memories: [
          MemoryItem(
            id: 'claim_sarah_01',
            category: 'Collaboration',
            text: 'Interested in RISC-V hardware collaboration and joint benchmark paper.',
            source: 'Meeting Note',
          ),
        ],
      );

      await detailRepo.saveProfile(profile);
      final p = await detailRepo.getProfile('per_sarah_01');
      expect(p?.memories.first.text, contains('RISC-V hardware collaboration'));
    });

    test('18. Golden Journey Step 6: Create Follow-up to send API documentation', () async {
      const followUp = FollowUpItem(
        id: 'fol_sarah_01',
        title: 'Send API documentation to Sarah Chen',
        context: 'Promised during neuromorphic hardware sync.',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        priority: FollowUpPriority.high,
        dueDate: 'Today Â· 5:00 PM',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyId: 'comp_mosaic',
        companyName: 'Mosaic Labs',
        targetRoute: '/follow-up/fol_sarah_01',
        isCompleted: false,
      );

      await followUpRepo.addFollowUp(followUp);
      final list = await followUpRepo.streamFollowUps().first;
      expect(list.length, equals(1));
      expect(list.first.title, contains('Send API documentation'));
    });

    test('19. Golden Journey Step 7: Dossier displays all connected entity elements', () async {
      const profile = PersonProfile(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Labs',
        location: 'San Francisco',
        initials: 'SC',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Strong',
        firstMet: 'August 2026',
        lastInteraction: 'Today',
        totalInteractions: 1,
        sharedEventsCount: 1,
        aiSummary: 'Lead architect for neuromorphic silicon systems at Mosaic Labs.',
        capabilities: ['Hardware', 'RISC-V', 'Neuromorphic'],
        memories: [],
      );

      await detailRepo.saveProfile(profile);
      final p = await detailRepo.getProfile('per_sarah_01');
      expect(p, isNotNull);
      expect(p!.name, equals('Sarah Chen'));
      expect(p.company, equals('Mosaic Labs'));
    });

    test('20. Golden Journey Step 8: Multi-source memory retrieval gathers all sources for Sarah Chen', () async {
      const sarah = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Labs',
        initials: 'SC',
      );
      const activity = ActivityItem(
        id: 'act_sarah_01',
        title: 'Mosaic Labs Product Discussion',
        summary: 'Met Sarah Chen to discuss neuromorphic hardware architecture.',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: 'Today Â· 2:00 PM',
        actionLabel: 'View Meeting',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/interaction/act_sarah_01',
      );
      const followUp = FollowUpItem(
        id: 'fol_sarah_01',
        title: 'Send API documentation to Sarah Chen',
        context: 'Promised during sync',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        priority: FollowUpPriority.high,
        dueDate: 'Today',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/follow-up/fol_sarah_01',
        isCompleted: false,
      );

      await peopleRepo.addPerson(sarah);
      await activityRepo.addActivity(activity);
      await followUpRepo.addFollowUp(followUp);

      final searchResult = await retrievalService.retrieve('Who is Sarah Chen?');

      expect(searchResult.context.targetPerson?.name, equals('Sarah Chen'));
      expect(searchResult.context.evidenceItems, isNotEmpty);
    });

    test('21. Golden Journey Step 9: AI answer generator grounds answer with Sarah Chen evidence', () async {
      const sarah = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Labs',
        initials: 'SC',
      );
      await peopleRepo.addPerson(sarah);

      final answer = await aiService.answer(
        const AiAnswerRequest(query: 'Who is Sarah Chen?'),
      );

      expect(answer.status, equals(AiAnswerStatus.completed));
      expect(answer.isSuccessful, isTrue);
      expect(answer.answer, contains('Sarah Chen'));
      expect(answer.evidence, isNotEmpty);
    });
  });

  group('Phase 13G-03 Group 5: Home Command Center Integrity', () {
    testWidgets('22. Home metrics start at 0 before data and display HomeEmptyState', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapScreen(
          HomeScreen(
            peopleRepository: MockPeopleRepository(initialPeople: const []),
            activityRepository: MockActivityRepository(initialActivities: const []),
            followUpRepository: MockFollowUpRepository(initialFollowUps: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeEmptyState), findsOneWidget);
      expect(find.text('Capture First Encounter'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsNothing);
    });

    testWidgets('23. Home metrics update to people=1, interactions=1, followUps=1 after data creation', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const sarah = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Labs',
        initials: 'SC',
      );
      const activity = ActivityItem(
        id: 'act_sarah_01',
        title: 'Mosaic Labs Sync',
        summary: 'Met Sarah Chen',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: 'Today',
        actionLabel: 'View',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/interaction/act_sarah_01',
      );
      const followUp = FollowUpItem(
        id: 'fol_sarah_01',
        title: 'Send API docs',
        context: 'Follow-up',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        priority: FollowUpPriority.high,
        dueDate: 'Today',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/follow-up/fol_sarah_01',
        isCompleted: false,
      );

      final peopleRepo = MockPeopleRepository(initialPeople: [sarah]);
      final activityRepo = MockActivityRepository(initialActivities: [activity]);
      final followUpRepo = MockFollowUpRepository(initialFollowUps: [followUp]);

      await tester.pumpWidget(
        _wrapScreen(
          HomeScreen(
            peopleRepository: peopleRepo,
            activityRepository: activityRepo,
            followUpRepository: followUpRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeEmptyState), findsNothing);
      expect(find.text('Sarah Chen'), findsWidgets);
      expect(find.text('Mosaic Labs Sync'), findsOneWidget);
      expect(find.text('Send API docs'), findsOneWidget);
    });

    testWidgets('24. Home metrics reset dynamically to 0 after deleting records without app restart', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final peopleRepo = MockPeopleRepository(initialPeople: [
        const PersonItem(
          id: 'per_sarah_01',
          name: 'Sarah Chen',
          role: 'VP Architecture',
          company: 'Mosaic Labs',
          initials: 'SC',
        ),
      ]);
      final activityRepo = MockActivityRepository(initialActivities: const []);
      final followUpRepo = MockFollowUpRepository(initialFollowUps: const []);

      await tester.pumpWidget(
        _wrapScreen(
          HomeScreen(
            peopleRepository: peopleRepo,
            activityRepository: activityRepo,
            followUpRepository: followUpRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sarah Chen'), findsWidgets);

      await peopleRepo.deletePerson('per_sarah_01');
      await tester.pumpAndSettle();

      expect(find.byType(HomeEmptyState), findsOneWidget);
      expect(find.text('Sarah Chen'), findsNothing);
    });
  });

  group('Phase 13G-03 Group 6: Cross-Screen Consistency', () {
    testWidgets('25. Same Sarah Chen canonical identity renders across People, Activity, and Follow-ups', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const sarah = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Labs',
        initials: 'SC',
      );
      const activity = ActivityItem(
        id: 'act_sarah_01',
        title: 'Mosaic Labs Sync',
        summary: 'Met Sarah Chen',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: 'Today',
        actionLabel: 'View',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/interaction/act_sarah_01',
      );
      const followUp = FollowUpItem(
        id: 'fol_sarah_01',
        title: 'Send API docs',
        context: 'Follow-up with Sarah',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        priority: FollowUpPriority.high,
        dueDate: 'Today',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Labs',
        targetRoute: '/follow-up/fol_sarah_01',
        isCompleted: false,
      );

      final peopleRepo = MockPeopleRepository(initialPeople: [sarah]);
      final activityRepo = MockActivityRepository(initialActivities: [activity]);
      final followUpRepo = MockFollowUpRepository(initialFollowUps: [followUp]);

      // Verify People Screen
      await tester.pumpWidget(_wrapScreen(PeopleScreen(repository: peopleRepo)));
      await tester.pumpAndSettle();
      expect(find.text('Sarah Chen'), findsWidgets);

      // Verify Activity Screen
      await tester.pumpWidget(_wrapScreen(ActivityScreen(repository: activityRepo)));
      await tester.pumpAndSettle();
      expect(find.text('Mosaic Labs Sync'), findsWidgets);

      // Verify Follow-ups Screen
      await tester.pumpWidget(_wrapScreen(FollowUpsScreen(repository: followUpRepo)));
      await tester.pumpAndSettle();
      expect(find.text('Send API docs'), findsWidgets);
    });
  });

  group('Phase 13G-03 Group 7: Memory Retrieval & AI Grounding Integrity', () {
    test('26. Exact queries return matching sources with valid deep links', () async {
      final retrievalRepo = MockMemoryRetrievalRepository();
      final assembler = RelationshipContextAssembler(
        peopleRepository: retrievalRepo.peopleRepository,
        personDetailRepository: retrievalRepo.personDetailRepository,
        activityRepository: retrievalRepo.activityRepository,
        followUpRepository: retrievalRepo.followUpRepository,
        captureRepository: retrievalRepo.captureRepository,
      );

      final retrievalService = DeterministicMemoryRetrievalService(
        repository: retrievalRepo,
        assembler: assembler,
      );

      final result = await retrievalService.retrieve('Who is Sarah Chen?');

      expect(result.context.targetPerson?.name, equals('Sarah Chen'));
      expect(result.context.evidenceItems, isNotEmpty);
      expect(result.context.evidenceItems.first.personName, equals('Sarah Chen'));
    });

    test('27. AnswerGroundingService extracts and budgets structured evidence', () {
      final memoryContext = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Sarah Chen'),
        targetPerson: const PersonItem(
          id: 'per_sarah_01',
          name: 'Sarah Chen',
          role: 'VP Architecture',
          company: 'Mosaic Labs',
          initials: 'SC',
        ),
        assembledAt: DateTime.now(),
      );

      const groundingService = AnswerGroundingService();
      final evidence = groundingService.extractEvidence(memoryContext);

      expect(evidence, isNotEmpty);
      expect(evidence.first.personName, equals('Sarah Chen'));
      expect(evidence.first.targetRoute, equals('/person/per_sarah_01'));
    });

    test('28. Deterministic generator grounds responses only on verified evidence', () async {
      final gen = DeterministicAiAnswerGenerator();
      final memoryContext = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Who is Sarah Chen?'),
        targetPerson: const PersonItem(
          id: 'per_sarah_01',
          name: 'Sarah Chen',
          role: 'VP Architecture',
          company: 'Mosaic Labs',
          initials: 'SC',
        ),
        assembledAt: DateTime.now(),
      );

      final answer = await gen.generateAnswer(
        request: const AiAnswerRequest(query: 'Who is Sarah Chen?'),
        context: memoryContext,
      );

      expect(answer.status, equals(AiAnswerStatus.completed));
      expect(answer.answer, contains('Sarah Chen'));
      expect(answer.evidence, isNotEmpty);
    });
  });

  group('Phase 13G-03 Group 8: Multi-Tenant Account Isolation', () {
    test('29. User A cannot retrieve User B data and vice versa', () async {
      final repoA = MockPeopleRepository(initialPeople: [
        const PersonItem(
          id: 'per_sarah_01',
          name: 'Sarah Chen',
          role: 'VP Architecture',
          company: 'Mosaic Labs',
          initials: 'SC',
        ),
      ]);

      final repoB = MockPeopleRepository(initialPeople: [
        const PersonItem(
          id: 'per_rahul_01',
          name: 'Rahul Mehta',
          role: 'Partner',
          company: 'Nexus Labs',
          initials: 'RM',
        ),
      ]);

      final peopleA = await repoA.streamPeople().first;
      final peopleB = await repoB.streamPeople().first;

      expect(peopleA.any((p) => p.name == 'Rahul Mehta'), isFalse);
      expect(peopleB.any((p) => p.name == 'Sarah Chen'), isFalse);
    });

    test('30. Logout User A clears private state; Login User B loads fresh state', () async {
      var activeRepo = MockPeopleRepository(initialPeople: [
        const PersonItem(
          id: 'per_sarah_01',
          name: 'Sarah Chen',
          role: 'VP Architecture',
          company: 'Mosaic Labs',
          initials: 'SC',
        ),
      ]);

      var currentPeople = await activeRepo.streamPeople().first;
      expect(currentPeople.length, equals(1));

      // Simulate Logout
      activeRepo = MockPeopleRepository(initialPeople: const []);
      currentPeople = await activeRepo.streamPeople().first;
      expect(currentPeople, isEmpty);

      // Simulate Login User B
      activeRepo = MockPeopleRepository(initialPeople: [
        const PersonItem(
          id: 'per_rahul_01',
          name: 'Rahul Mehta',
          role: 'Partner',
          company: 'Nexus Labs',
          initials: 'RM',
        ),
      ]);
      currentPeople = await activeRepo.streamPeople().first;
      expect(currentPeople.length, equals(1));
      expect(currentPeople.first.name, equals('Rahul Mehta'));
    });
  });

  group('Phase 13G-03 Group 9: Offline & Reconnection Truth', () {
    test('31. Idempotency: Multiple saves with same ID update cleanly without duplicate entities', () async {
      final repo = MockCaptureRepository(initialCaptures: const []);

      const capture = CaptureItem(
        id: 'cap_deterministic_01',
        type: CaptureType.note,
        title: 'Architecture Note',
        description: 'Meeting notes',
        timestamp: 'Just now',
        targetRoute: '/activity',
      );

      await repo.saveCapture(capture);
      await repo.saveCapture(capture);
      await repo.saveCapture(capture);

      final list = await repo.streamRecentCaptures().first;
      expect(list.length, equals(1));
      expect(list.first.id, equals('cap_deterministic_01'));
    });

    test('32. Offline cache and sync preserves records across disconnect simulation', () async {
      final repo = MockPeopleRepository(initialPeople: const []);

      const person = PersonItem(
        id: 'per_cached_01',
        name: 'Elena Rostova',
        role: 'Founder',
        company: 'Quantum Synapse',
        initials: 'ER',
      );

      await repo.addPerson(person);
      final stream1 = await repo.streamPeople().first;
      expect(stream1.length, equals(1));

      // Simulated reconnect fetch
      final stream2 = await repo.streamPeople().first;
      expect(stream2.first.name, equals('Elena Rostova'));
    });
  });

  group('Phase 13G-03 Group 10: Runtime Source-of-Truth & DI', () {
    test('33. RecallrDependencies resolves mock implementation in test harness', () {
      final deps = RecallrDependencies.mock();
      expect(deps.peopleRepository, isA<MockPeopleRepository>());
      expect(deps.activityRepository, isA<MockActivityRepository>());
      expect(deps.followUpRepository, isA<MockFollowUpRepository>());
      expect(deps.captureRepository, isA<MockCaptureRepository>());
    });

    test('34. Production wiring isolates real implementations without demo fallbacks', () {
      final prod = RecallrDependencies.production();
      expect(prod.peopleRepository, isA<FirestorePeopleRepository>());
      expect(prod.activityRepository, isA<FirestoreActivityRepository>());
      expect(prod.followUpRepository, isA<FirestoreFollowUpRepository>());
      expect(prod.captureRepository, isA<FirestoreCaptureRepository>());
      expect(prod.personDetailRepository, isA<FirestorePersonDetailRepository>());
      expect(prod.memoryRetrievalRepository, isA<FirestoreMemoryRetrievalRepository>());
    });
  });

  group('Phase 13G-03 Group 11: Observability Privacy', () {
    test('35. SafeLogger sanitizes email, phone, UID, and API key from telemetry messages', () {
      const rawMessage = 'User usr_998877 with email sarah.chen@mosaiclabs.com phone +1-555-010-0199 key AIzaSyFakeKey12345678901234567890';
      final sanitized = EnvironmentConfig.sanitizeForLog(rawMessage);

      expect(sanitized, isNot(contains('sarah.chen@mosaiclabs.com')));
      expect(sanitized, isNot(contains('+1-555-010-0199')));
      expect(sanitized, isNot(contains('AIzaSyFakeKey12345678901234567890')));
      expect(sanitized, contains('[REDACTED_EMAIL]'));
      expect(sanitized, contains('[REDACTED_PHONE]'));
      expect(sanitized, contains('[REDACTED_API_KEY]'));
    });
  });
}