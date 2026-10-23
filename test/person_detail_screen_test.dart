import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/core/widgets/widgets.dart';
import 'package:recaller/features/person_detail/widgets/ai_relationship_summary.dart';
import 'package:recaller/features/person_detail/widgets/connected_entities_section.dart';
import 'package:recaller/features/person_detail/widgets/person_context_section.dart';
import 'package:recaller/features/person_detail/widgets/person_follow_ups_section.dart';
import 'package:recaller/features/person_detail/widgets/person_memories_section.dart';
import 'package:recaller/features/person_detail/widgets/person_profile_header.dart';
import 'package:recaller/features/person_detail/widgets/person_timeline_section.dart';
import 'package:recaller/features/person_detail/widgets/relationship_intelligence.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/screens/person/person_detail_screen.dart';

Widget _createTestWidget(Widget child) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    routes: {
      '/ask': (context) => const Scaffold(body: Text('Grounded Memory Engine')),
      '/follow-up/fol_103': (context) => const Scaffold(body: Text('Follow-up Details fol_103')),
      '/follow-up/fol_106': (context) => const Scaffold(body: Text('Follow-up Details fol_106')),
      '/company/cmp_microsoft': (context) => const Scaffold(body: Text('Company Details cmp_microsoft')),
      '/event/evt_hyd_2025': (context) => const Scaffold(body: Text('Event Details evt_hyd_2025')),
      '/file/fil_301': (context) => const Scaffold(body: Text('File Details fil_301')),
      '/interaction/int_103': (context) => const Scaffold(body: Text('Interaction Details int_103')),
      '/person/per_304': (context) => const Scaffold(body: Text('Person Details per_304')),
    },
    home: RecallrScope(dependencies: RecallrDependencies.mock(), child: child),
  );
}

