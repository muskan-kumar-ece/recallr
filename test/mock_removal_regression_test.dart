import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/activity/widgets/activity_empty_state.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_empty_state.dart';
import 'package:recaller/features/home/widgets/home_empty_state.dart';
import 'package:recaller/features/home/widgets/memory_pulse.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/people/widgets/people_empty_state.dart';
import 'package:recaller/screens/activity/activity_screen.dart';
import 'package:recaller/screens/follow_ups/follow_ups_screen.dart';
import 'package:recaller/screens/home/home_screen.dart';
import 'package:recaller/screens/people/people_screen.dart';
import 'package:recaller/screens/person/person_detail_screen.dart';
import 'package:recaller/data/mock/mock_people_repository.dart';
import 'package:recaller/data/mock/mock_activity_repository.dart';
import 'package:recaller/data/mock/mock_follow_up_repository.dart';

Widget _createTestApp(Widget home) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    routes: {
      '/home': (context) => const Scaffold(body: Text('Home Route')),
      '/people': (context) => const Scaffold(body: Text('People Route')),
      '/ask': (context) => const Scaffold(body: Text('Ask Route')),
      '/activity': (context) => const Scaffold(body: Text('Activity Route')),
    },
    home: Material(child: home),
  );
}

void main() {
  group('Phase 13G-01-B Mock Removal & Real Source of Truth Regression Tests', () {
    // 1. Empty State on HomeScreen: 0 counts, authentic empty state, no mock metrics
    testWidgets('1. Empty HomeScreen renders 0 metrics and genuine HomeEmptyState without mock data', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptyPeopleRepo = MockPeopleRepository(initialPeople: []);
      final emptyActivityRepo = MockActivityRepository(initialActivities: []);
      final emptyFollowUpRepo = MockFollowUpRepository(initialFollowUps: []);

      await tester.pumpWidget(
        _createTestApp(
          HomeScreen(
            peopleRepository: emptyPeopleRepo,
            activityRepository: emptyActivityRepo,
            followUpRepository: emptyFollowUpRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect HomeEmptyState
      expect(find.byType(HomeEmptyState), findsOneWidget);
      expect(find.text('Your professional memory starts here.'), findsOneWidget);
      expect(find.text('Capture First Encounter'), findsOneWidget);

      // Verify NO fake mock counts (like 42 People or 18 Companies) are rendered
      expect(find.text('42'), findsNothing);
      expect(find.text('18'), findsNothing);
      expect(find.text('Priya Sharma'), findsNothing);
      expect(find.text('Vivek Raghavan'), findsNothing);
    });

    // 2. Empty State on PeopleScreen: genuine PeopleEmptyState, 0 items
    testWidgets('2. Empty PeopleScreen renders genuine PeopleEmptyState without fallback contacts', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptyPeopleRepo = MockPeopleRepository(initialPeople: []);

      await tester.pumpWidget(
        _createTestApp(
          PeopleScreen(
            repository: emptyPeopleRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PeopleEmptyState), findsOneWidget);
      expect(find.text('Your professional memory starts here.'), findsOneWidget);
      expect(find.text('Capture First Person'), findsOneWidget);

      // Verify no mock names
      expect(find.text('Priya Sharma'), findsNothing);
      expect(find.text('Arjun Mehta'), findsNothing);
      expect(find.text('Dr. K. S. Rao'), findsNothing);
    });

    // 3. Empty State on ActivityScreen: genuine ActivityEmptyState, 0 items
    testWidgets('3. Empty ActivityScreen renders genuine ActivityEmptyState without mock timeline items', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptyActivityRepo = MockActivityRepository(initialActivities: []);

      await tester.pumpWidget(
        _createTestApp(
          ActivityScreen(
            repository: emptyActivityRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActivityEmptyState), findsOneWidget);
      expect(find.text('Your professional timeline is still quiet.'), findsOneWidget);
      expect(find.text('Capture First Encounter'), findsOneWidget);

      // Verify no mock items
      expect(find.text('TiE Global Summit'), findsNothing);
      expect(find.text('Indiranagar Portfolio Mixer'), findsNothing);
    });

    // 4. Empty State on FollowUpsScreen: genuine FollowUpEmptyState, 0 items
    testWidgets('4. Empty FollowUpsScreen renders genuine FollowUpEmptyState without mock commitments', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptyFollowUpRepo = MockFollowUpRepository(initialFollowUps: []);

      await tester.pumpWidget(
        _createTestApp(
          FollowUpsScreen(
            repository: emptyFollowUpRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpEmptyState), findsOneWidget);
      expect(find.text('No follow-ups yet'), findsOneWidget);
      expect(find.text('Capture First Encounter'), findsOneWidget);

      // Verify no mock commitments
      expect(find.text('Send API specs to Arjun'), findsNothing);
      expect(find.text('Vivek will send hardware architecture'), findsNothing);
    });

    // 5. Unknown Person ID on PersonDetailScreen: genuine Person Not Found state, NO Priya Sharma fallback
    testWidgets('5. Unknown person ID renders Person Not Found error without Priya Sharma fallback', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _createTestApp(
          const PersonDetailScreen(
            personId: 'not_found',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Person Not Found'), findsOneWidget);
      expect(find.text('No relationship memory matches ID "not_found".'), findsOneWidget);
      expect(find.text('Back to People'), findsOneWidget);

      // Verify no fallback data
      expect(find.text('Priya Sharma'), findsNothing);
      expect(find.text('Principal Architect · Microsoft'), findsNothing);
    });

    // 6. Populated real repository yields exact data without mock injections
    testWidgets('6. Populated repository streams exact custom items into HomeScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final customPeople = [
        const PersonItem(
          id: 'custom_per_1',
          name: 'Sundar Pichai',
          role: 'CEO',
          company: 'Alphabet Inc.',
          initials: 'SP',
          capabilities: ['Leadership', 'AI Strategy'],
          interactionCount: 1,
          relationshipType: RelationshipContextType.collaborator,
        ),
      ];

      final customActivities = [
        const ActivityItem(
          id: 'custom_act_1',
          title: 'Google I/O Keynote Sync',
          summary: 'Discussed Gemini 2.0 deployment roadmap',
          timestamp: '2h ago',
          type: ActivityType.meeting,
          period: TimelinePeriod.today,
          personId: 'custom_per_1',
          personName: 'Sundar Pichai',
          companyId: 'comp_alphabet',
          companyName: 'Alphabet Inc.',
          actionLabel: 'View Meeting',
          targetRoute: '/activity/custom_act_1',
        ),
      ];

      final customPeopleRepo = MockPeopleRepository(initialPeople: customPeople);
      final customActivityRepo = MockActivityRepository(initialActivities: customActivities);
      final emptyFollowUpRepo = MockFollowUpRepository(initialFollowUps: []);

      await tester.pumpWidget(
        _createTestApp(
          HomeScreen(
            peopleRepository: customPeopleRepo,
            activityRepository: customActivityRepo,
            followUpRepository: emptyFollowUpRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect populated memory pulse with exact count (1 Person, 1 Company, 1 Interaction, 0 Follow-ups)
      expect(find.byType(MemoryPulse), findsOneWidget);
      expect(find.text('Sundar Pichai'), findsWidgets);
      expect(find.text('Google I/O Keynote Sync'), findsWidgets);

      // Verify no mock data polluted the feed
      expect(find.text('Priya Sharma'), findsNothing);
      expect(find.text('TiE Global Summit'), findsNothing);
    });
  });
}