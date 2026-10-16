import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/firestore/firestore_activity_repository.dart';
import 'package:recaller/data/firestore/firestore_capture_repository.dart';
import 'package:recaller/data/firestore/firestore_follow_up_repository.dart';
import 'package:recaller/data/firestore/firestore_memory_retrieval_repository.dart';
import 'package:recaller/data/firestore/firestore_people_repository.dart';
import 'package:recaller/data/firestore/firestore_person_detail_repository.dart';
import 'package:recaller/data/mock/mock_people_repository.dart';
import 'package:recaller/data/mock/mock_activity_repository.dart';
import 'package:recaller/data/mock/mock_follow_up_repository.dart';
import 'package:recaller/data/mock/mock_memory_retrieval_repository.dart';
import 'package:recaller/data/mock/mock_person_detail_repository.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/activity/widgets/activity_empty_state.dart';
import 'package:recaller/features/ask/models/ai_answer_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_empty_state.dart';
import 'package:recaller/features/home/widgets/home_empty_state.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/people/widgets/people_empty_state.dart';
import 'package:recaller/screens/activity/activity_screen.dart';
import 'package:recaller/screens/follow_ups/follow_ups_screen.dart';
import 'package:recaller/screens/home/home_screen.dart';
import 'package:recaller/screens/people/people_screen.dart';
import 'package:recaller/services/ai/ai_answer_service.dart';
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
      '/person/per_real_1': (context) => const Scaffold(body: Text('Person per_real_1')),
      '/interaction/int_real_1': (context) => const Scaffold(body: Text('Interaction int_real_1')),
    },
    home: Scaffold(body: child),
  );
}