void main() {
  group('PersonDetailScreen Phase 12 Relationship Memory Tests', () {
    // 1. Identity rendering
    testWidgets('1. Identity renders avatar, name, role, company, location, and verified checkmark', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(PersonProfileHeader), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Principal Architect · Microsoft'), findsOneWidget);
      expect(find.text('Hyderabad, India'), findsOneWidget);
      expect(find.text('COLLABORATOR'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    // 2. Relationship Snapshot
    testWidgets('2. Relationship Snapshot renders metrics and relationship strength', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(RelationshipIntelligence), findsOneWidget);
      expect(find.text('Relationship Snapshot'), findsOneWidget);
      expect(find.text('First Met'), findsOneWidget);
      expect(find.text('Last Interaction'), findsOneWidget);
      expect(find.text('Interactions'), findsOneWidget);
      expect(find.text('Strong Partner'), findsOneWidget);
    });

    // 3. What Recallr Knows / AI Summary
    testWidgets('3. Memory Summary renders AI Relationship Summary and key takeaways', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(AiRelationshipSummary), findsOneWidget);
      expect(find.text('AI Relationship Summary'), findsOneWidget);
      expect(find.text('GROUNDED'), findsOneWidget);
      expect(find.textContaining('RISC-V acceleration team'), findsOneWidget);
      expect(find.text('Key Context Takeaways'), findsOneWidget);
    });

    // 4. Expertise & Capabilities
    testWidgets('4. Expertise and capability chips render correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(PersonContextSection), findsOneWidget);
      expect(find.text('Expertise & Capabilities'), findsOneWidget);
      expect(find.text('RISC-V Vector Extensions'), findsOneWidget);
      expect(find.text('Embedded AI'), findsOneWidget);
      expect(find.text('On-Device SLMs'), findsOneWidget);
    });

    // 5. Recent Memory & Interaction Timeline
    testWidgets('5. Recent memories and interaction timeline render chronological stream', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(PersonTimelineSection), findsOneWidget);
      expect(find.text('Interaction Timeline'), findsOneWidget);
      expect(find.text('Hyderabad Tech Summit Sync'), findsOneWidget);
      expect(find.text('Visiting Card Scanned & Verified'), findsOneWidget);
    });

    // 6. Active Commitments / Follow-ups
    testWidgets('6. Commitments section renders I PROMISED and THEY PROMISED items', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(PersonFollowUpsSection), findsOneWidget);
      expect(find.text('Active Commitments & Follow-ups'), findsOneWidget);
      expect(find.text('I PROMISED'), findsOneWidget);
      expect(find.text('Check with Priya about RISC-V discussion'), findsOneWidget);
    });

    // 7. Memories & Context Claims
    testWidgets('7. Memories and verified claims section renders evidence items', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(PersonMemoriesSection), findsOneWidget);
      expect(find.text('Memories & Context Claims'), findsOneWidget);
      expect(find.text('VERIFIED'), findsWidgets);
      expect(find.text('Technical Working Focus'), findsOneWidget);
    });

    // 8. Connected Entities
    testWidgets('8. Connected entities render Companies, Events, Files, and Related People', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(ConnectedEntitiesSection), findsOneWidget);
      expect(find.text('Connected Network Entities'), findsOneWidget);
      expect(find.text('Microsoft'), findsOneWidget);
      expect(find.text('Hyderabad Tech Summit 2025'), findsOneWidget);
      expect(find.text('Priya_Sharma_Visiting_Card.pdf'), findsOneWidget);
      expect(find.text('Dr. K. S. Rao'), findsOneWidget);
    });

    // 9. Prompt suggestion chip in Ask About Person card navigates to /ask
    testWidgets('9. Prompt suggestion chip in Ask About Person card navigates to /ask', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('What did we discuss about RISC-V quantization?'));
      await tester.pumpAndSettle();

      expect(find.text('Grounded Memory Engine'), findsOneWidget);
    });

    // 10. Header Ask Recallr button navigates to /ask
    testWidgets('10. Header Ask Recallr button navigates to /ask', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ask Recallr'));
      await tester.pumpAndSettle();

      expect(find.text('Grounded Memory Engine'), findsOneWidget);
    });

    // 11. Header Capture button opens CaptureModal
    testWidgets('11. Header Capture button opens CaptureModal', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(RecallrButton, 'Capture'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
      expect(find.text('Omni-Capture Hub'), findsOneWidget);
    });

    // 12. Action Bar Capture Encounter opens CaptureModal
    testWidgets('12. Action Bar Capture Encounter opens CaptureModal', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Capture Encounter'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureModal), findsOneWidget);
    });

    // 13. Follow-up item tap navigates to /follow-up/:id
    testWidgets('13. Follow-up item tap navigates to /follow-up/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check with Priya about RISC-V discussion'));
      await tester.pumpAndSettle();

      expect(find.text('Follow-up Details fol_103'), findsOneWidget);
    });

    // 14. Interaction timeline tap navigates to /interaction/:id
    testWidgets('14. Interaction timeline tap navigates to /interaction/:id', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hyderabad Tech Summit Sync'));
      await tester.pumpAndSettle();

      expect(find.text('Interaction Details int_103'), findsOneWidget);
    });

    // 15. Connected entity tap navigates to target route
    testWidgets('15. Connected entity tap navigates to target route', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Microsoft'));
      await tester.pumpAndSettle();

      expect(find.text('Company Details cmp_microsoft'), findsOneWidget);
    });

    // 16. Loading state renders skeleton
    testWidgets('16. Loading state renders skeleton loaders', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(
        personId: 'per_301',
        isLoading: true,
      )));
      await tester.pump();

      expect(find.byType(RecallrSkeleton), findsWidgets);
    });

    // 17. Error state renders error message and retry button
    testWidgets('17. Error state renders error message and retry button', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool retried = false;
      await tester.pumpWidget(_createTestWidget(PersonDetailScreen(
        personId: 'per_301',
        isError: true,
        onRetry: () => retried = true,
      )));
      await tester.pumpAndSettle();

      expect(find.byType(RecallrErrorState), findsOneWidget);
      expect(find.text("We couldn't load this person's memory dossier. Please try again."), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    // 18. Not found state renders not found message
    testWidgets('18. Not found state renders not found message and back button', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(
        personId: 'not_found',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Person Not Found'), findsOneWidget);
      expect(find.text('Back to People'), findsOneWidget);
    });

    // 19. Missing context state renders partial memory dossier notice
    testWidgets('19. Partial profile renders missing context notice and Capture CTA', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(
        personId: 'per_partial',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Partial Memory Dossier'), findsOneWidget);
      expect(find.text("Recallr has this person's identity, but there isn't enough conversation history yet."), findsOneWidget);
      expect(find.text('Capture First Encounter'), findsOneWidget);
    });

    // 20. Empty profile renders without error
    testWidgets('20. Empty profile renders without crashing', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(
        personId: 'per_empty',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Anonymous Contact'), findsOneWidget);
      expect(find.text('New Contact'), findsOneWidget);
    });

    // 21. Desktop 2-column layout renders correctly
    testWidgets('21. Desktop viewport renders 2-column layout without overflow', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
      await tester.pumpAndSettle();

      expect(find.byType(PersonProfileHeader), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
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

        await tester.pumpWidget(_createTestWidget(const PersonDetailScreen(personId: 'per_301')));
        await tester.pumpAndSettle();

        expect(find.byType(PersonDetailScreen), findsOneWidget);
      }
    });
  });
}