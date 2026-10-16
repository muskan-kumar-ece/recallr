import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/routing/deep_link_manager.dart';
import '../core/logging/safe_logger.dart';

class AuthService {
  static AuthService? _instance;
  static final SafeLogger _logger = SafeLogger('AuthService');
  static bool _googleSignInInitialized = false;

  // Web Client ID from Firebase Console / google-services.json (client_type: 3)
  static const String _webClientId =
      '326057321055-ja0uaq0fdieg2c5op006l1g30a7m33qp.apps.googleusercontent.com';

  final FirebaseAuth? _injectedAuth;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  /// Factory constructor providing singleton access by default while supporting
  /// dependency injection for automated testing.
  factory AuthService({FirebaseAuth? auth}) {
    if (auth != null) {
      return AuthService._internal(auth: auth);
    }
    return _instance ??= AuthService._internal();
  }

  AuthService._internal({FirebaseAuth? auth}) : _injectedAuth = auth;

  static Future<void> _initializeGoogleSignIn() async {
    if (_googleSignInInitialized) return;
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.initialize(
          serverClientId: _webClientId,
        );
      }
      _googleSignInInitialized = true;
    } catch (_) {
      // Ignored in test environment or if platform channels not registered
    }
  }

  @visibleForTesting
  static void setMockInstance(AuthService? mock) {
    _instance = mock;
  }

  @visibleForTesting
  static void reset() {
    _instance = null;
    _googleSignInInitialized = false;
  }

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  // Get current user
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // Sign in with Email and Password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Register with Email and Password
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (displayName != null && displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();
    }

    return credential;
  }

  // Google Sign-In with cross-platform support (GoogleSignIn 7.2.0+ & Web popup)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web uses popup to avoid DWDS hangs and manual client ID config
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        // Mobile uses standard flow with google_sign_in 7.2.0 API
        await _initializeGoogleSignIn();
        final GoogleSignInAccount? googleUser =
            await GoogleSignIn.instance.authenticate();
        if (googleUser == null) return null; // User cancelled

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw StateError(
              'Google Sign-In failed to return valid authentication token.');
        }

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e, st) {
      _logger.warning('Error during Google Sign-In', e, st);
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Sign out (with try-finally guarantee for FirebaseAuth)
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (e, st) {
          _logger.warning('Non-fatal error signing out of GoogleSignIn', e, st);
        }
      }
    } finally {
      try {
        DeepLinkManager().clearPendingPath();
        await _auth.signOut();
      } catch (e, st) {
        _logger.warning('Error signing out of FirebaseAuth', e, st);
        rethrow;
      }
    }
  }
}