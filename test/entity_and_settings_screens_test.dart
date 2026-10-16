import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/screens/entities/company_dossier_screen.dart';
import 'package:recaller/screens/entities/event_dossier_screen.dart';
import 'package:recaller/screens/entities/file_dossier_screen.dart';
import 'package:recaller/screens/entities/interaction_dossier_screen.dart';
import 'package:recaller/screens/settings/settings_screen.dart';

Widget _buildWrapper(Widget child) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    routes: {
      '/person/per_priya': (context) => const Scaffold(body: Text('Person Profile Priya')),
      '/people': (context) => const Scaffold(body: Text('People Directory')),
    },
    home: child,
  );
}

void main() {
  group('Production Secondary Dossiers & Settings Tests', () {
    testWidgets('1. InteractionDossierScreen renders with contextual data and memory claims', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildWrapper(const InteractionDossierScreen(
        interactionId: 'int_101',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Interaction Details int_101'), findsOneWidget);
      expect(find.text('Strategic Relationship Encounter'), findsOneWidget);
      expect(find.text('Extracted Relationship Memory'), findsOneWidget);
      expect(find.text('Action Commitments'), findsOneWidget);
      expect(find.text('Network Partner'), findsOneWidget);

      // Verify navigation to person from encounter
      await tester.tap(find.text('Network Partner'));
      await tester.pumpAndSettle();
      expect(find.text('Person Profile Priya'), findsOneWidget);
    });

    testWidgets('2. CompanyDossierScreen renders organization header and affiliate contacts link', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildWrapper(const CompanyDossierScreen(
        companyId: 'comp_tensorflight',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Company Details comp_tensorflight'), findsOneWidget);
      expect(find.text('TENSORFLIGHT'), findsOneWidget);
      expect(find.text('Key Contacts at TENSORFLIGHT'), findsOneWidget);

      // Tap to view network affiliates
      await tester.tap(find.text('Network Affiliates'));
      await tester.pumpAndSettle();
      expect(find.text('People Directory'), findsOneWidget);
    });

    testWidgets('3. EventDossierScreen renders event details and encounter touchpoints', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildWrapper(const EventDossierScreen(
        eventId: 'evt_techcrunch_disrupt',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Event Details evt_techcrunch_disrupt'), findsOneWidget);
      expect(find.text('TECHCRUNCH DISRUPT'), findsOneWidget);
      expect(find.text('EVENT ENCOUNTER'), findsOneWidget);
    });

    testWidgets('4. FileDossierScreen renders document details and secured storage badges', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildWrapper(const FileDossierScreen(
        fileId: 'fil_301',
      )));
      await tester.pumpAndSettle();

      expect(find.text('File Details fil_301'), findsOneWidget);
      expect(find.text('ATTACHMENT'), findsOneWidget);
      expect(find.text('Encounter Document / Slide Deck'), findsOneWidget);
      expect(find.text('Secured Cloud Storage'), findsOneWidget);
    });

    testWidgets('5. SettingsScreen renders user account, AI controls, and security info', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildWrapper(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('AI & Grounding Controls'), findsOneWidget);
      expect(find.text('Strict Grounding Mode'), findsOneWidget);
      expect(find.text('Local Offline Persistence'), findsOneWidget);
      expect(find.text('Tenant Isolation & App Check'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.textContaining('Recallr v1.0.0'), findsOneWidget);

      // Verify toggles work interactively
      await tester.tap(find.text('Strict Grounding Mode'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Local Offline Persistence'));
      await tester.pumpAndSettle();
    });
  });
}
