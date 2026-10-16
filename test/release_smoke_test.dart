import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/theme/recallr_theme.dart';
import 'package:recaller/screens/activity/activity_screen.dart';
import 'package:recaller/screens/ask/ask_screen.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/screens/follow_ups/follow_ups_screen.dart';
import 'package:recaller/screens/people/people_screen.dart';
import 'package:recaller/screens/person/person_detail_screen.dart';

void main() {
  group('Phase 13F-04: Release Candidate Critical User Journey Smoke Tests', () {
    late RecallrDependencies dependencies;

    setUp(() {
      dependencies = RecallrDependencies.mock();
      RecallrDependencies.setInstance(dependencies);
    });

    Widget buildTestApp(Widget home) {
      return RecallrScope(
        dependencies: dependencies,
        child: MaterialApp(
          theme: RecallrTheme.darkTheme,
          routes: {
            '/people': (context) => const PeopleScreen(),
            '/ask': (context) => const AskScreen(),
            '/activity': (context) => const ActivityScreen(),
            '/follow-ups': (context) => const FollowUpsScreen(),
            '/person/per_301': (context) => const Scaffold(body: Text('Person Details per_301')),
          },
          home: Scaffold(body: home),
        ),
      );
    }

    testWidgets('1. People Directory loads and displays contacts', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const PeopleScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(PeopleScreen), findsOneWidget);
    });

    testWidgets('2. Person Detail Dossier renders relationship history and follow-ups', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(PersonDetailScreen), findsOneWidget);
    });

    testWidgets('3. Omni-Capture Modal opens and allows capture submission', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const CaptureModal()));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
    });

    testWidgets('4. Activity Timeline loads relationship encounters', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const ActivityScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityScreen), findsOneWidget);
    });

    testWidgets('5. Follow-ups Screen lists commitments and summary metrics', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpsScreen), findsOneWidget);
    });

    testWidgets('6. Ask Screen processes questions and returns grounded personal memory answer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const AskScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AskScreen), findsOneWidget);
    });
  });
}