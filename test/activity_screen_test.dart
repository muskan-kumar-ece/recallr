import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/core/widgets/widgets.dart';
import 'package:recaller/features/activity/widgets/activity_detail_context.dart';
import 'package:recaller/features/activity/widgets/activity_filters.dart';
import 'package:recaller/features/activity/widgets/activity_header.dart';
import 'package:recaller/features/activity/widgets/activity_loading_state.dart';
import 'package:recaller/features/activity/widgets/activity_search.dart';
import 'package:recaller/features/activity/widgets/activity_timeline.dart';
import 'package:recaller/features/activity/widgets/activity_timeline_group.dart';
import 'package:recaller/screens/activity/activity_screen.dart';

Widget _createTestWidget(Widget child) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    routes: {
      '/person/per_priya': (context) => const Scaffold(body: Text('Person Details Priya')),
      '/person/per_arjun': (context) => const Scaffold(body: Text('Person Details Arjun')),
      '/person/per_vivek': (context) => const Scaffold(body: Text('Person Details Vivek')),
      '/person/per_vikram': (context) => const Scaffold(body: Text('Person Details Vikram')),
      '/person/per_sarah': (context) => const Scaffold(body: Text('Person Details Sarah')),
      '/follow-up/fol_101': (context) => const Scaffold(body: Text('Follow-up Details fol_101')),
      '/interaction/int_101': (context) => const Scaffold(body: Text('Interaction Details int_101')),
      '/interaction/int_102': (context) => const Scaffold(body: Text('Interaction Details int_102')),
      '/interaction/int_104': (context) => const Scaffold(body: Text('Interaction Details int_104')),
      '/file/fil_301': (context) => const Scaffold(body: Text('File Details fil_301')),
      '/company/comp_tensorflight': (context) => const Scaffold(body: Text('Company Details TensorFlight')),
    },
    home: Scaffold(body: child),
  );
}

