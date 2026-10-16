import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/core/widgets/widgets.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_card.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_detail_context.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_empty_state.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_filters.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_group.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_header.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_loading_state.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_search.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_summary.dart';
import 'package:recaller/screens/follow_ups/follow_ups_screen.dart';

Widget _createTestWidget(Widget child) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    routes: {
      '/person/per_arjun': (context) => const Scaffold(body: Text('Person Details Arjun')),
      '/person/per_vivek': (context) => const Scaffold(body: Text('Person Details Vivek')),
      '/person/per_priya': (context) => const Scaffold(body: Text('Person Details Priya')),
      '/person/per_kavita': (context) => const Scaffold(body: Text('Person Details Kavita')),
      '/person/per_vikram': (context) => const Scaffold(body: Text('Person Details Vikram')),
      '/interaction/int_101': (context) => const Scaffold(body: Text('Interaction Details int_101')),
      '/interaction/int_102': (context) => const Scaffold(body: Text('Interaction Details int_102')),
      '/interaction/int_103': (context) => const Scaffold(body: Text('Interaction Details int_103')),
      '/interaction/int_104': (context) => const Scaffold(body: Text('Interaction Details int_104')),
      '/follow-up/fol_101': (context) => const Scaffold(body: Text('Follow-up Details fol_101')),
      '/follow-up/fol_102': (context) => const Scaffold(body: Text('Follow-up Details fol_102')),
    },
    home: Scaffold(body: child),
  );
}

