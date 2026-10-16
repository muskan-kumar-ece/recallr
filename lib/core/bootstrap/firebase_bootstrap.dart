import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../firebase_options.dart';
import '../di/recallr_dependencies.dart';
import '../logging/safe_logger.dart';
import '../security/app_check_service.dart';
import '../security/environment_config.dart';
import '../security/firebase_emulator_helper.dart';
import '../security/production_configuration_validator.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

import 'dart:ui';
import '../observability/observability.dart';

/// Encapsulates the runtime result of the Firebase and security bootstrap phase.
class BootstrapResult {
  final bool isSuccess;
  final EnvironmentConfig config;
  final RecallrDependencies? dependencies;
  final AppCheckService appCheckService;
  final String? errorMessage;

  const BootstrapResult({
    required this.isSuccess,
    required this.config,
    required this.appCheckService,
    this.dependencies,
    this.errorMessage,
  });
}

/// Orchestrates the hardened, environment-aware startup lifecycle for Recallr.
class FirebaseBootstrap {
  static final SafeLogger _logger = SafeLogger('FirebaseBootstrap');

  /// Executes the full initialization pipeline in the required security order.
  static Future<BootstrapResult> initialize({
    EnvironmentConfig? configOverride,
    FirebaseOptions? optionsOverride,
    AppCheckService? appCheckOverride,
    RecallrDependencies? dependenciesOverride,
    CrashReportingService? crashReportingOverride,
    TelemetryService? telemetryOverride,
  }) async {
    final config = configOverride ?? EnvironmentConfig.current();
    final appCheckService = appCheckOverride ?? FirebaseAppCheckService(config: config);
    final crashReporting = crashReportingOverride ?? ProductionCrashReportingService(config: config);
    final telemetry = telemetryOverride ?? ProductionTelemetryService(config: config);

    _logger.info('Starting Recallr Bootstrap for environment: ${config.environment.name}');

    // Step 0: Wire Global Error Listeners
    try {
      await crashReporting.initialize();
      await telemetry.initialize();

      FlutterError.onError = (details) {
        crashReporting.recordFatalError(
          details.exception,
          details.stack ?? StackTrace.empty,
          reason: details.context?.toString(),
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        crashReporting.recordFatalError(error, stack, reason: 'Uncaught Platform Error');
        return true;
      };

      telemetry.recordEvent(
        TelemetryEvent(
          name: 'app_started',
          environment: config.environment,
          feature: TelemetryFeature.bootstrap,
          operation: 'initialize',
          severity: TelemetrySeverity.info,
        ),
      );
    } catch (e, st) {
      _logger.warning('Failed to initialize crash reporting or telemetry during bootstrap', e, st);
    }

    // Step 1: Validate Environment Configuration
    try {
      ProductionConfigurationValidator.validateOrThrow(config);
      _logger.info('Configuration validation passed.');
    } catch (e, st) {
      _logger.error('Configuration validation failed', e, st);
      telemetry.recordEvent(
        TelemetryEvent(
          name: 'bootstrap_validation_failed',
          environment: config.environment,
          feature: TelemetryFeature.bootstrap,
          operation: 'validateConfiguration',
          severity: TelemetrySeverity.fatal,
          isSuccess: false,
          safeErrorCategory: 'configuration_invalid',
        ),
      );
      return BootstrapResult(
        isSuccess: false,
        config: config,
        appCheckService: appCheckService,
        errorMessage: 'Configuration Validation Error: $e',
      );
    }

    // Step 2: Initialize Firebase
    try {
      final options = optionsOverride ?? DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: options);
      _logger.info('Firebase.initializeApp completed successfully.');

      telemetry.recordEvent(
        TelemetryEvent(
          name: 'firebase_initialized',
          environment: config.environment,
          feature: TelemetryFeature.bootstrap,
          operation: 'initializeApp',
          severity: TelemetrySeverity.info,
        ),
      );
    } catch (e, st) {
      _logger.error('Firebase initialization failed', e, st);
      telemetry.recordEvent(
        TelemetryEvent(
          name: 'firebase_initialization_failed',
          environment: config.environment,
          feature: TelemetryFeature.bootstrap,
          operation: 'initializeApp',
          severity: TelemetrySeverity.error,
          isSuccess: false,
          safeErrorCategory: 'core_init_failure',
        ),
      );
      // In development or test mode without Firebase, allow soft continuation if mocks provided
      if (config.isProduction) {
        return BootstrapResult(
          isSuccess: false,
          config: config,
          appCheckService: appCheckService,
          errorMessage: 'Firebase Core Initialization Error: $e',
        );
      }
    }

    // Step 3: Activate App Check
    try {
      await appCheckService.activate();
      _logger.info('App Check step completed. Activated: ${appCheckService.isActivated}');

      telemetry.recordEvent(
        TelemetryEvent(
          name: 'app_check_activated',
          environment: config.environment,
          feature: TelemetryFeature.bootstrap,
          operation: 'activateAppCheck',
          severity: appCheckService.isActivated ? TelemetrySeverity.info : TelemetrySeverity.warning,
          isSuccess: appCheckService.isActivated,
          provider: appCheckService.activeProviderType.name,
        ),
      );
    } catch (e, st) {
      _logger.warning('App Check activation threw during bootstrap', e, st);
    }

    // Step 4: Connect Emulators if configured
    if (config.useEmulators && !config.isProduction) {
      try {
        await FirebaseEmulatorHelper.connectIfEnabled(config);
        _logger.info('Firebase Emulators connected.');
      } catch (e, st) {
        _logger.warning('Emulator connection failed', e, st);
      }
    }

    // Step 5: Construct Production Dependencies Container
    final deps = dependenciesOverride ??
        RecallrDependencies.production(
          crashReportingService: crashReporting,
          telemetryService: telemetry,
        );

    RecallrDependencies.setInstance(deps);

    _logger.info('Recallr Bootstrap completed successfully.');
    return BootstrapResult(
      isSuccess: true,
      config: config,
      appCheckService: appCheckService,
      dependencies: deps,
    );
  }
}

/// Fallback error screen rendered when Firebase bootstrap encounters an unrecoverable failure.
class RecallrBootstrapErrorApp extends StatelessWidget {
  final String errorMessage;

  const RecallrBootstrapErrorApp({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recallr — Startup Error',
      debugShowCheckedModeBanner: false,
      theme: RecallrTheme.darkTheme,
      home: Scaffold(
        backgroundColor: RecallrColors.obsidianBase,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(RecallrSpacing.xl),
            child: RecallrCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.security_update_warning_rounded,
                    size: 48,
                    color: RecallrColors.crimsonAlert,
                  ),
                  const SizedBox(height: RecallrSpacing.md),
                  Text(
                    'Initialization Failure',
                    style: RecallrTypography.headlineMedium.copyWith(
                      color: RecallrColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: RecallrSpacing.sm),
                  Text(
                    'Recallr encountered a secure startup error and halted execution to protect user data.',
                    textAlign: TextAlign.center,
                    style: RecallrTypography.bodyMedium.copyWith(
                      color: RecallrColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: RecallrSpacing.lg),
                  RecallrSurface(
                    surfaceColor: RecallrColors.charcoalCard,
                    child: Padding(
                      padding: const EdgeInsets.all(RecallrSpacing.md),
                      child: Text(
                        EnvironmentConfig.sanitizeForLog(errorMessage),
                        style: RecallrTypography.monoMetadata.copyWith(
                          color: RecallrColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}