void main() {
  group('ActivityScreen Phase 09 Relationship Timeline Tests', () {
    // 1. Populated timeline renders
    testWidgets('1. Populated timeline renders with timeline groups and cards', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityTimeline), findsOneWidget);
      expect(find.byType(ActivityTimelineGroup), findsWidgets);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('EARLIER'), findsOneWidget);

      expect(find.text('Meeting with Priya Sharma'), findsWidgets);
      expect(find.text('Visiting Card Scanned for Arjun Mehta'), findsOneWidget);
    });

    // 2. Header renders
    testWidgets('2. Header renders editorial title and subtitle', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityHeader), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Your professional memory, in chronological context.'), findsOneWidget);
    });

    // 3. Search renders
    testWidgets('3. Search bar renders with placeholder', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ActivitySearch), findsOneWidget);
      expect(find.text('Search your activity...'), findsOneWidget);
    });

    // 4. All filters render
    testWidgets('4. All 8 category filter chips render', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityFilters), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Meetings'), findsOneWidget);
      expect(find.text('Calls'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Captures'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Follow-ups'), findsOneWidget);
    });

    // 5. Filter selection changes visible activities
    testWidgets('5. Filter selection filters activities by category', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      // Tap on 'Meetings' filter chip
      await tester.tap(find.text('Meetings'));
      await tester.pumpAndSettle();

      expect(find.text('Meeting with Priya Sharma'), findsWidgets);
      expect(find.text('Visiting Card Scanned for Arjun Mehta'), findsNothing);
      expect(find.text('Send API specifications to Arjun'), findsNothing);
    });

    // 6. Search filters activity
    testWidgets('6. Search query filters activities by keyword', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'RISC-V');
      await tester.pumpAndSettle();

      expect(find.text('Meeting with Priya Sharma'), findsWidgets);
      expect(find.text('File Attached: riscv_v2_spec.pdf'), findsOneWidget);
      expect(find.text('Visiting Card Scanned for Arjun Mehta'), findsNothing);
    });

    // 7. Search-empty state works
    testWidgets('7. Search-empty state renders when query matches nothing', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonExistentPersonOrTopic123');
      await tester.pumpAndSettle();

      expect(find.text('No activity matches this search.'), findsOneWidget);
      expect(find.text('Clear Search & Filters'), findsOneWidget);

      // Tap 'Clear Search & Filters'
      await tester.tap(find.text('Clear Search & Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Meeting with Priya Sharma'), findsWidgets);
    });

    // 8. Empty state works
    testWidgets('8. Complete empty state renders when timeline is empty', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      expect(find.text('Your professional timeline is still quiet.'), findsOneWidget);
      expect(find.text('Capture First Encounter'), findsOneWidget);
    });

    // 9. Empty-state Capture CTA opens CaptureModal
    testWidgets('9. Empty-state Capture CTA opens CaptureModal', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool captureOpened = false;
      await tester.pumpWidget(_createTestWidget(ActivityScreen(
        isEmpty: true,
        onCapture: () => captureOpened = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Capture First Encounter'));
      await tester.pumpAndSettle();

      expect(captureOpened, isTrue);
    });

    // 10. Loading state works
    testWidgets('10. Loading state renders skeleton placeholders', (tester) async {
      await tester.pumpWidget(_createTestWidget(const ActivityScreen(isLoading: true)));
      await tester.pump();

      expect(find.byType(ActivityLoadingState), findsOneWidget);
      expect(find.byType(RecallrSkeleton), findsWidgets);
    });

    // 11. Error state works
    testWidgets('11. Error state renders with message and retry callback', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_createTestWidget(ActivityScreen(
        isError: true,
        errorMessage: "We couldn't load your activity. Please try again.",
        onRetry: () => retried = true,
      )));
      await tester.pumpAndSettle();

      expect(find.byType(RecallrErrorState), findsOneWidget);
      expect(find.text("We couldn't load your activity. Please try again."), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    // 12. Person activity navigates to /person/:id
    testWidgets('12. Person encounter or card tap navigates to /person/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      // Tap on 'View Person' for Arjun Mehta
      await tester.tap(find.text('View Person').first);
      await tester.pumpAndSettle();

      expect(find.text('Person Details Arjun'), findsOneWidget);
    });

    // 13. Follow-up activity navigates to /follow-up/:id
    testWidgets('13. Follow-up action button navigates to /follow-up/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Follow-up'));
      await tester.pumpAndSettle();

      expect(find.text('Follow-up Details fol_101'), findsOneWidget);
    });

    // 14. Interaction activity navigates correctly
    testWidgets('14. Interaction activity navigates to /interaction/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Memory').first);
      await tester.pumpAndSettle();

      expect(find.text('Interaction Details int_101'), findsOneWidget);
    });

    // 15. File activity navigates correctly
    testWidgets('15. File activity navigates to /file/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('View File'));
      await tester.tap(find.text('View File'));
      await tester.pumpAndSettle();

      expect(find.text('File Details fil_301'), findsOneWidget);
    });

    // 16. Company activity navigates correctly
    testWidgets('16. Company activity navigates to /company/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('View Company'));
      await tester.tap(find.text('View Company'));
      await tester.pumpAndSettle();

      expect(find.text('Company Details TensorFlight'), findsOneWidget);
    });

    // 17. Responsive layouts render without overflow across all viewports
    testWidgets('17. Responsive layouts render across all viewports without overflow', (tester) async {
      final viewports = [
        const Size(360, 640),   // Compact mobile
        const Size(390, 844),   // Standard iPhone
        const Size(430, 932),   // Large mobile
        const Size(768, 1024),  // Tablet
        const Size(1024, 768),  // Tablet Landscape / Small Desktop
        const Size(1440, 900),  // Desktop Wide
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(ActivityScreen), findsOneWidget);
      }
    });

    // 18. Tablet & Desktop layout renders relationship context inspector on right
    testWidgets('18. Desktop layout renders relationship context inspector', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityDetailContext), findsOneWidget);
      expect(find.text('Relationship Context'), findsOneWidget);
      expect(find.text('View Dossier'), findsOneWidget);
    });

    // 19. Context inspector updates when selecting a different activity
    testWidgets('19. Context inspector updates selection when activity card tapped on desktop', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      // Tap on the second activity card in list (Arjun Mehta card)
      await tester.tap(find.text('Visiting Card Scanned for Arjun Mehta'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityDetailContext), findsOneWidget);
      expect(find.text('Nexus Venture Partners'), findsWidgets);
    });

    // 20. Clear search icon in search bar works reactively
    testWidgets('20. Clear search icon resets search filter', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sarvam');
      await tester.pumpAndSettle();

      expect(find.text('Encounter with Vivek Raghavan'), findsWidgets);
      expect(find.text('Meeting with Priya Sharma'), findsNothing);

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Meeting with Priya Sharma'), findsWidgets);
    });
  });
}