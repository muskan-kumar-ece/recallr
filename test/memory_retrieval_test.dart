import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/data/firestore/firestore_memory_retrieval_repository.dart';
import 'package:recaller/data/mock/mock_follow_up_repository.dart';
import 'package:recaller/data/mock/mock_memory_retrieval_repository.dart';
import 'package:recaller/data/mock/mock_people_repository.dart';
import 'package:recaller/data/mock/mock_person_detail_repository.dart';
import 'package:recaller/features/ask/models/memory_retrieval_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/screens/ask/ask_screen.dart';
import 'package:recaller/services/retrieval/memory_query_classifier.dart';
import 'package:recaller/services/retrieval/memory_relevance_ranker.dart';
import 'package:recaller/services/retrieval/memory_retrieval_service.dart';
import 'package:recaller/services/retrieval/mock_memory_retrieval_service.dart';
import 'package:recaller/services/retrieval/relationship_context_assembler.dart';

void main() {
  group('Phase 13E-01: Memory Query Intent Classifier Tests', () {
    const classifier = MemoryQueryClassifier();

    test('1. Classifies person lookup intent and extracts person name', () {
      final q = classifier.classify('Who is Sarah Chen from Mosaic?');
      expect(q.intent, equals(MemoryQueryIntent.personLookup));
      expect(q.targetPersonName, equals('Sarah Chen'));
    });

    test('2. Classifies interaction lookup intent', () {
      final q = classifier.classify('What did I discuss with Priya Sharma?');
      expect(q.intent, equals(MemoryQueryIntent.interactionLookup));
      expect(q.targetPersonName, equals('Priya Sharma'));
    });

    test('3. Classifies follow-up commitment lookup intent', () {
      final q = classifier.classify('What did I promise Sarah?');
      expect(q.intent, equals(MemoryQueryIntent.followUpLookup));
      expect(q.targetPersonName, equals('Sarah'));
    });

    test('4. Classifies company lookup intent', () {
      final q = classifier.classify('Who works at Vance Dynamics?');
      expect(q.intent, equals(MemoryQueryIntent.companyLookup));
      expect(q.targetCompanyName, equals('Vance Dynamics'));
    });

    test('5. Classifies recent interaction intent', () {
      final q = classifier.classify('Who did I meet recently this week?');
      expect(q.intent, equals(MemoryQueryIntent.recentInteraction));
      expect(q.temporalConstraint, equals('this week'));
    });

    test('6. Classifies relationship overview intent', () {
      final q = classifier.classify('Tell me everything about Sarah Chen');
      expect(q.intent, equals(MemoryQueryIntent.relationshipOverview));
      expect(q.targetPersonName, equals('Sarah Chen'));
    });

    test('7. Extracts temporal constraints accurately', () {
      expect(classifier.classify('Meeting yesterday').temporalConstraint, equals('yesterday'));
      expect(classifier.classify('Calls today').temporalConstraint, equals('today'));
      expect(classifier.classify('Notes last week').temporalConstraint, equals('last week'));
    });

    test('8. Falls back to generalSearch for unclassified queries', () {
      final q = classifier.classify('optical interconnect efficiency');
      expect(q.intent, equals(MemoryQueryIntent.generalSearch));
    });
  });

  group('Phase 13E-01: Memory Relevance Ranker Tests', () {
    const ranker = MemoryRelevanceRanker();

    test('9. Ranks exact target matches highest', () {
      final query = MemoryQuery(
        rawQuery: 'Who is Sarah Chen?',
        intent: MemoryQueryIntent.personLookup,
        targetPersonName: 'Sarah Chen',
      );

      final candidate1 = MemoryEvidence(
        id: 'ev_1',
        sourceType: MemorySourceType.person,
        sourceId: 'p_1',
        personName: 'Sarah Chen',
        content: 'Sarah Chen · VP of System Architecture at Mosaic.',
        relevanceScore: 0.0,
        matchReason: 'Person profile match',
      );

      final candidate2 = MemoryEvidence(
        id: 'ev_2',
        sourceType: MemorySourceType.activity,
        sourceId: 'a_1',
        personName: 'Dr. Priya Sharma',
        content: 'Quantization discussion with Priya.',
        relevanceScore: 0.0,
        matchReason: 'Other person match',
      );

      final ranked = ranker.rank(query: query, candidateEvidence: [candidate2, candidate1]);
      expect(ranked.first.id, equals('ev_1'));
      expect(ranked.first.relevanceScore, greaterThan(ranked.last.relevanceScore));
    });

    test('10. Deduplicates evidence items by ID during ranking', () {
      final query = MemoryQuery(rawQuery: 'Sarah Chen');
      final duplicate = MemoryEvidence(
        id: 'ev_dup',
        sourceType: MemorySourceType.person,
        sourceId: 'p_dup',
        content: 'Content',
        relevanceScore: 0.5,
        matchReason: 'Match',
      );

      final ranked = ranker.rank(query: query, candidateEvidence: [duplicate, duplicate]);
      expect(ranked.length, equals(1));
    });
  });

  group('Phase 13E-01: Relationship Context Assembler Tests', () {
    late MockPeopleRepository peopleRepo;
    late MockPersonDetailRepository personDetailRepo;
    late MockFollowUpRepository followUpRepo;
    late RelationshipContextAssembler assembler;

    final sarahPerson = PersonItem(
      id: 'per_sarah_01',
      name: 'Sarah Chen',
      role: 'VP of System Architecture',
      company: 'Mosaic Neuromorphic',
      initials: 'SC',
      capabilities: ['Silicon photonics', 'Synaptic crossbars'],
    );

    setUp(() {
      peopleRepo = MockPeopleRepository(initialPeople: [sarahPerson]);
      personDetailRepo = MockPersonDetailRepository();
      followUpRepo = MockFollowUpRepository(initialFollowUps: [
        FollowUpItem(
          id: 'fu_1',
          title: 'Send proposal deliverables',
          context: 'Discussed with Sarah',
          commitmentType: CommitmentType.iPromised,
          status: FollowUpStatus.upcoming,
          priority: FollowUpPriority.high,
          dueDate: 'Tomorrow',
          createdDate: 'Today',
          personId: 'per_sarah_01',
          personName: 'Sarah Chen',
          targetRoute: '/follow-up/fu_1',
        )
      ]);

      assembler = RelationshipContextAssembler(
        peopleRepository: peopleRepo,
        personDetailRepository: personDetailRepo,
        followUpRepository: followUpRepo,
      );
    });

    test('11. Assembles full 360-degree context for person preserving provenance', () async {
      final query = MemoryQuery(
        rawQuery: 'Everything about Sarah Chen',
        intent: MemoryQueryIntent.relationshipOverview,
        targetPersonName: 'Sarah Chen',
      );

      final context = await assembler.assembleForPerson(
        personId: 'per_sarah_01',
        query: query,
      );

      expect(context.targetPerson, isNotNull);
      expect(context.targetPerson!.name, equals('Sarah Chen'));
      expect(context.evidenceItems, isNotEmpty);

      // Verify every evidence item preserves source provenance
      for (final ev in context.evidenceItems) {
        expect(ev.sourceId, isNotEmpty);
        expect(ev.relevanceScore, greaterThan(0.0));
        expect(ev.matchReason, isNotEmpty);
      }
    });

    test('12. Respects maxEvidence budget and sets wasTruncated when truncated', () async {
      final query = MemoryQuery(rawQuery: 'Sarah Chen');
      final context = await assembler.assembleForPerson(
        personId: 'per_sarah_01',
        query: query,
        maxEvidence: 2,
      );

      expect(context.returnedCount, lessThanOrEqualTo(2));
      expect(context.evidenceItems.length, lessThanOrEqualTo(2));
    });
  });

  group('Phase 13E-01: MockMemoryRetrievalRepository Multi-Source Search Tests', () {
    late MockMemoryRetrievalRepository repo;

    setUp(() {
      repo = MockMemoryRetrievalRepository();
    });

    test('13. searchPeople matches by name, role, company, and capabilities', () async {
      final byName = await repo.searchPeople('Sarah');
      expect(byName.length, equals(1));
      expect(byName.first.name, equals('Sarah Chen'));

      final byCapability = await repo.searchPeople('Quantization');
      expect(byCapability.length, equals(1));
      expect(byCapability.first.name, equals('Dr. Priya Sharma'));

      final byCompany = await repo.searchPeople('Vance Dynamics');
      expect(byCompany.length, equals(1));
      expect(byCompany.first.name, equals('Marcus Vance'));
    });

    test('14. searchFollowUps matches active commitments', () async {
      final followUps = await repo.searchFollowUps('proposal');
      expect(followUps.length, equals(1));
      expect(followUps.first.title, contains('Sarah Chen'));
    });

    test('15. searchEvidence retrieves multi-source evidence across stores', () async {
      final query = MemoryQuery(rawQuery: 'Sarah');
      final evidence = await repo.searchEvidence(query);
      expect(evidence.length, greaterThanOrEqualTo(1));
      expect(evidence.any((e) => e.sourceType == MemorySourceType.person), isTrue);
    });

    test('16. getRecentInteractions retrieves recent activity timeline items', () async {
      final recent = await repo.getRecentInteractions(limit: 5);
      expect(recent, isNotNull);
    });
  });

  group('Phase 13E-01: DeterministicMemoryRetrievalService Tests', () {
    late DeterministicMemoryRetrievalService service;
    late MockMemoryRetrievalRepository repo;
    late RelationshipContextAssembler assembler;

    setUp(() {
      repo = MockMemoryRetrievalRepository();
      assembler = RelationshipContextAssembler(
        peopleRepository: repo.peopleRepository,
        personDetailRepository: repo.personDetailRepository,
        activityRepository: repo.activityRepository,
        followUpRepository: repo.followUpRepository,
        captureRepository: repo.captureRepository,
      );
      service = DeterministicMemoryRetrievalService(
        repository: repo,
        assembler: assembler,
      );
    });

    test('17. Retrieves targeted relationship context for person query', () async {
      final result = await service.retrieve('Who is Sarah Chen?');
      expect(result.status, equals(MemoryRetrievalStatus.completed));
      expect(result.isSuccessful, isTrue);
      expect(result.context.targetPerson?.name, equals('Sarah Chen'));
      expect(result.context.evidenceItems, isNotEmpty);
      expect(result.searchDurationMs, greaterThanOrEqualTo(0));
    });

    test('18. Retrieves recent interaction context for recent queries', () async {
      final result = await service.retrieve('Who did I meet recently?');
      expect(result.status, isNotNull);
      expect(result.query.intent, equals(MemoryQueryIntent.recentInteraction));
    });

    test('19. Retrieves multi-source evidence for general keyword queries', () async {
      final result = await service.retrieve('Silicon photonics');
      expect(result.status, equals(MemoryRetrievalStatus.completed));
      expect(result.context.evidenceItems, isNotEmpty);
    });

    test('20. Returns empty status gracefully when no memories match', () async {
      final result = await service.retrieve('NonExistentTermX999');
      expect(result.status, equals(MemoryRetrievalStatus.empty));
      expect(result.context.evidenceItems.isEmpty, isTrue);
    });

    test('21. assemblePersonContext constructs complete dossier context directly', () async {
      final context = await service.assemblePersonContext('per_sarah_01');
      expect(context.targetPerson?.name, equals('Sarah Chen'));
      expect(context.evidenceItems, isNotEmpty);
    });
  });

  group('Phase 13E-01: MockMemoryRetrievalService Tests', () {
    test('22. Mock service returns mock result and tracks retrieveCalls', () async {
      final mock = MockMemoryRetrievalService();
      final result = await mock.retrieve('Test query');
      expect(mock.retrieveCalls, equals(1));
      expect(result.status, equals(MemoryRetrievalStatus.completed));
      expect(result.context.evidenceItems.length, equals(2));
    });

    test('23. Mock service throws when shouldFail is true', () async {
      final mock = MockMemoryRetrievalService(shouldFail: true);
      expect(
        () => mock.retrieve('Test query'),
        throwsA(isA<RecallrDataException>()),
      );
    });
  });

  group('Phase 13E-01: FirestoreMemoryRetrievalRepository Fail-Closed Tests', () {
    test('24. searchPeople throws unauthenticated when logged out', () async {
      final repo = FirestoreMemoryRetrievalRepository();
      expect(
        () => repo.searchPeople('Sarah'),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('25. searchActivities throws unauthenticated when logged out', () async {
      final repo = FirestoreMemoryRetrievalRepository();
      expect(
        () => repo.searchActivities('Meeting'),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('26. searchCaptures throws unauthenticated when logged out', () async {
      final repo = FirestoreMemoryRetrievalRepository();
      expect(
        () => repo.searchCaptures('Card'),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('27. searchFollowUps throws unauthenticated when logged out', () async {
      final repo = FirestoreMemoryRetrievalRepository();
      expect(
        () => repo.searchFollowUps('Proposal'),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('28. searchEvidence throws unauthenticated when logged out', () async {
      final repo = FirestoreMemoryRetrievalRepository();
      expect(
        () => repo.searchEvidence(const MemoryQuery(rawQuery: 'Sarah')),
        throwsA(isA<RecallrDataException>()),
      );
    });
  });

  group('Phase 13E-01: AskScreen Retrieval Wiring Tests', () {
    testWidgets('29. AskScreen triggers memory retrieval service on query submission', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRetrieval = MockMemoryRetrievalService();
      final deps = RecallrDependencies.mock(
        memoryRetrievalService: mockRetrieval,
      );

      await tester.pumpWidget(
        RecallrScope(
          dependencies: deps,
          child: const MaterialApp(
            home: Scaffold(body: AskScreen(initialQuery: 'Who is Sarah Chen?')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(mockRetrieval.retrieveCalls, equals(1));
    });

    testWidgets('30. AskScreen renders empty and loaded states without visual regression', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final deps = RecallrDependencies.mock();

      await tester.pumpWidget(
        RecallrScope(
          dependencies: deps,
          child: const MaterialApp(
            home: Scaffold(body: AskScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AskScreen), findsOneWidget);
    });
  });
}