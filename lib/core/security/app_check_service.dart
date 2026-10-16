import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../logging/safe_logger.dart';
import 'environment_config.dart';

/// Abstract contract for Firebase App Check lifecycle and provider orchestration.
abstract class AppCheckService {
  /// Activates App Check with environment-specific providers.
  Future<void> activate();

  /// Whether App Check was successfully activated.
  bool get isActivated;

  /// The active App Check provider type configured for this instance.
  AppCheckProviderType get activeProviderType;

  /// Retrieves the current App Check token (for manual HTTP headers or Cloud Functions).
  Future<String?> getToken({bool forceRefresh = false});

  /// Stream of token updates.
  Stream<String?> get onTokenChange;

  /// Diagnostic telemetry for security auditing (tokens are never included).
  Map<String, dynamic> get diagnostics;
}

/// Production implementation of AppCheckService wrapping the FirebaseAppCheck SDK.
class FirebaseAppCheckService implements AppCheckService {
  final FirebaseAppCheck? _appCheckOverride;
  final EnvironmentConfig config;
  final SafeLogger _logger;

  bool _isActivated = false;
  bool _hasAttemptedActivation = false;
  String? _activationError;
  late AppCheckProviderType _activeProviderType;

  FirebaseAppCheckService({
    FirebaseAppCheck? appCheck,
    EnvironmentConfig? config,
    SafeLogger? logger,
  })  : _appCheckOverride = appCheck,
        config = config ?? EnvironmentConfig.current(),
        _logger = logger ?? SafeLogger('AppCheckService') {
    _activeProviderType = config?.appCheckProviderType ?? AppCheckProviderType.debug;
  }

  FirebaseAppCheck get _appCheck {
    if (_appCheckOverride != null) return _appCheckOverride;
    return FirebaseAppCheck.instance;
  }

  @override
  bool get isActivated => _isActivated;

  @override
  AppCheckProviderType get activeProviderType => _activeProviderType;

  @override
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      return await _appCheck.getToken(forceRefresh);
    } catch (e, st) {
      _logger.warning('Failed to retrieve App Check token', e, st);
      return null;
    }
  }

  @override
  Stream<String?> get onTokenChange => _appCheck.onTokenChange;

  @override
  Map<String, dynamic> get diagnostics => {
        'isActivated': _isActivated,
        'hasAttemptedActivation': _hasAttemptedActivation,
        'environment': config.environment.name,
        'providerType': _activeProviderType.name,
        'error': _activationError != null ? EnvironmentConfig.sanitizeForLog(_activationError!) : null,
      };

  @override
  Future<void> activate() async {
    if (_hasAttemptedActivation) {
      _logger.debug('App Check activation skipped: already initialized.');
      return;
    }

    _hasAttemptedActivation = true;

    if (!config.enableAppCheck) {
      _logger.info('App Check is disabled for environment: ${config.environment.name}');
      return;
    }

    try {
      _logger.info('Activating Firebase App Check for environment: ${config.environment.name}');

      final AndroidProvider androidProvider;
      final AppleProvider appleProvider;
      final ReCaptchaV3Provider? webProvider;

      if (config.isProduction) {
        androidProvider = AndroidProvider.playIntegrity;
        appleProvider = AppleProvider.appAttestWithDeviceCheckFallback;
        webProvider = config.appCheckRecaptchaSiteKey != null
            ? ReCaptchaV3Provider(config.appCheckRecaptchaSiteKey!)
            : null;
        _activeProviderType = kIsWeb
            ? AppCheckProviderType.reCaptchaV3
            : (defaultTargetPlatform == TargetPlatform.iOS
                ? AppCheckProviderType.appAttest
                : AppCheckProviderType.playIntegrity);
      } else {
        // Development / Staging: Use debug provider
        androidProvider = AndroidProvider.debug;
        appleProvider = AppleProvider.debug;
        webProvider = null;
        _activeProviderType = AppCheckProviderType.debug;
      }

      await _appCheck.activate(
        androidProvider: androidProvider,
        appleProvider: appleProvider,
        webProvider: webProvider,
      );

      _isActivated = true;
      _activationError = null;
      _logger.info('Firebase App Check activated successfully with provider: ${_activeProviderType.name}');
    } catch (e, st) {
      _isActivated = false;
      _activationError = e.toString();
      _logger.warning('Firebase App Check activation failed (safe fallback active)', e, st);

      // In production, we record failure in diagnostics but do not crash the app UI.
      if (config.isProduction) {
        _logger.error('CRITICAL: App Check failed to activate in production environment.');
      }
    }
  }
}

/// Mock implementation for unit and widget testing.
class MockAppCheckService implements AppCheckService {
  final bool shouldSucceed;
  final AppCheckProviderType providerType;
  bool _isActivated = false;
  int activationCallCount = 0;

  MockAppCheckService({
    this.shouldSucceed = true,
    this.providerType = AppCheckProviderType.debug,
  });

  @override
  Future<void> activate() async {
    activationCallCount++;
    if (activationCallCount > 1) return; // Idempotent
    _isActivated = shouldSucceed;
  }

  @override
  bool get isActivated => _isActivated;

  @override
  AppCheckProviderType get activeProviderType => providerType;

  @override
  Future<String?> getToken({bool forceRefresh = false}) async => null;

  @override
  Stream<String?> get onTokenChange => const Stream.empty();

  @override
  Map<String, dynamic> get diagnostics => {
        'isActivated': _isActivated,
        'hasAttemptedActivation': activationCallCount > 0,
        'callCount': activationCallCount,
        'providerType': providerType.name,
      };
}