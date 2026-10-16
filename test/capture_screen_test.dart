import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/widgets/business_card_capture_view.dart';
import 'package:recaller/features/capture/widgets/capture_empty_state.dart';
import 'package:recaller/features/capture/widgets/capture_error_view.dart';
import 'package:recaller/features/capture/widgets/capture_header.dart';
import 'package:recaller/features/capture/widgets/capture_method_card.dart';
import 'package:recaller/features/capture/widgets/capture_method_grid.dart';
import 'package:recaller/features/capture/widgets/capture_recent_list.dart';
import 'package:recaller/features/capture/widgets/capture_review_view.dart';
import 'package:recaller/features/capture/widgets/capture_success_view.dart';
import 'package:recaller/features/capture/widgets/photo_doc_capture_view.dart';
import 'package:recaller/features/capture/widgets/quick_note_capture_view.dart';
import 'package:recaller/features/capture/widgets/voice_capture_view.dart';
import 'package:recaller/features/home/models/home_mock_data.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/screens/home/home_screen.dart';
import 'package:recaller/screens/people/people_screen.dart';
import 'package:recaller/screens/ask/ask_screen.dart';
import 'package:recaller/screens/activity/activity_screen.dart';
import 'package:recaller/screens/follow_ups/follow_ups_screen.dart';

Widget _createTestWidget(Widget child) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    onGenerateRoute: (settings) {
      if (settings.name != null && settings.name!.startsWith('/captures/')) {
        return MaterialPageRoute(builder: (_) => Scaffold(body: Text('Capture Details ${settings.name}')));
      }
      return null;
    },
    routes: {
      '/person/per_arjun': (context) => const Scaffold(body: Text('Person Details Arjun')),
      '/person/per_vivek': (context) => const Scaffold(body: Text('Person Details Vivek')),
      '/person/per_priya': (context) => const Scaffold(body: Text('Person Details Priya')),
      '/interaction/int_101': (context) => const Scaffold(body: Text('Interaction Details int_101')),
    },
    home: Scaffold(body: child),
  );
}

