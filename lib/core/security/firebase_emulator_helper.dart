import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../logging/safe_logger.dart';
import 'environment_config.dart';
import 'production_configuration_validator.dart';

/// Helper to configure and safely isolate Firebase Emulators during local development and testing.
class FirebaseEmulatorHelper {
  static final SafeLogger _logger = SafeLogger('FirebaseEmulatorHelper');

  /// Connects Firebase SDKs to local emulator suite if configured in [config].
  ///
  /// Guarantees that production builds NEVER connect to emulators.
  static Future<void> connectIfEnabled(
    EnvironmentConfig config, {
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) async {
    if (!config.useEmulators) {
      return;
    }

    if (config.isProduction) {
      const errorMsg = 'SECURITY VIOLATION: Attempted to connect to Firebase Emulators in PRODUCTION environment.';
      _logger.error(errorMsg);
      throw const RecallrConfigurationException(errorMsg);
    }

    final host = config.emulatorHost;
    _logger.info('Connecting to Firebase Emulator Suite at host: $host');

    try {
      final authTarget = auth ?? FirebaseAuth.instance;
      await authTarget.useAuthEmulator(host, config.authEmulatorPort);
      _logger.info('FirebaseAuth emulator connected on port ${config.authEmulatorPort}');
    } catch (e, st) {
      _logger.warning('Failed to connect FirebaseAuth emulator', e, st);
    }

    try {
      final firestoreTarget = firestore ?? FirebaseFirestore.instance;
      firestoreTarget.useFirestoreEmulator(host, config.firestoreEmulatorPort);
      _logger.info('FirebaseFirestore emulator connected on port ${config.firestoreEmulatorPort}');
    } catch (e, st) {
      _logger.warning('Failed to connect FirebaseFirestore emulator', e, st);
    }

    try {
      final storageTarget = storage ?? FirebaseStorage.instance;
      await storageTarget.useStorageEmulator(host, config.storageEmulatorPort);
      _logger.info('FirebaseStorage emulator connected on port ${config.storageEmulatorPort}');
    } catch (e, st) {
      _logger.warning('Failed to connect FirebaseStorage emulator', e, st);
    }
  }
}