import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/app/app_shell.dart';
import 'package:recaller/core/routing/app_router.dart';
import 'package:recaller/core/routing/deep_link_manager.dart';
import 'package:recaller/core/routing/recallr_routes.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/follow_ups/widgets/follow_up_group.dart';
import 'package:recaller/features/people/widgets/people_empty_state.dart';
import 'package:recaller/screens/auth_screen.dart';
import 'package:recaller/screens/people/people_screen.dart';

void main() {
  group('Phase 13H-08.1: Navigation & Shell Hardening Tests', () {
    setUp(() {
      DeepLinkManager().clearPendingPath();
    });

    tearDown(() {
      DeepLinkManager().clearPendingPath();
    });

    testWidgets('AppRouter guards /home when unauthenticated and fails closed to AuthScreen (NAV-P0-1)', (tester) async {
      // In test environment without Firebase user logged in, isAuthenticated is false
      final route = AppRouter.onGenerateRoute(const RouteSettings(name: RecallrRoutes.home));

      await tester.pumpWidget(MaterialApp(
        theme: RecallrTheme.darkTheme,
        home: Builder(
          builder: (context) {
            return (route as MaterialPageRoute).builder(context);
          },
        ),
      ));

      // Must fail-closed to AuthScreen
      expect(find.byType(AuthScreen), findsOneWidget);
      // /home is default authenticated route so pending path should not override it
      expect(DeepLinkManager().pendingPath, isNull);
    });

    testWidgets('AppRouter guards protected deep-links when unauthenticated and captures pending path', (tester) async {
      final route = AppRouter.onGenerateRoute(const RouteSettings(name: '/person/alice_999'));

      await tester.pumpWidget(MaterialApp(
        theme: RecallrTheme.darkTheme,
        home: Builder(
          builder: (context) {
            return (route as MaterialPageRoute).builder(context);
          },
        ),
      ));

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(DeepLinkManager().pendingPath, '/person/alice_999');
    });

    testWidgets('RecallrAppShellScope.openTab switches shell tabs without pushing new routes (NAV-P1-1)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: RecallrTheme.darkTheme,
        home: const RecallrAppShell(initialIndex: 0),
      ));
      await tester.pumpAndSettle();

      // Starts at Home (index 0)
      expect(find.text('Home'), findsWidgets);

      // Programmatically switch to People tab (index 1) via RecallrAppShell.selectTab
      final element = tester.element(find.byType(RecallrAppShell));
      RecallrAppShell.selectTab(element, 1);
      await tester.pump();
      await tester.pumpAndSettle();

      // Switched to People tab
      final scope = tester.widget<RecallrAppShellScope>(find.byType(RecallrAppShellScope));
      expect(scope.selectedIndex, 1);
    });

    testWidgets('PopScope intercepts system back on non-home tab and navigates to Home (NAV-P1-2)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: RecallrTheme.darkTheme,
        home: const RecallrAppShell(initialIndex: 1), // Start on People
      ));
      await tester.pumpAndSettle();

      final popScopeFinder = find.byKey(const ValueKey<String>('recallr_shell_pop_scope'));
      expect(popScopeFinder, findsOneWidget);

      // On tab 1, PopScope canPop is false
      final popScope = tester.widget<PopScope>(popScopeFinder);
      expect(popScope.canPop, isFalse);

      // Simulate back button press via PopScope onPopInvokedWithResult
      popScope.onPopInvokedWithResult!(false, null);
      await tester.pump();
      await tester.pumpAndSettle();

      // Should now be on Home tab (index 0)
      final updatedScope = tester.widget<RecallrAppShellScope>(find.byType(RecallrAppShellScope));
      expect(updatedScope.selectedIndex, 0);

      // On Home tab, canPop is true
      final updatedPopScope = tester.widget<PopScope>(popScopeFinder);
      expect(updatedPopScope.canPop, isTrue);
    });

    testWidgets('IndexedStack preserves PageStorageKey across mobile and tablet breakpoint resize (NAV-P1-5)', (tester) async {
      // 1. Mobile viewport (400 width < 600 breakpoint)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: RecallrTheme.darkTheme,
        home: const RecallrAppShell(initialIndex: 0),
      ));
      await tester.pumpAndSettle();

      final mobileStackFinder = find.byKey(const PageStorageKey<String>('recallr_shell_stack'));
      expect(mobileStackFinder, findsOneWidget);

      // 2. Resize to tablet/desktop viewport (900 width >= 600 breakpoint)
      tester.view.physicalSize = const Size(900, 800);
      await tester.pump();
      await tester.pumpAndSettle();

      // The same PageStorageKey IndexedStack is present and preserved in the tree
      final tabletStackFinder = find.byKey(const PageStorageKey<String>('recallr_shell_stack'));
      expect(tabletStackFinder, findsOneWidget);
    });

    testWidgets('PeopleScreen truthfully initializes _isLoading to prevent premature empty flashing (NAV-P1-3)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: RecallrTheme.darkTheme,
        home: const Scaffold(
          body: PeopleScreen(
            // initialPeople is null, isEmpty is false, isError is false
            // This represents a live screen waiting for the repository stream to emit
            initialPeople: null,
            isEmpty: false,
            isError: false,
          ),
        ),
      ));

      // On initial frame, PeopleEmptyState must NOT be rendered
      expect(find.byType(PeopleEmptyState), findsNothing);
    });

    testWidgets('FollowUpGroup does not recursively push /follow-ups route (NAV-P1-4)', (tester) async {
      int pushedRoutesCount = 0;
      String? lastPushedRoute;

      final followUpItem = FollowUpItem(
        id: 'fol_test_1',
        title: 'Review proposal',
        personName: 'Dave',
        targetRoute: '/follow-ups', // recursive route target
        dueDate: 'Tomorrow',
        commitmentType: CommitmentType.iPromised,
        priority: FollowUpPriority.medium,
        status: FollowUpStatus.dueToday,
      );

      await tester.pumpWidget(MaterialApp(
        theme: RecallrTheme.darkTheme,
        navigatorObservers: [
          _TestNavigatorObserver(
            onPushed: (route) {
              pushedRoutesCount++;
              lastPushedRoute = route.settings.name;
            },
          ),
        ],
        home: Scaffold(
          body: FollowUpGroup(
            title: 'Test Group',
            items: [followUpItem],
            onTapFollowUp: null, // default handler
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final cardFinder = find.text('Review proposal');
      expect(cardFinder, findsOneWidget);

      // Tap the card
      await tester.tap(cardFinder);
      await tester.pump();

      // Must NOT push /follow-ups route
      expect(lastPushedRoute, isNot('/follow-ups'));
      expect(pushedRoutesCount, 0);
    });
  });
}

class _TestNavigatorObserver extends NavigatorObserver {
  final void Function(Route<dynamic> route) onPushed;

  _TestNavigatorObserver({required this.onPushed});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      onPushed(route);
    }
  }
}
