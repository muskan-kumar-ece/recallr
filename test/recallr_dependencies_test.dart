import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/data/data.dart';
import 'package:recaller/repositories/repositories.dart';
import 'package:recaller/screens/activity/activity_screen.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/screens/follow_ups/follow_ups_screen.dart';
import 'package:recaller/screens/people/people_screen.dart';
import 'package:recaller/screens/person/person_detail_screen.dart';

void main() {
  group('Phase 13C-01: Repository Dependency Wiring Tests', () {
    tearDown(() {
      RecallrDependencies.reset();
    });

    test('1. RecallrDependencies.mock() initializes with mock repository implementations', () {
      final deps = RecallrDependencies.mock();
      expect(deps.peopleRepository, isA<MockPeopleRepository>());
      expect(deps.personDetailRepository, isA<MockPersonDetailRepository>());
      expect(deps.activityRepository, isA<MockActivityRepository>());
      expect(deps.followUpRepository, isA<MockFollowUpRepository>());
      expect(deps.captureRepository, isA<MockCaptureRepository>());
    });

    test('2. RecallrDependencies.production() initializes with firestore repository implementations', () {
      final deps = RecallrDependencies.production();
      expect(deps.peopleRepository, isA<FirestorePeopleRepository>());
      expect(deps.personDetailRepository, isA<FirestorePersonDetailRepository>());
      expect(deps.activityRepository, isA<FirestoreActivityRepository>());
      expect(deps.followUpRepository, isA<FirestoreFollowUpRepository>());
      expect(deps.captureRepository, isA<FirestoreCaptureRepository>());
    });

    test('3. RecallrDependencies.instance provides global access and allows overrides', () {
      final defaultInstance = RecallrDependencies.instance;
      expect(defaultInstance.peopleRepository, isA<MockPeopleRepository>());

      final customMock = MockPeopleRepository(initialPeople: []);
      final customDeps = RecallrDependencies.mock(peopleRepository: customMock);
      RecallrDependencies.setInstance(customDeps);

      expect(RecallrDependencies.instance.peopleRepository, equals(customMock));

      RecallrDependencies.reset();
      expect(RecallrDependencies.instance.peopleRepository, isNot(equals(customMock)));
    });

    testWidgets('4. RecallrScope InheritedWidget exposes repositories via BuildContext extension', (tester) async {
      final customMockPeople = MockPeopleRepository();
      final customMockDetail = MockPersonDetailRepository();
      final customMockActivity = MockActivityRepository();
      final customMockFollowUp = MockFollowUpRepository();
      final customMockCapture = MockCaptureRepository();

      final deps = RecallrDependencies(
        peopleRepository: customMockPeople,
        personDetailRepository: customMockDetail,
        activityRepository: customMockActivity,
        followUpRepository: customMockFollowUp,
        captureRepository: customMockCapture,
      );

      late PeopleRepository resolvedPeople;
      late PersonDetailRepository resolvedDetail;
      late ActivityRepository resolvedActivity;
      late FollowUpRepository resolvedFollowUp;
      late CaptureRepository resolvedCapture;
      late Object resolvedMediaStorage;
      late Object resolvedMediaPicker;
      late Object resolvedAudioRecorder;
      late Object resolvedProcessingRepo;
      late Object resolvedProcessingService;
      late Object resolvedOcrService;
      late Object resolvedEntityResolutionService;
      late Object resolvedRelationshipMemoryService;
      late Object resolvedRetrievalRepo;
      late Object resolvedAssembler;
      late Object resolvedRetrievalService;
      late Object resolvedAiAnswerGenerator;
      late Object resolvedAnswerGroundingService;
      late Object resolvedAiAnswerService;
      late Object resolvedGeminiConfig;
      late Object resolvedGeminiProvider;
      late Object resolvedGeminiPromptBuilder;
      late Object resolvedGeminiResponseParser;
      late Object resolvedGroundedValidator;

      await tester.pumpWidget(
        RecallrScope(
          dependencies: deps,
          child: Builder(
            builder: (context) {
              resolvedPeople = context.peopleRepo;
              resolvedDetail = context.personDetailRepo;
              resolvedActivity = context.activityRepo;
              resolvedFollowUp = context.followUpRepo;
              resolvedCapture = context.captureRepo;
              resolvedMediaStorage = context.mediaStorageRepo;
              resolvedMediaPicker = context.mediaPickerService;
              resolvedAudioRecorder = context.audioRecorderService;
              resolvedProcessingRepo = context.captureProcessingRepo;
              resolvedProcessingService = context.captureProcessingService;
              resolvedOcrService = context.ocrService;
              resolvedEntityResolutionService = context.entityResolutionService;
              resolvedRelationshipMemoryService = context.relationshipMemoryService;
              resolvedRetrievalRepo = context.memoryRetrievalRepo;
              resolvedAssembler = context.relationshipContextAssembler;
              resolvedRetrievalService = context.memoryRetrievalService;
              resolvedAiAnswerGenerator = context.aiAnswerGenerator;
              resolvedAnswerGroundingService = context.answerGroundingService;
              resolvedAiAnswerService = context.aiAnswerService;
              resolvedGeminiConfig = context.geminiAiConfiguration;
              resolvedGeminiProvider = context.geminiAiProvider;
              resolvedGeminiPromptBuilder = context.geminiPromptBuilder;
              resolvedGeminiResponseParser = context.geminiResponseParser;
              resolvedGroundedValidator = context.groundedAnswerValidator;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedPeople, equals(customMockPeople));
      expect(resolvedDetail, equals(customMockDetail));
      expect(resolvedActivity, equals(customMockActivity));
      expect(resolvedFollowUp, equals(customMockFollowUp));
      expect(resolvedCapture, equals(customMockCapture));
      expect(resolvedMediaStorage, isNotNull);
      expect(resolvedMediaPicker, isNotNull);
      expect(resolvedAudioRecorder, isNotNull);
      expect(resolvedProcessingRepo, isNotNull);
      expect(resolvedProcessingService, isNotNull);
      expect(resolvedOcrService, isNotNull);
      expect(resolvedEntityResolutionService, isNotNull);
      expect(resolvedRelationshipMemoryService, isNotNull);
      expect(resolvedRetrievalRepo, isNotNull);
      expect(resolvedAssembler, isNotNull);
      expect(resolvedRetrievalService, isNotNull);
      expect(resolvedAiAnswerGenerator, isNotNull);
      expect(resolvedAnswerGroundingService, isNotNull);
      expect(resolvedAiAnswerService, isNotNull);
      expect(resolvedGeminiConfig, isNotNull);
      expect(resolvedGeminiProvider, isNotNull);
      expect(resolvedGeminiPromptBuilder, isNotNull);
      expect(resolvedGeminiResponseParser, isNotNull);
      expect(resolvedGroundedValidator, isNotNull);
    });

    testWidgets('5. PeopleScreen receives injected repository cleanly', (tester) async {
      final customMockPeople = MockPeopleRepository(initialPeople: []);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeopleScreen(
              repository: customMockPeople,
              initialPeople: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PeopleScreen), findsOneWidget);
    });

    testWidgets('6. PersonDetailScreen receives injected repository cleanly', (tester) async {
      final customMockDetail = MockPersonDetailRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonDetailScreen(
              personId: 'per_301',
              repository: customMockDetail,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PersonDetailScreen), findsOneWidget);
    });

    testWidgets('7. ActivityScreen receives injected repository cleanly', (tester) async {
      final customMockActivity = MockActivityRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityScreen(
              repository: customMockActivity,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ActivityScreen), findsOneWidget);
    });

    testWidgets('8. FollowUpsScreen receives injected repository cleanly', (tester) async {
      final customMockFollowUp = MockFollowUpRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpsScreen(
              repository: customMockFollowUp,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FollowUpsScreen), findsOneWidget);
    });

    testWidgets('9. CaptureModal receives injected repository cleanly', (tester) async {
      final customMockCapture = MockCaptureRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaptureModal(
              repository: customMockCapture,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CaptureModal), findsOneWidget);
    });
  });
}