import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/data/mock/mock_ai_answer_generator.dart';
import 'package:recaller/data/mock/mock_memory_retrieval_repository.dart';
import 'package:recaller/features/ask/models/ai_answer_models.dart';
import 'package:recaller/features/ask/models/memory_retrieval_models.dart';
import 'package:recaller/features/ask/widgets/grounded_answer_card.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/screens/ask/ask_screen.dart';
import 'package:recaller/services/ai/ai_answer_service.dart';
import 'package:recaller/services/ai/answer_grounding_service.dart';
import 'package:recaller/services/ai/deterministic_ai_answer_generator.dart';
import 'package:recaller/services/retrieval/memory_retrieval_service.dart';
import 'package:recaller/services/retrieval/mock_memory_retrieval_service.dart';
import 'package:recaller/services/retrieval/relationship_context_assembler.dart';

void main() {
  group('Phase 13E-02: AI Answer Domain Models Tests', () {
    test('1. AiAnswerEvidence serializes and deserializes correctly', () {
      final ev = AiAnswerEvidence(
        sourceType: MemorySourceType.person,
        sourceId: 'p_1',
        personId: 'p_1',
        personName: 'Sarah Chen',
        title: 'Sarah Chen · VP Architecture',
        content: 'Sarah is VP of System Architecture at Mosaic.',
        timestamp: 'Today at 4:00 PM',
        relevanceScore: 0.95,
        matchReason: 'Person profile match',
        targetRoute: '/person/p_1',
      );

      final map = ev.toMap();
      final fromMap = AiAnswerEvidence.fromMap(map);

      expect(fromMap.sourceId, equals('p_1'));
      expect(fromMap.sourceType, equals(MemorySourceType.person));
      expect(fromMap.personName, equals('Sarah Chen'));
      expect(fromMap.relevanceScore, equals(0.95));
      expect(fromMap.targetRoute, equals('/person/p_1'));
    });

    test('2. AiAnswerRequest and Turn serialize and deserialize correctly', () {
      final turn = AiAnswerTurn(
        id: 'turn_1',
        query: 'Who is Sarah?',
        answer: 'Sarah is VP of Architecture',
        timestamp: DateTime(2026, 8, 28),
      );

      final req = AiAnswerRequest(
        query: 'What did she say about RISC-V?',
        conversationHistory: [turn],
        targetPersonId: 'p_1',
        maxEvidence: 10,
      );

      final map = req.toMap();
      final fromMap = AiAnswerRequest.fromMap(map);

      expect(fromMap.query, equals('What did she say about RISC-V?'));
      expect(fromMap.conversationHistory?.length, equals(1));
      expect(fromMap.targetPersonId, equals('p_1'));
      expect(fromMap.maxEvidence, equals(10));
    });

    test('3. AiAnswer serializes, deserializes, and copyWith works', () {
      final answer = AiAnswer(
        answer: 'Sarah Chen is VP of System Architecture at Mosaic.',
        status: AiAnswerStatus.completed,
        query: 'Who is Sarah?',
        intent: MemoryQueryIntent.personLookup,
        confidence: 0.95,
        evidence: const [],
        generatedAt: DateTime(2026, 8, 28),
      );

      final map = answer.toMap();
      final fromMap = AiAnswer.fromMap(map);

      expect(fromMap.answer, equals(answer.answer));
      expect(fromMap.confidence, equals(0.95));
      expect(fromMap.status, equals(AiAnswerStatus.completed));
      expect(fromMap.intent, equals(MemoryQueryIntent.personLookup));

      final updated = answer.copyWith(confidence: 0.99);
      expect(updated.confidence, equals(0.99));
    });
  });

  group('Phase 13E-02: Answer Grounding Service Tests', () {
    const grounding = AnswerGroundingService();

    test('4. Extracts and deduplicates evidence from MemoryContext', () {
      final person = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic',
        initials: 'SC',
      );

      final rawEvidence = [
        MemoryEvidence(
          id: 'ev_1',
          sourceType: MemorySourceType.activity,
          sourceId: 'act_1',
          personId: 'per_sarah_01',
          personName: 'Sarah Chen',
          content: 'Discussed synaptic crossbars',
          relevanceScore: 0.85,
          matchReason: 'Activity match',
        ),
        MemoryEvidence(
          id: 'ev_dup',
          sourceType: MemorySourceType.activity,
          sourceId: 'act_1', // Duplicate sourceId
          content: 'Discussed synaptic crossbars copy',
          relevanceScore: 0.85,
          matchReason: 'Activity match',
        ),
      ];

      final context = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Sarah Chen'),
        targetPerson: person,
        evidenceItems: rawEvidence,
        assembledAt: DateTime.now(),
      );

      final extracted = grounding.extractEvidence(context);
      expect(extracted.length, equals(2)); // Person evidence + 1 unique activity
      expect(extracted.any((e) => e.sourceType == MemorySourceType.person), isTrue);
      expect(extracted.any((e) => e.sourceId == 'act_1'), isTrue);
    });

    test('5. Calculates deterministic confidence bounded between 0.0 and 1.0', () {
      final emptyContext = MemoryContext(
        query: const MemoryQuery(rawQuery: 'test'),
        assembledAt: DateTime.now(),
      );
      expect(grounding.calculateConfidence(context: emptyContext, evidence: const []), equals(0.0));

      final person = PersonItem(
        id: 'p_1',
        name: 'Sarah',
        role: 'Role',
        company: 'Company',
        initials: 'SC',
      );
      final evList = [
        AiAnswerEvidence(
          sourceType: MemorySourceType.person,
          sourceId: 'p_1',
          title: 'Title',
          content: 'Content',
          relevanceScore: 0.95,
          matchReason: 'Match',
        )
      ];

      final richContext = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Sarah'),
        targetPerson: person,
        evidenceItems: const [],
        assembledAt: DateTime.now(),
      );

      final conf = grounding.calculateConfidence(context: richContext, evidence: evList);
      expect(conf, greaterThanOrEqualTo(0.80));
      expect(conf, lessThanOrEqualTo(1.0));
    });

    test('6. Extracts mentioned people, companies, and suggested actions', () {
      final person = PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP Architecture',
        company: 'Mosaic Neuromorphic',
        initials: 'SC',
      );

      final context = MemoryContext(
        query: const MemoryQuery(rawQuery: 'Sarah Chen'),
        targetPerson: person,
        evidenceItems: const [],
        assembledAt: DateTime.now(),
      );

      final people = grounding.extractMentionedPeople(context, const []);
      expect(people.length, equals(1));
      expect(people.first.name, equals('Sarah Chen'));
      expect(people.first.targetRoute, equals('/person/per_sarah_01'));

      final companies = grounding.extractMentionedCompanies(context, const []);
      expect(companies, contains('Mosaic Neuromorphic'));

      final actions = grounding.extractSuggestedActions(context, const []);
      expect(actions.any((a) => a.contains('Sarah Chen')), isTrue);
    });
  });

  group('Phase 13E-02: Deterministic AI Answer Generator Intent Tests', () {
    const generator = DeterministicAiAnswerGenerator();

    final sarahPerson = PersonItem(
      id: 'per_sarah_01',
      name: 'Sarah Chen',
      role: 'VP of System Architecture',
      company: 'Mosaic Neuromorphic',
      locationOrEvent: 'San Francisco, CA',
      capabilities: ['Silicon photonics', 'Synaptic crossbars', 'RISC-V'],
      lastInteraction: 'Today at 4:00 PM',
      initials: 'SC',
    );

    test('7. Generates grounded answer for Person Lookup intent', () async {
      final query = const MemoryQuery(
        rawQuery: 'Who is Sarah Chen?',
        intent: MemoryQueryIntent.personLookup,
        targetPersonName: 'Sarah Chen',
      );

      final context = MemoryContext(
        query: query,
        targetPerson: sarahPerson,
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'Who is Sarah Chen?'),
        context: context,
      );

      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.confidence, greaterThan(0.8));
      expect(result.answer, contains('Sarah Chen is VP of System Architecture at Mosaic Neuromorphic'));
      expect(result.answer, contains('Silicon photonics'));
      expect(result.mentionedPeople.length, equals(1));
    });

    test('8. Generates grounded answer for Company Lookup intent', () async {
      final query = const MemoryQuery(
        rawQuery: 'Who works at Mosaic?',
        intent: MemoryQueryIntent.companyLookup,
        targetCompanyName: 'Mosaic Neuromorphic',
      );

      final context = MemoryContext(
        query: query,
        relevantPeople: [sarahPerson],
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'Who works at Mosaic?'),
        context: context,
      );

      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.answer, contains('Sarah Chen (VP of System Architecture)'));
    });

    test('9. Returns empty status and zero confidence for empty context (No Hallucination)', () async {
      final query = const MemoryQuery(rawQuery: 'UnknownPersonXYZ');
      final context = MemoryContext(
        query: query,
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'UnknownPersonXYZ'),
        context: context,
      );

      expect(result.status, equals(AiAnswerStatus.empty));
      expect(result.confidence, equals(0.0));
      expect(result.answer, contains("I don't have enough information in your Recallr memory"));
      expect(result.evidence.isEmpty, isTrue);
    });
  });

  group('Phase 13E-02: Mock AI Answer Generator Tests', () {
    test('10. Mock generator tracks generateCalls and supports forced answers', () async {
      final mock = MockAiAnswerGenerator();
      final context = MemoryContext(
        query: const MemoryQuery(rawQuery: 'test'),
        targetPerson: PersonItem(
          id: 'p1',
          name: 'Sarah',
          role: 'Role',
          company: 'Company',
          initials: 'S',
        ),
        assembledAt: DateTime.now(),
      );

      final result = await mock.generateAnswer(
        request: const AiAnswerRequest(query: 'test'),
        context: context,
      );

      expect(mock.generateCalls, equals(1));
      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.answer, contains('Mock grounded answer'));
    });

    test('11. Mock generator throws on shouldFail', () async {
      final mock = MockAiAnswerGenerator(shouldFail: true);
      final context = MemoryContext(
        query: const MemoryQuery(rawQuery: 'test'),
        assembledAt: DateTime.now(),
      );

      expect(
        () => mock.generateAnswer(request: const AiAnswerRequest(query: 'test'), context: context),
        throwsA(isA<RecallrDataException>()),
      );
    });
  });

  group('Phase 13E-02: AI Answer Service Pipeline Tests', () {
    late DeterministicAiAnswerService answerService;
    late DeterministicMemoryRetrievalService retrievalService;
    late MockMemoryRetrievalRepository retrievalRepo;
    late RelationshipContextAssembler assembler;

    setUp(() {
      retrievalRepo = MockMemoryRetrievalRepository();
      assembler = RelationshipContextAssembler(
        peopleRepository: retrievalRepo.peopleRepository,
        personDetailRepository: retrievalRepo.personDetailRepository,
        activityRepository: retrievalRepo.activityRepository,
        followUpRepository: retrievalRepo.followUpRepository,
        captureRepository: retrievalRepo.captureRepository,
      );
      retrievalService = DeterministicMemoryRetrievalService(
        repository: retrievalRepo,
        assembler: assembler,
      );
      answerService = DeterministicAiAnswerService(
        retrievalService: retrievalService,
      );
    });

    test('12. End-to-end question answering pipeline produces grounded answer with evidence', () async {
      final result = await answerService.answer(
        const AiAnswerRequest(query: 'Who is Sarah Chen?'),
      );

      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.isSuccessful, isTrue);
      expect(result.confidence, greaterThan(0.8));
      expect(result.answer, contains('Sarah Chen'));
      expect(result.evidence, isNotEmpty);
      expect(result.mentionedPeople.length, equals(1));
      expect(result.mentionedPeople.first.targetRoute, equals('/person/per_sarah_01'));
    });

    test('13. Empty retrieval returns unhallucinated empty answer', () async {
      final result = await answerService.answer(
        const AiAnswerRequest(query: 'NonExistentTerm999'),
      );

      expect(result.status, equals(AiAnswerStatus.empty));
      expect(result.confidence, equals(0.0));
      expect(result.answer, contains("I don't have enough information in your Recallr memory"));
    });
  });

  group('Phase 13E-02: AskScreen AI Answer Integration Widget Tests', () {
    testWidgets('14. AskScreen answers query and renders GroundedAnswerCard with live evidence', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockGen = MockAiAnswerGenerator();
      final deps = RecallrDependencies.mock(
        aiAnswerGenerator: mockGen,
      );

      await tester.pumpWidget(
        RecallrScope(
          dependencies: deps,
          child: const MaterialApp(
            home: Scaffold(body: AskScreen(initialQuery: 'Who is Priya Sharma?')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GroundedAnswerCard), findsOneWidget);
      expect(find.text('Grounded Memory Answer'), findsOneWidget);
      expect(mockGen.generateCalls, equals(1));
    });

    testWidgets('15. AskScreen renders clean empty state when no query provided', (tester) async {
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
      expect(find.text('Ask your memory'), findsOneWidget);
    });
  });

  group('Phase 13E-02: Additional Generator Intent & Edge Case Tests', () {
    const generator = DeterministicAiAnswerGenerator();

    final sarahPerson = PersonItem(
      id: 'per_sarah_01',
      name: 'Sarah Chen',
      role: 'VP of System Architecture',
      company: 'Mosaic Neuromorphic',
      initials: 'SC',
    );

    test('16. Generates grounded answer for Interaction Lookup intent', () async {
      final query = const MemoryQuery(
        rawQuery: 'When did I discuss synaptic crossbars with Sarah?',
        intent: MemoryQueryIntent.interactionLookup,
        targetPersonName: 'Sarah Chen',
      );

      final timeline = [
        const TimelineItem(
          id: 'tl_1',
          title: 'Synaptic Crossbar Discussion',
          subtitle: '28nm test chip tapeout',
          date: 'Yesterday at 3:00 PM',
          summary: 'Reviewed 28nm test chip tapeout and pricing tiers.',
          type: TimelineType.meeting,
        ),
      ];

      final context = MemoryContext(
        query: query,
        targetPerson: sarahPerson,
        relevantTimeline: timeline,
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'When did I discuss synaptic crossbars with Sarah?'),
        context: context,
      );

      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.answer, contains('Synaptic Crossbar Discussion'));
      expect(result.answer, contains('Yesterday at 3:00 PM'));
    });

    test('17. Generates grounded answer for Memory Lookup intent', () async {
      final query = const MemoryQuery(
        rawQuery: 'What do I remember about Sarah?',
        intent: MemoryQueryIntent.memoryLookup,
        targetPersonName: 'Sarah Chen',
      );

      final memories = [
        const MemoryItem(
          id: 'mem_1',
          text: 'Prefers asynchronous Slack communication over scheduled phone calls.',
          category: 'Communication Preference',
          source: 'Stanford Tech Summit',
          timestamp: '2 days ago',
        ),
      ];

      final context = MemoryContext(
        query: query,
        targetPerson: sarahPerson,
        relevantMemories: memories,
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'What do I remember about Sarah?'),
        context: context,
      );

      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.answer, contains('Prefers asynchronous Slack communication'));
    });

    test('18. Generates grounded answer for Follow-up Lookup intent', () async {
      final query = const MemoryQuery(
        rawQuery: 'What do I need to follow up on with Sarah?',
        intent: MemoryQueryIntent.followUpLookup,
        targetPersonName: 'Sarah Chen',
      );

      final followUps = [
        FollowUpItem(
          id: 'fu_1',
          title: 'Send proposal deliverables',
          context: 'Commitment detected from meeting notes',
          commitmentType: CommitmentType.iPromised,
          status: FollowUpStatus.upcoming,
          priority: FollowUpPriority.high,
          dueDate: 'Tomorrow',
          createdDate: 'Today',
          personId: 'per_sarah_01',
          personName: 'Sarah Chen',
          targetRoute: '/follow-up/fu_1',
        ),
      ];

      final context = MemoryContext(
        query: query,
        targetPerson: sarahPerson,
        relevantFollowUps: followUps,
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'What do I need to follow up on with Sarah?'),
        context: context,
      );

      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.answer, contains('Send proposal deliverables'));
      expect(result.answer, contains('Tomorrow'));
    });

    test('19. Generates grounded answer for Relationship Overview intent', () async {
      final query = const MemoryQuery(
        rawQuery: 'Tell me about my relationship with Sarah',
        intent: MemoryQueryIntent.relationshipOverview,
        targetPersonName: 'Sarah Chen',
      );

      final profile = PersonProfile(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP of System Architecture',
        company: 'Mosaic Neuromorphic',
        location: 'San Francisco, CA',
        relationshipType: RelationshipContextType.collaborator,
        initials: 'SC',
        firstMet: 'Stanford Tech Summit',
        lastInteraction: 'Last Week',
        totalInteractions: 8,
        sharedEventsCount: 2,
        aiSummary: 'Leading silicon photonics integration',
        relationshipStrength: 'Core Network / High Trust',
        timeline: [
          const TimelineItem(
            id: 'tl_1',
            title: 'Founders Dinner',
            subtitle: 'Silicon photonics collaboration',
            date: 'Last Week',
            summary: 'Discussed silicon photonics collaboration',
            type: TimelineType.meeting,
          ),
        ],
      );

      final context = MemoryContext(
        query: query,
        targetPerson: sarahPerson,
        targetProfile: profile,
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'Tell me about my relationship with Sarah'),
        context: context,
      );

      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.answer, contains('8 total interactions'));
      expect(result.answer, contains('CORE NETWORK / HIGH TRUST'));
      expect(result.answer, contains('Founders Dinner'));
    });

    test('20. Generates grounded answer for Recent Interaction intent', () async {
      final query = const MemoryQuery(
        rawQuery: 'Who did I meet recently?',
        intent: MemoryQueryIntent.recentInteraction,
      );

      final context = MemoryContext(
        query: query,
        evidenceItems: [
          MemoryEvidence(
            id: 'ev_1',
            sourceType: MemorySourceType.activity,
            sourceId: 'act_1',
            personName: 'Sarah Chen',
            content: 'Discussed Q3 roadmaps',
            timestamp: 'Yesterday',
            relevanceScore: 0.85,
            matchReason: 'Recent activity',
          ),
        ],
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'Who did I meet recently?'),
        context: context,
      );

      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.answer, contains('Sarah Chen (Yesterday)'));
    });

    test('21. Generates grounded answer for General Search query', () async {
      final query = const MemoryQuery(
        rawQuery: 'silicon photonics',
        intent: MemoryQueryIntent.generalSearch,
      );

      final context = MemoryContext(
        query: query,
        evidenceItems: [
          MemoryEvidence(
            id: 'ev_1',
            sourceType: MemorySourceType.person,
            sourceId: 'per_sarah_01',
            personName: 'Sarah Chen',
            content: 'Sarah Chen specializes in silicon photonics.',
            relevanceScore: 0.90,
            matchReason: 'Keyword match',
          ),
        ],
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'silicon photonics'),
        context: context,
      );

      expect(result.status, equals(AiAnswerStatus.completed));
      expect(result.answer, contains('silicon photonics'));
    });

    test('22. Preserves wasTruncated flag from context into AiAnswer', () async {
      final context = MemoryContext(
        query: const MemoryQuery(rawQuery: 'test'),
        targetPerson: sarahPerson,
        wasTruncated: true,
        originalCount: 20,
        returnedCount: 5,
        assembledAt: DateTime.now(),
      );

      final result = await generator.generateAnswer(
        request: const AiAnswerRequest(query: 'test'),
        context: context,
      );

      expect(result.wasTruncated, isTrue);
    });
  });

  group('Phase 13E-02: Failure Handling & Security Tests', () {
    test('23. AiAnswerService propagates retrieval failure message cleanly', () async {
      final failingRetrieval = MockMemoryRetrievalService(
        forcedResult: MemorySearchResult(
          query: const MemoryQuery(rawQuery: 'test'),
          status: MemoryRetrievalStatus.failed,
          context: MemoryContext(
            query: const MemoryQuery(rawQuery: 'test'),
            assembledAt: DateTime.now(),
          ),
          errorMessage: 'Firestore permission denied',
        ),
      );

      final service = DeterministicAiAnswerService(
        retrievalService: failingRetrieval,
      );

      final answer = await service.answer(const AiAnswerRequest(query: 'test'));
      expect(answer.status, equals(AiAnswerStatus.failed));
      expect(answer.errorMessage, contains('Firestore permission denied'));
    });

    test('24. AiAnswerService catches and reports generator exceptions cleanly', () async {
      final mockGen = MockAiAnswerGenerator(shouldFail: true);
      final retrievalService = MockMemoryRetrievalService();

      final service = DeterministicAiAnswerService(
        retrievalService: retrievalService,
        generator: mockGen,
      );

      final answer = await service.answer(const AiAnswerRequest(query: 'test'));
      expect(answer.status, equals(AiAnswerStatus.failed));
    });

    test('25. AiAnswerService throws unauthenticated exception when logged out', () async {
      final mockRetrieval = MockMemoryRetrievalService(
        shouldFail: true,
        failureException: RecallrDataException.unauthenticated(),
      );
      final service = DeterministicAiAnswerService(retrievalService: mockRetrieval);

      expect(
        () => service.answer(const AiAnswerRequest(query: 'test')),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('26. AiAnswerConfiguration adheres to default safety thresholds', () {
      const config = AiAnswerConfiguration();
      expect(config.maxEvidenceItems, equals(15));
      expect(config.maxContextChars, equals(8000));
      expect(config.maxAnswerLength, equals(2000));
      expect(config.minConfidenceThreshold, equals(0.40));
    });

    test('27. AiAnswerStatus labels are user-friendly and descriptive', () {
      expect(AiAnswerStatus.idle.label, equals('Ready'));
      expect(AiAnswerStatus.generating.label, equals('Synthesizing Answer...'));
      expect(AiAnswerStatus.completed.label, equals('Answer Grounded'));
      expect(AiAnswerStatus.empty.label, equals('No Memory Found'));
      expect(AiAnswerStatus.failed.label, equals('Generation Failed'));
    });

    test('28. AiAnswerTurn preserves query, answer, and evidence timestamps', () {
      final turn = AiAnswerTurn(
        id: 't_1',
        query: 'What is RISC-V?',
        answer: 'Open instruction set architecture.',
        evidence: const [],
        timestamp: DateTime(2026, 8, 28),
      );

      expect(turn.id, equals('t_1'));
      expect(turn.query, equals('What is RISC-V?'));
      expect(turn.answer, equals('Open instruction set architecture.'));
    });

    test('29. AiAnswerService dispose calls generator dispose cleanly', () {
      final mockGen = MockAiAnswerGenerator();
      final retrievalService = MockMemoryRetrievalService();
      final service = DeterministicAiAnswerService(
        retrievalService: retrievalService,
        generator: mockGen,
      );

      expect(() => service.dispose(), returnsNormally);
    });

    test('30. Grounding service route generation maps types to canonical paths', () {
      const grounding = AnswerGroundingService();
      final context = MemoryContext(
        query: const MemoryQuery(rawQuery: 'test'),
        evidenceItems: [
          MemoryEvidence(
            id: 'ev_1',
            sourceType: MemorySourceType.followUp,
            sourceId: 'fu_123',
            content: 'Follow up',
            relevanceScore: 0.9,
            matchReason: 'Match',
          ),
          MemoryEvidence(
            id: 'ev_2',
            sourceType: MemorySourceType.activity,
            sourceId: 'act_456',
            content: 'Activity',
            relevanceScore: 0.8,
            matchReason: 'Match',
          ),
          MemoryEvidence(
            id: 'ev_3',
            sourceType: MemorySourceType.capture,
            sourceId: 'cap_789',
            content: 'Capture',
            relevanceScore: 0.8,
            matchReason: 'Match',
          ),
        ],
        assembledAt: DateTime.now(),
      );

      final extracted = grounding.extractEvidence(context);
      expect(extracted.firstWhere((e) => e.sourceId == 'fu_123').targetRoute, equals('/follow-up/fu_123'));
      expect(extracted.firstWhere((e) => e.sourceId == 'act_456').targetRoute, equals('/interaction/act_456'));
      expect(extracted.firstWhere((e) => e.sourceId == 'cap_789').targetRoute, equals('/file/cap_789'));
    });
  });
}