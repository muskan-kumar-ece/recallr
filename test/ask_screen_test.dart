import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/features/ask/widgets/ask_empty_state.dart';
import 'package:recaller/features/ask/widgets/ask_header.dart';
import 'package:recaller/features/ask/widgets/ask_loading_state.dart';
import 'package:recaller/features/ask/widgets/ask_no_answer_state.dart';
import 'package:recaller/features/ask/widgets/grounded_answer_card.dart';
import 'package:recaller/features/ask/widgets/memory_sources_section.dart';
import 'package:recaller/features/ask/widgets/people_mentions.dart';
import 'package:recaller/features/ask/widgets/question_input.dart';
import 'package:recaller/features/ask/widgets/recent_questions.dart';
import 'package:recaller/features/ask/widgets/suggested_questions.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/screens/ask/ask_screen.dart';

Widget _createTestWidget(Widget child) {
  return RecallrScope(
    dependencies: RecallrDependencies.mock(),
    child: MaterialApp(
      theme: RecallrTheme.darkTheme,
      routes: {
        '/person/per_301': (context) => const Scaffold(body: Text('Person Details per_301')),
        '/person/per_302': (context) => const Scaffold(body: Text('Person Details per_302')),
        '/person/per_303': (context) => const Scaffold(body: Text('Person Details per_303')),
        '/person/per_308': (context) => const Scaffold(body: Text('Person Details per_308')),
        '/interaction/int_301': (context) => const Scaffold(body: Text('Interaction Details int_301')),
        '/file/fil_301': (context) => const Scaffold(body: Text('File Details fil_301')),
        '/follow-up/fol_101': (context) => const Scaffold(body: Text('Follow-up Details fol_101')),
      },
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AskScreen Phase 07 Tests', () {
    // 1. Landing state
    testWidgets('1. Ask landing screen renders header, composer, suggestions, and recents', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AskHeader), findsOneWidget);
      expect(find.text('Ask your memory'), findsOneWidget);
      expect(find.text('GROUNDED MEMORY'), findsOneWidget);

      expect(find.byType(QuestionInput), findsOneWidget);
      expect(find.text('Ask Memory'), findsOneWidget);

      expect(find.byType(SuggestedQuestions), findsOneWidget);
      expect(find.text('Suggested Inquiries'), findsOneWidget);
      expect(find.text('What did I discuss with Priya about RISC-V?'), findsOneWidget);

      expect(find.byType(RecentQuestions), findsOneWidget);
      expect(find.text('Recent Inquiries'), findsOneWidget);
    });

    // 2. Suggested questions render
    testWidgets('2. Suggested questions render all suggested prompts', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen()));
      await tester.pumpAndSettle();

      expect(find.text('What did I discuss with Priya about RISC-V?'), findsOneWidget);
      expect(find.text('Who knows about embedded AI?'), findsOneWidget);
      expect(find.text('What did Vivek promise to send me?'), findsOneWidget);
      expect(find.text('Where did I meet Arjun?'), findsOneWidget);
    });

    // 3. Question can be submitted
    testWidgets('3. Question can be submitted via input text and button', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'What did I discuss with Priya about RISC-V?');
      await tester.pump();
      await tester.tap(find.text('Ask Memory'));
      await tester.pumpAndSettle();

      expect(find.byType(GroundedAnswerCard), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsWidgets);
    });

    // 4. Loading state
    testWidgets('4. Loading state appears when isLoading is true', (tester) async {
      await tester.pumpWidget(_createTestWidget(const AskScreen(isLoading: true)));
      await tester.pump();

      expect(find.byType(AskLoadingState), findsOneWidget);
      expect(find.textContaining('Searching your memory'), findsOneWidget);
    });

    // 5. Grounded answer renders
    testWidgets('5. Grounded answer renders with grounding metadata', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen(
        initialQuery: 'What did I discuss with Priya about RISC-V?',
      )));
      await tester.pumpAndSettle();

      expect(find.byType(GroundedAnswerCard), findsOneWidget);
      expect(find.text('Grounded Memory Answer'), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsWidgets);
    });

    // 6. Source memories render
    testWidgets('6. Source memories render with citations and verified badge', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen(
        initialQuery: 'What did I discuss with Priya about RISC-V?',
      )));
      await tester.pumpAndSettle();

      expect(find.byType(MemorySourcesSection), findsOneWidget);
      expect(find.text('Source Memories & Evidence'), findsOneWidget);
      expect(find.text('VERIFIED'), findsWidgets);
    });

    // 7. Person source navigates correctly
    testWidgets('7. Person source navigates to /person/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen(
        initialQuery: 'What did I discuss with Priya about RISC-V?',
      )));
      await tester.pumpAndSettle();

      expect(find.byType(PeopleMentions), findsOneWidget);
      await tester.tap(find.text('Priya Sharma').first);
      await tester.pumpAndSettle();

      expect(find.text('Person Details per_301'), findsOneWidget);
    });

    // 8. Follow-up question populates/submits correctly
    testWidgets('8. Follow-up question tap submits follow-up inquiry', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen(
        initialQuery: 'What did I discuss with Priya about RISC-V?',
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('dossier for Priya Sharma'), findsOneWidget);
      await tester.tap(find.textContaining('dossier for Priya Sharma'));
      await tester.pumpAndSettle();

      expect(find.byType(GroundedAnswerCard), findsOneWidget);
    });

    // 9. No-answer state renders
    testWidgets('9. No-answer state renders on ungrounded query', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen(
        initialQuery: 'alien technology on mars colony',
      )));
      await tester.pumpAndSettle();

      expect(find.byType(AskNoAnswerState), findsOneWidget);
      expect(find.text('Insufficient memory evidence'), findsOneWidget);
      expect(find.textContaining('I couldn\'t find enough evidence in your memory'), findsOneWidget);
    });

    // 10. Empty state renders
    testWidgets('10. Empty state renders when isEmpty is true', (tester) async {
      await tester.pumpWidget(_createTestWidget(const AskScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      expect(find.byType(AskEmptyState), findsOneWidget);
      expect(find.text('Your memory is still quiet'), findsOneWidget);
      expect(find.text('Capture First Encounter'), findsOneWidget);
    });

    // 11. Capture CTA opens CaptureModal
    testWidgets('11. Capture CTA opens CaptureModal bottom sheet', (tester) async {
      await tester.pumpWidget(_createTestWidget(const AskScreen(isEmpty: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Capture First Encounter'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
    });

    // 12. Error state renders
    testWidgets('12. Error state renders with retry callback', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_createTestWidget(AskScreen(
        isError: true,
        onRetry: () => retried = true,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining("We couldn't query your memory network"), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    // 13. New conversation clears current answer
    testWidgets('13. New Question button clears current answer and returns to landing state', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const AskScreen(
        initialQuery: 'What did I discuss with Priya about RISC-V?',
      )));
      await tester.pumpAndSettle();

      expect(find.byType(GroundedAnswerCard), findsOneWidget);
      expect(find.text('New Question'), findsOneWidget);

      await tester.tap(find.text('New Question'));
      await tester.pumpAndSettle();

      expect(find.byType(GroundedAnswerCard), findsNothing);
      expect(find.byType(SuggestedQuestions), findsOneWidget);
    });

    // 14. Responsive layouts do not overflow
    testWidgets('14. Responsive layouts render across all breakpoints without overflow', (tester) async {
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

        await tester.pumpWidget(_createTestWidget(const AskScreen(
          initialQuery: 'Where did I meet Arjun?',
        )));
        await tester.pumpAndSettle();

        expect(find.byType(AskScreen), findsOneWidget);
      }
    });
  });
}