void main() {
  group('Omni-Capture Hub Phase 11 Tests', () {
    // 1. Capture Hub renders
    testWidgets('1. Capture Hub renders header, method grid, and recent captures', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureHeader), findsOneWidget);
      expect(find.text('Omni-Capture Hub'), findsOneWidget);
      expect(find.byType(CaptureMethodGrid), findsOneWidget);
      expect(find.byType(CaptureRecentList), findsOneWidget);
    });

    // 2. All capture methods render
    testWidgets('2. All 5 capture methods render in method grid', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureMethodCard), findsNWidgets(5));
      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Business Card')), findsOneWidget);
      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Voice Memo')), findsOneWidget);
      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Quick Note')), findsOneWidget);
      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Capture Photo')), findsOneWidget);
      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Add Document')), findsOneWidget);
    });

    // 3. Business Card mode opens
    testWidgets('3. Tapping Business Card opens card scanning view', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Business Card')));
      await tester.pumpAndSettle();

      expect(find.byType(BusinessCardCaptureView), findsOneWidget);
      expect(find.text('Align visiting card inside frame'), findsOneWidget);
      expect(find.text('Scan & Extract'), findsOneWidget);
    });

    // 4. Voice mode opens
    testWidgets('4. Tapping Voice Memo opens voice capture view', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Voice Memo')));
      await tester.pumpAndSettle();

      expect(find.byType(VoiceCaptureView), findsOneWidget);
      expect(find.text('What would you like Recallr to remember?'), findsOneWidget);
      expect(find.text('Start Recording'), findsOneWidget);
    });

    // 5. Quick Note mode opens
    testWidgets('5. Tapping Quick Note opens note form view', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Quick Note')));
      await tester.pumpAndSettle();

      expect(find.byType(QuickNoteCaptureView), findsOneWidget);
      expect(find.text('Title / Subject'), findsOneWidget);
      expect(find.text('Notes & Key Context'), findsOneWidget);
    });

    // 6. Photo mode opens
    testWidgets('6. Tapping Capture Photo opens photo upload view', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Capture Photo')));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoDocCaptureView), findsOneWidget);
      expect(find.text('Whiteboard / Slide Photo Attached'), findsOneWidget);
    });

    // 7. Document mode opens
    testWidgets('7. Tapping Add Document opens document upload view', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Add Document')));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoDocCaptureView), findsOneWidget);
      expect(find.text('Document Attached (PDF / Deck)'), findsOneWidget);
    });

    // 8. Business Card processing and review
    testWidgets('8. Business card scan triggers extraction and renders review', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Business Card')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan & Extract'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureReviewView), findsOneWidget);
      expect(find.text('Arjun Mehta'), findsWidgets);
      expect(find.text('Save to Memory'), findsOneWidget);
    });

    // 9. Voice recording and review
    testWidgets('9. Voice recording toggles and processes to review', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Voice Memo')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Recording'));
      await tester.pump();

      expect(find.text('Recording conversation takeaway...'), findsOneWidget);
      expect(find.text('Finish & Process'), findsOneWidget);

      await tester.tap(find.text('Finish & Process'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureReviewView), findsOneWidget);
      expect(find.textContaining('Voice Recording ('), findsWidgets);
    });

    // 10. Quick Note form processing
    testWidgets('10. Quick Note form accepts custom text and context', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Quick Note')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Custom Edge Note');
      await tester.enterText(find.byType(TextField).at(2), 'Dr. Rao');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Memory'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureReviewView), findsOneWidget);
      expect(find.text('Custom Edge Note'), findsOneWidget);
    });

    // 11. Save action creates memory and shows success view
    testWidgets('11. Saving review commits to permanent memory and displays success', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      CaptureItem? savedMemory;

      await tester.pumpWidget(_createTestWidget(CaptureModal(
        onSaved: (item) => savedMemory = item,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Business Card')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan & Extract'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureSuccessView), findsOneWidget);
      expect(find.text('Memory Saved'), findsWidgets);
      expect(find.text('View Memory'), findsOneWidget);
      expect(savedMemory, isNotNull);
    });

    // 12. View Memory navigates to target route
    testWidgets('12. Tapping View Memory navigates to target route', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Business Card')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan & Extract'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Memory'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Capture Details /captures/'), findsOneWidget);
    });

    // 13. Empty state renders
    testWidgets('13. Empty recent captures state renders when no captures exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal(isEmpty: true)));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureEmptyState), findsOneWidget);
      expect(find.text('Your captured memories will appear here.'), findsOneWidget);
    });

    // 14. Error state renders with retry callback
    testWidgets('14. Error state renders with retry button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal(
        isError: true,
        errorMessage: 'OCR processing timeout.',
      )));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureErrorView), findsOneWidget);
      expect(find.text('OCR processing timeout.'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureMethodGrid), findsOneWidget);
    });

    // 15. Header Back button returns to idle
    testWidgets('15. Header back button returns from active mode to method grid', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Quick Note')));
      await tester.pumpAndSettle();

      expect(find.byType(QuickNoteCaptureView), findsOneWidget);

      await tester.tap(find.byTooltip('Back to capture options'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureMethodGrid), findsOneWidget);
    });

    // 16. Recent capture item tap navigates
    testWidgets('16. Tapping recent capture item navigates to entity route', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const CaptureModal()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Visiting Card: Arjun Mehta').first);
      await tester.pumpAndSettle();

      expect(find.text('Person Details Arjun'), findsOneWidget);
    });

    // 17. Home screen Quick Capture triggers modal
    testWidgets('17. Capture from Home screen opens CaptureModal', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(HomeScreen(initialStats: HomeMockData.pulseStats, initialAttentionItems: HomeMockData.attentionItems, initialRecentPeople: HomeMockData.recentPeople, initialRecentMemories: HomeMockData.recentMemories)));
      await tester.pumpAndSettle();

      expect(find.text('Capture an Encounter'), findsOneWidget);
      await tester.tap(find.text('Capture an Encounter'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
      expect(find.text('Omni-Capture Hub'), findsOneWidget);
    });

    // 18. People screen empty state Capture CTA triggers modal
    testWidgets('18. Capture from People screen empty state opens CaptureModal', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PeopleScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Capture First Person'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
    });

    // 19. Ask screen empty state Capture CTA triggers modal
    testWidgets('19. Capture from Ask screen empty state opens CaptureModal', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Capture First Encounter'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
    });

    // 20. Activity screen empty state Capture CTA triggers modal
    testWidgets('20. Capture from Activity screen empty state opens CaptureModal', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const ActivityScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Capture First Encounter'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
    });

    // 21. Follow-ups screen empty state Capture CTA triggers modal
    testWidgets('21. Capture from Follow-ups screen empty state opens CaptureModal', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const FollowUpsScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Capture First Encounter'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
    });

    // 22. Responsive layouts across all viewports
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

        await tester.pumpWidget(_createTestWidget(const CaptureModal()));
        await tester.pumpAndSettle();

        expect(find.byType(CaptureModal), findsOneWidget);
      }
    });
  });
}