void main() {
  group('Phase 13G-02: Real Data End-to-End Runtime Truth Gate Tests', () {
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

    testWidgets('2. Empty account renders genuine empty states without demo records',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Home Screen Empty
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
      expect(find.text('Arjun Mehta'), findsNothing);
      expect(find.text('Sarvam AI'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('89'), findsNothing);

      // People Screen Empty
      await tester.pumpWidget(
        _wrapScreen(
          PeopleScreen(
            repository: MockPeopleRepository(initialPeople: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PeopleEmptyState), findsOneWidget);
      expect(find.text('Capture First Person'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsNothing);

      // Activity Screen Empty
      await tester.pumpWidget(
        _wrapScreen(
          ActivityScreen(
            repository: MockActivityRepository(initialActivities: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActivityEmptyState), findsOneWidget);
      expect(find.textContaining('quiet'), findsOneWidget);
      expect(find.text('RISC-V'), findsNothing);

      // Follow-ups Screen Empty
      await tester.pumpWidget(
        _wrapScreen(
          FollowUpsScreen(
            repository: MockFollowUpRepository(initialFollowUps: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpEmptyState), findsOneWidget);
      expect(find.text('No follow-ups yet'), findsOneWidget);
      expect(find.text('Check with Priya about RISC-V discussion'), findsNothing);
    });

    testWidgets('3. Real capture and person data flow cleanly through repository streams into UI',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final realPerson = PersonItem(
        id: 'per_real_1',
        name: 'Samantha Ray',
        role: 'VP of Hardware Systems',
        company: 'Silicon Photonics Labs',
        initials: 'SR',
        locationOrEvent: 'Bangalore DeepTech Summit',
        contextSnippet: 'Discussed optical inter-chip interconnects for wafer-scale clusters.',
        capabilities: const ['Silicon Photonics', 'Hardware Interconnects'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final realActivity = ActivityItem(
        id: 'act_real_1',
        title: 'Silicon Photonics Labs Sync',
        summary: 'Met Samantha Ray to discuss low-latency optical interconnect prototypes.',
        type: ActivityType.meeting,
        timestamp: 'Today Â· 10:30 AM',
        period: TimelinePeriod.today,
        actionLabel: 'View Meeting',
        personName: 'Samantha Ray',
        personRole: 'VP of Hardware Systems',
        companyName: 'Silicon Photonics Labs',
        location: 'Bangalore',
        targetRoute: '/interaction/int_real_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final realFollowUp = FollowUpItem(
        id: 'fol_real_1',
        title: 'Send optical link power budget estimation',
        context: 'Agreed to share internal benchmark results by next Monday.',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        priority: FollowUpPriority.high,
        dueDate: 'Today Â· 5:00 PM',
        personId: 'per_real_1',
        personName: 'Samantha Ray',
        personRole: 'VP of Hardware Systems',
        companyId: 'comp_spl',
        companyName: 'Silicon Photonics Labs',
        targetRoute: '/follow-up/fol_real_1',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final peopleRepo = MockPeopleRepository(initialPeople: [realPerson]);
      final activityRepo = MockActivityRepository(initialActivities: [realActivity]);
      final followUpRepo = MockFollowUpRepository(initialFollowUps: [realFollowUp]);

      // Verify Home Screen with real data
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

      expect(find.text('Samantha Ray'), findsWidgets);
      expect(find.textContaining('Silicon Photonics Labs'), findsWidgets);
      expect(find.text('Silicon Photonics Labs Sync'), findsOneWidget);
      expect(find.text('Send optical link power budget estimation'), findsOneWidget);

      // Verify People Screen with real data
      await tester.pumpWidget(
        _wrapScreen(
          PeopleScreen(repository: peopleRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Samantha Ray'), findsWidgets);
      expect(find.textContaining('Silicon Photonics Labs'), findsWidgets);

      // Verify Activity Screen with real data
      await tester.pumpWidget(
        _wrapScreen(
          ActivityScreen(repository: activityRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Silicon Photonics Labs Sync'), findsWidgets);
      expect(find.textContaining('optical interconnect prototypes'), findsWidgets);

      // Verify Follow-ups Screen with real data
      await tester.pumpWidget(
        _wrapScreen(
          FollowUpsScreen(repository: followUpRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Send optical link power budget estimation'), findsWidgets);
      expect(find.textContaining('Silicon Photonics Labs'), findsWidgets);
    });

    test('4. End-to-end memory retrieval and grounded AI answer generation with real evidence', () async {
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

      final aiService = DeterministicAiAnswerService(
        retrievalService: retrievalService,
      );

      final queryResult = await aiService.answer(
        const AiAnswerRequest(query: 'Who is Sarah Chen?'),
      );

      expect(queryResult.status, equals(AiAnswerStatus.completed));
      expect(queryResult.evidence, isNotEmpty);
      expect(queryResult.answer, contains('Sarah Chen'));
      expect(queryResult.isSuccessful, isTrue);
    });

    test('5. Empty memory returns truthful no-evidence answer without hallucinations', () async {
      final retrievalRepo = MockMemoryRetrievalRepository(
        peopleRepository: MockPeopleRepository(initialPeople: const []),
        activityRepository: MockActivityRepository(initialActivities: const []),
        followUpRepository: MockFollowUpRepository(initialFollowUps: const []),
      );
      final emptyAssembler = RelationshipContextAssembler(
        peopleRepository: retrievalRepo.peopleRepository,
        personDetailRepository: MockPersonDetailRepository(),
        activityRepository: retrievalRepo.activityRepository,
        followUpRepository: retrievalRepo.followUpRepository,
        captureRepository: retrievalRepo.captureRepository,
      );

      final retrievalService = DeterministicMemoryRetrievalService(
        repository: retrievalRepo,
        assembler: emptyAssembler,
      );

      final aiService = DeterministicAiAnswerService(
        retrievalService: retrievalService,
      );

      final emptyResult = await aiService.answer(
        const AiAnswerRequest(query: 'NonExistentPersonQueryXYZ999'),
      );

      expect(emptyResult.status, equals(AiAnswerStatus.empty));
      expect(emptyResult.evidence, isEmpty);
      expect(emptyResult.answer, contains("I don't have enough information in your Recallr memory"));
      expect(emptyResult.answer, isNot(contains('Priya Sharma')));
      expect(emptyResult.answer, isNot(contains('Sarvam AI')));
    });
  });
}