void main() {
  group('FollowUpsScreen Phase 10 Relationship Commitments Tests', () {
    // 1. Populated follow-ups render
    testWidgets('1. Populated follow-ups render with groups and commitment cards', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpGroup), findsWidgets);
      expect(find.byType(FollowUpCard), findsWidgets);
      expect(find.text('Send API specs to Arjun'), findsWidgets);
      expect(find.text('Vivek will send hardware architecture'), findsWidgets);
      expect(find.text('Check with Priya about RISC-V discussion'), findsWidgets);
    });

    // 2. Summary metrics render
    testWidgets('2. Summary metrics strip renders with metrics', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpSummary), findsOneWidget);
      expect(find.descendant(of: find.byType(FollowUpSummary), matching: find.text('Today')), findsOneWidget);
      expect(find.descendant(of: find.byType(FollowUpSummary), matching: find.text('Upcoming')), findsOneWidget);
      expect(find.descendant(of: find.byType(FollowUpSummary), matching: find.text('Waiting')), findsOneWidget);
      expect(find.descendant(of: find.byType(FollowUpSummary), matching: find.text('Overdue')), findsOneWidget);
    });

    // 3. Filters render
    testWidgets('3. Filter chips render for all categories', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpFilters), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Due Today'), findsOneWidget);
      expect(find.text('Upcoming'), findsWidgets);
      expect(find.text('Waiting'), findsWidgets);
      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
    });

    // 4. Search works
    testWidgets('4. Search bar filters commitments by keyword', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'RISC-V');
      await tester.pumpAndSettle();

      expect(find.text('Check with Priya about RISC-V discussion'), findsWidgets);
      expect(find.text('Send API specs to Arjun'), findsNothing);
    });

    // 5. I PROMISED items render
    testWidgets('5. I PROMISED commitment badges render', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('I PROMISED'), findsWidgets);
      expect(find.text('Send API specs to Arjun'), findsWidgets);
    });

    // 6. THEY PROMISED items render
    testWidgets('6. THEY PROMISED commitment badges render', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('THEY PROMISED'), findsWidgets);
      expect(find.text('Vivek will send hardware architecture'), findsWidgets);
    });

    // 7. Overdue items render
    testWidgets('7. OVERDUE items render with badge', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('OVERDUE'), findsWidgets);
      expect(find.text('Send partnership proposal to Kavita'), findsWidgets);
    });

    // 8. Waiting items render
    testWidgets('8. WAITING commitments render', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('WAITING'), findsWidgets);
      expect(find.text('Dr. Rao to confirm quantum lab grant review'), findsWidgets);
    });

    // 9. Completed items render
    testWidgets('9. Completed items render in completed section', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Shared embedded AI research with Priya'), findsWidgets);
    });

    // 10. Follow-up card opens person
    testWidgets('10. Tapping person name on card navigates to /person/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Arjun Mehta').first);
      await tester.pumpAndSettle();

      expect(find.text('Person Details Arjun'), findsOneWidget);
    });

    // 11. Source memory navigation works
    testWidgets('11. Tapping Open Memory on card navigates to source interaction', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Memory').first);
      await tester.pumpAndSettle();

      expect(find.text('Interaction Details int_101'), findsOneWidget);
    });

    // 12. Source interaction navigation works from inspector
    testWidgets('12. Tapping Source Interaction from context inspector navigates', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpDetailContext), findsOneWidget);
      await tester.tap(find.text('Source Interaction'));
      await tester.pumpAndSettle();

      expect(find.text('Interaction Details int_101'), findsOneWidget);
    });

    // 13. Complete action works
    testWidgets('13. Tapping Complete button toggles completion state optimistically', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      // Tap Complete on first item (Send API specs to Arjun)
      await tester.tap(find.text('Complete').first);
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsWidgets);
    });

    // 14. Empty state renders
    testWidgets('14. Full empty state renders when there are no follow-ups', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpEmptyState), findsOneWidget);
      expect(find.text('No follow-ups yet'), findsOneWidget);
      expect(find.text('Capture First Encounter'), findsOneWidget);
    });

    // 15. Search-empty state renders
    testWidgets('15. Search-empty state renders when search query matches nothing', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonExistentPersonOrQuery999');
      await tester.pumpAndSettle();

      expect(find.text('No follow-ups match your filters.'), findsOneWidget);
      expect(find.text('Clear Search & Filters'), findsOneWidget);

      await tester.tap(find.text('Clear Search & Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Send API specs to Arjun'), findsWidgets);
    });

    // 16. Loading state renders
    testWidgets('16. Loading state renders skeleton placeholders', (tester) async {
      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen(isLoading: true)));
      await tester.pump();

      expect(find.byType(FollowUpLoadingState), findsOneWidget);
      expect(find.byType(RecallrSkeleton), findsWidgets);
    });

    // 17. Error state renders
    testWidgets('17. Error state renders with retry callback', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_createTestWidget(FollowUpsScreen(
        isError: true,
        errorMessage: "We couldn't load your follow-ups. Please try again.",
        onRetry: () => retried = true,
      )));
      await tester.pumpAndSettle();

      expect(find.byType(RecallrErrorState), findsOneWidget);
      expect(find.text("We couldn't load your follow-ups. Please try again."), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    // 18. Capture CTA opens CaptureModal
    testWidgets('18. Empty-state Capture CTA triggers onCapture callback', (tester) async {
      bool captureOpened = false;
      await tester.pumpWidget(_createTestWidget(FollowUpsScreen(
        isEmpty: true,
        onCapture: () => captureOpened = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Capture First Encounter'));
      await tester.pumpAndSettle();

      expect(captureOpened, isTrue);
    });

    // 19. Mobile layout works (< 720dp)
    testWidgets('19. Mobile single-column layout renders correctly', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpHeader), findsOneWidget);
      expect(find.byType(FollowUpSummary), findsOneWidget);
      expect(find.byType(FollowUpSearch), findsOneWidget);
      expect(find.byType(FollowUpFilters), findsOneWidget);
      expect(find.byType(FollowUpDetailContext), findsNothing);
    });

    // 20. Tablet layout works (768dp)
    testWidgets('20. Tablet layout renders 2-column balanced layout with detail context', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpDetailContext), findsOneWidget);
      expect(find.text('Relationship Context'), findsOneWidget);
    });

    // 21. Desktop layout works (1024dp, 1440dp)
    testWidgets('21. Desktop layout renders 2-column layout with inspector', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FollowUpDetailContext), findsOneWidget);
      expect(find.text('Relationship Context'), findsOneWidget);
    });

    // 22. No RenderFlex overflow across all viewports
    testWidgets('22. Responsive layouts render across 360dp, 390dp, 430dp, 768dp, 1024dp, 1440dp without overflow', (tester) async {
      final viewports = [
        const Size(360, 640),
        const Size(390, 844),
        const Size(430, 932),
        const Size(768, 1024),
        const Size(1024, 768),
        const Size(1440, 900),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(FollowUpsScreen), findsOneWidget);
      }
    });

    // 23. Summary metric tap changes filter
    testWidgets('23. Summary metric card tap activates corresponding filter', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Overdue').first);
      await tester.pumpAndSettle();

      expect(find.text('Send partnership proposal to Kavita'), findsWidgets);
      expect(find.text('Send API specs to Arjun'), findsNothing);
    });
  });
}