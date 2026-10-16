import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/features/people/widgets/people_empty_state.dart';
import 'package:recaller/features/people/widgets/people_filters.dart';
import 'package:recaller/features/people/widgets/people_header.dart';
import 'package:recaller/features/people/widgets/people_search.dart';
import 'package:recaller/features/people/widgets/person_card.dart';
import 'package:recaller/features/people/widgets/recently_interacted.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/screens/people/people_screen.dart';

Widget _createTestWidget(Widget child) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    routes: {
      '/person/per_301': (context) => const Scaffold(body: Text('Person Details per_301')),
      '/person/per_302': (context) => const Scaffold(body: Text('Person Details per_302')),
      '/person/per_303': (context) => const Scaffold(body: Text('Person Details per_303')),
    },
    home: Scaffold(body: child),
  );
}

void main() {
  group('PeopleScreen Phase 06 Tests', () {
    testWidgets('renders populated directory correctly on mobile', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PeopleScreen()));
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.byType(PeopleHeader), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.textContaining('REMEMBERED'), findsOneWidget);

      // 2. Search Field
      expect(find.byType(PeopleSearch), findsOneWidget);
      expect(find.text('Search people you remember (skills, companies, events)...'), findsOneWidget);

      // 3. Filters
      expect(find.byType(PeopleFilters), findsOneWidget);
      expect(find.text('All People'), findsOneWidget);
      expect(find.text('Follow-up Due'), findsOneWidget);

      // 4. Recently Interacted Section
      expect(find.byType(RecentlyInteractedSection), findsOneWidget);
      expect(find.text('Recently Interacted'), findsOneWidget);

      // 5. Person Cards
      expect(find.byType(PersonCard), findsWidgets);
      expect(find.text('Priya Sharma'), findsWidgets);
      expect(find.text('Vivek Raghavan'), findsWidgets);
      expect(find.text('Dr. K. S. Rao'), findsWidgets);
    });

    testWidgets('person card tap navigates to /person/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PeopleScreen()));
      await tester.pumpAndSettle();

      // Tap on Priya Sharma card
      await tester.tap(find.text('Priya Sharma').first);
      await tester.pumpAndSettle();

      expect(find.text('Person Details per_301'), findsOneWidget);
    });

    testWidgets('search query filters people correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PeopleScreen()));
      await tester.pumpAndSettle();

      // Search by capability keyword 'Quantum'
      await tester.enterText(find.byType(TextField), 'Quantum');
      await tester.pumpAndSettle();

      expect(find.text('Dr. K. S. Rao'), findsOneWidget);
      expect(find.text('Vivek Raghavan'), findsNothing);
    });

    testWidgets('filter selection filters people correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PeopleScreen()));
      await tester.pumpAndSettle();

      // Select 'Follow-up Due' filter
      await tester.tap(find.text('Follow-up Due'));
      await tester.pumpAndSettle();

      // Priya Sharma and Arjun Mehta have follow-ups; Vivek Raghavan does not
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Arjun Mehta'), findsOneWidget);
      expect(find.text('Vivek Raghavan'), findsNothing);
    });

    testWidgets('renders search-empty state when query matches no one', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PeopleScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonexistentQueryXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No remembered people found'), findsOneWidget);
      expect(find.text('Clear Search & Filters'), findsOneWidget);

      // Tap clear CTA
      await tester.tap(find.text('Clear Search & Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Priya Sharma'), findsWidgets);
    });

    testWidgets('renders empty onboarding state with Capture CTA when isEmpty is true', (tester) async {
      await tester.pumpWidget(_createTestWidget(const PeopleScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      expect(find.byType(PeopleEmptyState), findsOneWidget);
      expect(find.text('Your professional memory starts here.'), findsOneWidget);
      expect(find.text('Capture First Person'), findsOneWidget);

      // Tap Capture CTA
      await tester.tap(find.text('Capture First Person'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
    });

    testWidgets('renders loading skeleton when isLoading is true', (tester) async {
      await tester.pumpWidget(_createTestWidget(const PeopleScreen(isLoading: true)));
      await tester.pump();

      expect(find.byType(PeopleHeader), findsNothing);
      expect(find.byType(PeopleSearch), findsNothing);
    });

    testWidgets('renders error state with retry action', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_createTestWidget(PeopleScreen(
        isError: true,
        onRetry: () => retried = true,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining("We couldn't load your people directory"), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets('renders 2-column layout on desktop viewports without overflow', (tester) async {
      final viewports = [
        const Size(360, 640),  // Compact mobile
        const Size(768, 1024), // Tablet
        const Size(1440, 900), // Desktop wide
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_createTestWidget(const PeopleScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PeopleScreen), findsOneWidget);
      }
    });
  });
}