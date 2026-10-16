import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app/app_shell.dart';
import 'core/routing/app_router.dart';
import 'core/routing/deep_link_manager.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'core/di/recallr_dependencies.dart';
import 'core/theme/theme.dart';
import 'core/logging/safe_logger.dart';

import 'core/bootstrap/firebase_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final result = await FirebaseBootstrap.initialize();

  if (!result.isSuccess) {
    runApp(RecallrBootstrapErrorApp(
      errorMessage: result.errorMessage ?? 'Unknown secure startup error occurred.',
    ));
    return;
  }

  runApp(RecallerApp(dependencies: result.dependencies));
}

class RecallerApp extends StatelessWidget {
  final RecallrDependencies? dependencies;

  const RecallerApp({
    super.key,
    this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    final deps = dependencies ?? RecallrDependencies.production();

    return RecallrScope(
      dependencies: deps,
      child: MaterialApp(
        title: 'Recallr',
        debugShowCheckedModeBanner: false,
        theme: RecallrTheme.darkTheme,
        darkTheme: RecallrTheme.darkTheme,
        themeMode: ThemeMode.dark,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final AuthService? authService;
  final FirestoreService? firestoreService;

  const AuthGate({
    super.key,
    this.authService,
    this.firestoreService,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static final SafeLogger _logger = SafeLogger('AuthGate');

  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final Stream<User?> _authStateStream;

  String? _lastSyncedUserId;
  bool _isSyncingProfile = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    _authStateStream = _authService.authStateChanges;
  }

  void _triggerProfileSync(User user) {
    if (_lastSyncedUserId == user.uid || _isSyncingProfile) {
      return;
    }

    _isSyncingProfile = true;
    _lastSyncedUserId = user.uid;

    _firestoreService.syncUserProfile(user).catchError((error, stackTrace) {
      _logger.warning('Failed to sync user profile', error, stackTrace);
      if (mounted && _lastSyncedUserId == user.uid) {
        // Reset on failure so subsequent attempts or reloads can retry
        _lastSyncedUserId = null;
      }
    }).whenComplete(() {
      _isSyncingProfile = false;
    });
  }

  void _handleSignOut() {
    if (_lastSyncedUserId != null) {
      _lastSyncedUserId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        // 1. Error state handling
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: RecallrColors.obsidianBase,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(RecallrSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: RecallrColors.crimsonAlert,
                    ),
                    RecallrSpacing.gapMd,
                    Text(
                      'Authentication Error',
                      style: RecallrTypography.headlineMedium.copyWith(color: RecallrColors.textPrimary),
                    ),
                    RecallrSpacing.gapSm,
                    Text(
                      snapshot.error.toString(),
                      style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 2. Waiting connection state (initial auth evaluation)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: RecallrColors.obsidianBase,
            body: Center(
              child: CircularProgressIndicator(
                color: RecallrColors.aiElectricViolet,
              ),
            ),
          );
        }

        // 3. Authenticated state
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          // Asynchronously trigger profile sync without side-effects inside build()
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _triggerProfileSync(user);
            }
          });

          // Keyed by user.uid so account switching completely unmounts and discards User A's subtree
          return _AuthenticatedRestorer(
            key: ValueKey('user_restorer_${user.uid}'),
            user: user,
          );
        }

        // 4. Unauthenticated state
        _handleSignOut();
        return const AuthScreen();
      },
    );
  }
}

class _AuthenticatedRestorer extends StatefulWidget {
  final User user;
  const _AuthenticatedRestorer({super.key, required this.user});

  @override
  State<_AuthenticatedRestorer> createState() => _AuthenticatedRestorerState();
}

class _AuthenticatedRestorerState extends State<_AuthenticatedRestorer> {
  @override
  void initState() {
    super.initState();
    final pending = DeepLinkManager().consumePendingPath();
    if (pending != null && pending.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamed(pending);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecallrAppShell(
      key: ValueKey('app_shell_${widget.user.uid}'),
      user: widget.user,
    );
  }
}