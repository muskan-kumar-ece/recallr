import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recaller/core/routing/deep_link_manager.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/main.dart';
import 'package:recaller/screens/auth_screen.dart';
import 'package:recaller/services/auth_service.dart';
import 'package:recaller/services/firestore_service.dart';

// Test Mock for User
class _FakeUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? photoURL;

  _FakeUser({
    required this.uid,
    this.email = 'test@recallr.ai',
    this.displayName = 'Test User',
  }) : photoURL = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test Mock for AuthService
class _TestAuthService implements AuthService {
  final StreamController<User?> _controller = StreamController<User?>.broadcast();
  User? _currentUser;
  bool signOutCalled = false;

  void emitUser(User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => _currentUser;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    DeepLinkManager().clearPendingPath();
    emitUser(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test Mock for FirestoreService
class _TestFirestoreService implements FirestoreService {
  final List<String> syncedUids = [];

  @override
  Future<void> syncUserProfile(User user) async {
    syncedUids.add(user.uid);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildTestApp({
  required AuthService authService,
  required FirestoreService firestoreService,
}) {
  return MaterialApp(
    theme: RecallrTheme.darkTheme,
    home: AuthGate(
      authService: authService,
      firestoreService: firestoreService,
    ),
  );
}

void main() {
  group('Phase 13H-08.1: Auth Hardening Tests', () {
    late _TestAuthService mockAuth;
    late _TestFirestoreService mockFirestore;

    setUp(() {
      mockAuth = _TestAuthService();
      mockFirestore = _TestFirestoreService();
      DeepLinkManager().clearPendingPath();
      AuthService.setMockInstance(mockAuth);
    });

    tearDown(() {
      mockAuth._controller.close();
      DeepLinkManager().clearPendingPath();
      AuthService.reset();
    });

    test('DeepLinkManager.clearPendingPath removes pending deep links on logout', () async {
      final dlm = DeepLinkManager();
      dlm.setPendingPath('/person/target_123');
      expect(dlm.pendingPath, '/person/target_123');

      dlm.clearPendingPath();
      expect(dlm.pendingPath, isNull);
    });

    test('AuthService.setMockInstance enables unit test dependency injection', () {
      final customMock = _TestAuthService();
      AuthService.setMockInstance(customMock);
      final instance = AuthService();
      expect(identical(instance, customMock), isTrue);

      AuthService.reset();
      final fresh = AuthService();
      expect(identical(fresh, customMock), isFalse);
    });

    testWidgets('AuthGate displays CircularProgressIndicator when connection is waiting', (tester) async {
      // Controller hasn't emitted yet -> ConnectionState.waiting
      await tester.pumpWidget(_buildTestApp(
        authService: mockAuth,
        firestoreService: mockFirestore,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AuthGate routes to AuthScreen when unauthenticated (user == null)', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        authService: mockAuth,
        firestoreService: mockFirestore,
      ));

      // Emit null (unauthenticated)
      mockAuth.emitUser(null);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('AuthGate routes to _AuthenticatedRestorer and performs single-flight profile sync', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        authService: mockAuth,
        firestoreService: mockFirestore,
      ));

      final userA = _FakeUser(uid: 'uid_alice_123', email: 'alice@recallr.ai');
      mockAuth.emitUser(userA);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Profile sync should have fired once for userA
      expect(mockFirestore.syncedUids, ['uid_alice_123']);

      // Re-trigger a pump/rebuild without changing user
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Single-flight guarantee: syncUserProfile must NOT be called again
      expect(mockFirestore.syncedUids.length, 1);
    });

    testWidgets('AuthGate purges state and keys subtrees across account switching (User A -> Logout -> User B)', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        authService: mockAuth,
        firestoreService: mockFirestore,
      ));

      // 1. User A logs in
      final userA = _FakeUser(uid: 'user_a', displayName: 'Alice');
      mockAuth.emitUser(userA);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('user_restorer_user_a')), findsOneWidget);
      expect(mockFirestore.syncedUids, ['user_a']);

      // 2. User A logs out
      mockAuth.emitUser(null);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('user_restorer_user_a')), findsNothing);

      // 3. User B logs in
      final userB = _FakeUser(uid: 'user_b', displayName: 'Bob');
      mockAuth.emitUser(userB);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('user_restorer_user_b')), findsOneWidget);
      expect(find.byKey(const ValueKey('user_restorer_user_a')), findsNothing);
      expect(mockFirestore.syncedUids, ['user_a', 'user_b']);
    });

    testWidgets('AuthGate gracefully renders error screen when auth stream emits error', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        authService: mockAuth,
        firestoreService: mockFirestore,
      ));

      mockAuth.emitError('Firebase network unreachable');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Authentication Error'), findsOneWidget);
      expect(find.textContaining('Firebase network unreachable'), findsOneWidget);
    });
  });
}
