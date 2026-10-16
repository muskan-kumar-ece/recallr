import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/features/home/widgets/home_empty_state.dart';
import 'package:recaller/features/home/widgets/home_header.dart';
import 'package:recaller/features/home/widgets/memory_pulse.dart';
import 'package:recaller/features/home/widgets/memory_search_card.dart';
import 'package:recaller/features/home/widgets/needs_attention.dart';
import 'package:recaller/features/home/widgets/quick_capture_tile.dart';
import 'package:recaller/features/home/widgets/recent_memories.dart';
import 'package:recaller/features/home/widgets/recent_people.dart';
import 'package:recaller/features/home/models/home_mock_data.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/screens/home/home_screen.dart';

Widget _createTestWidget(Widget child) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    routes: {
      '/ask': (context) => const Scaffold(body: Text('Grounded Memory Engine')),
      '/follow-up/fol_101': (context) => const Scaffold(body: Text('Follow-up Details fol_101')),
      '/person/per_301': (context) => const Scaffold(body: Text('Person Details per_301')),
      '/person/per_302': (context) => const Scaffold(body: Text('Person Details per_302')),
      '/people': (context) => const Scaffold(body: Text('People Directory')),
      '/activity': (context) => const Scaffold(body: Text('Activity Screen')),
    },
    home: Scaffold(body: child),
  );
}

void main() {
  group('HomeScreen Phase 05 Tests', () {
    testWidgets('renders all populated sections correctly on mobile', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(HomeScreen(
        userName: 'Arjun Sharma',
        initialStats: HomeMockData.pulseStats,
        initialAttentionItems: HomeMockData.attentionItems,
        initialRecentPeople: HomeMockData.recentPeople,
        initialRecentMemories: HomeMockData.recentMemories,
      )));
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.descendant(of: find.byType(HomeHeader), matching: find.textContaining('Arjun')), findsOneWidget);
      expect(find.text('SYNCED'), findsOneWidget);

      // 2. Search card
      expect(find.byType(MemorySearchCard), findsOneWidget);
      expect(find.text('Ask your memory...'), findsOneWidget);

      // 3. Memory Pulse
      expect(find.byType(MemoryPulse), findsOneWidget);
      expect(find.text('42'), findsOneWidget); // People count
      expect(find.text('18'), findsOneWidget); // Companies count

      // 4. Needs Attention
      expect(find.byType(NeedsAttentionSection), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('Send API Specs to Arjun'), findsOneWidget);

      // 5. Key Contacts / Recent People
      expect(find.byType(RecentPeopleSection), findsOneWidget);
      expect(find.text('Key Contacts'), findsOneWidget);
      expect(find.text('Vivek Raghavan'), findsOneWidget);

      // 6. Recent Memories
      expect(find.byType(RecentMemoriesSection), findsOneWidget);
      expect(find.text('Recently Remembered'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsWidgets);

      // 7. Quick Capture Tile
      expect(find.byType(QuickCaptureTile), findsOneWidget);
      expect(find.text('Capture an Encounter'), findsOneWidget);
    });

    testWidgets('search card tap triggers navigation to Ask tab', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MemorySearchCard));
      await tester.pumpAndSettle();

      expect(find.text('Grounded Memory Engine'), findsOneWidget);
    });

    testWidgets('quick capture tile opens CaptureModal bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(QuickCaptureTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(QuickCaptureTile));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
      expect(find.text('Omni-Capture Hub'), findsOneWidget);
    });

    testWidgets('attention item tap triggers parametric route', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(HomeScreen(
        initialAttentionItems: HomeMockData.attentionItems,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send API Specs to Arjun'));
      await tester.pumpAndSettle();

      expect(find.text('Follow-up Details fol_101'), findsOneWidget);
    });

    testWidgets('key contact item tap triggers person route', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(HomeScreen(
        initialRecentPeople: HomeMockData.recentPeople,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vivek Raghavan'));
      await tester.pumpAndSettle();

      expect(find.text('Person Details per_302'), findsOneWidget);
    });

    testWidgets('renders empty state when isEmpty is true', (tester) async {
      await tester.pumpWidget(_createTestWidget(const HomeScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      expect(find.byType(HomeEmptyState), findsOneWidget);
      expect(find.text('Your professional memory starts here.'), findsOneWidget);

      // Tap CTA on empty state
      await tester.tap(find.text('Capture First Encounter'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
    });

    testWidgets('renders loading skeleton when isLoading is true', (tester) async {
      await tester.pumpWidget(_createTestWidget(const HomeScreen(isLoading: true)));
      await tester.pump();

      expect(find.byType(HomeHeader), findsNothing);
      expect(find.byType(MemorySearchCard), findsNothing);
    });

    testWidgets('renders error state with retry action', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_createTestWidget(HomeScreen(
        isError: true,
        onRetry: () => retried = true,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining("We couldn't load your memories"), findsOneWidget);
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

        await tester.pumpWidget(_createTestWidget(const HomeScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(HomeScreen), findsOneWidget);
      }
    });
  });
}