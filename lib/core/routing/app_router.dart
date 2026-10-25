import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'deep_link_manager.dart';
import 'recallr_routes.dart';
import '../../app/app_shell.dart';
import '../../screens/auth_screen.dart';
import '../../screens/entities/company_dossier_screen.dart';
import '../../screens/entities/event_dossier_screen.dart';
import '../../screens/entities/file_dossier_screen.dart';
import '../../screens/entities/interaction_dossier_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/subscription_screen.dart';
import '../../screens/common/not_found_screen.dart';
import '../../screens/follow_ups/follow_ups_screen.dart';
import '../../screens/network/network_dashboard_screen.dart';
import '../../screens/person/person_detail_screen.dart';
import '../../screens/capture/capture_detail_screen.dart';

/// Central Route Generator and Deep-Link Parser for Recallr.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? RecallrRoutes.initial);
    final path = uri.path;

    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    final bool isAuthenticated = user != null;

    // Public / Auth Route
    if (path == RecallrRoutes.auth) {
      return _buildRoute(const AuthScreen(), settings);
    }

    // Guard Protected Deep Links & Core Routes when Unauthenticated
    if (!isAuthenticated) {
      if (path != RecallrRoutes.initial) {
        DeepLinkManager().setPendingPath(settings.name);
      }
      return _buildRoute(const AuthScreen(), settings);
    }

    // Primary Root & App Shell Tabs (Home, People, Ask, Activity)
    if (path == RecallrRoutes.initial || path == RecallrRoutes.home) {
      return _buildRoute(RecallrAppShell(user: user, initialIndex: 0), settings);
    }
    if (path == RecallrRoutes.people) {
      return _buildRoute(RecallrAppShell(user: user, initialIndex: 1), settings);
    }
    if (path == RecallrRoutes.ask) {
      return _buildRoute(
        RecallrAppShell(
          user: user,
          initialIndex: 2,
          initialAskQuery: settings.arguments as String?,
        ),
        settings,
      );
    }
    if (path == RecallrRoutes.activity) {
      return _buildRoute(RecallrAppShell(user: user, initialIndex: 3), settings);
    }

    // Global Shell Action Entry Route (/capture)
    // Resolves into the authenticated shell and immediately opens the quick capture modal
    if (path == RecallrRoutes.capture) {
      return _buildRoute(
        RecallrAppShell(user: user, initialIndex: 0, autoOpenCapture: true),
        settings,
      );
    }

    // Settings Route
    if (path == RecallrRoutes.settings) {
      return _buildRoute(
        const SettingsScreen(),
        settings,
      );
    }

    // Subscription & Storage Route
    if (path == RecallrRoutes.subscription) {
      return _buildRoute(
        const SubscriptionScreen(),
        settings,
      );
    }

    // Follow-ups Hub Route
    if (path == RecallrRoutes.followUp || path == '/follow-ups') {
      return _buildRoute(
        const FollowUpsScreen(),
        settings,
      );
    }

    // Network Intelligence Dashboard Route
    if (path == RecallrRoutes.network || path == '/network') {
      return _buildRoute(
        const NetworkDashboardScreen(),
        settings,
      );
    }

    // Parametric Deep-Link Routes (P1/P2 Context Dossiers)
    final pathSegments = uri.pathSegments;
    if (pathSegments.length == 2) {
      final entityType = pathSegments[0];
      final entityId = pathSegments[1];

      switch (entityType) {
        case 'person':
          return _buildRoute(
            PersonDetailScreen(personId: entityId),
            settings,
          );
        case 'company':
          return _buildRoute(
            CompanyDossierScreen(companyId: entityId),
            settings,
          );
        case 'event':
          return _buildRoute(
            EventDossierScreen(eventId: entityId),
            settings,
          );
        case 'file':
          return _buildRoute(
            FileDossierScreen(fileId: entityId),
            settings,
          );
        case 'interaction':
          return _buildRoute(
            InteractionDossierScreen(interactionId: entityId),
            settings,
          );
        case 'follow-up':
          return _buildRoute(
            FollowUpsScreen(initialFollowUpId: entityId),
            settings,
          );
        case 'captures':
          return _buildRoute(
            CaptureDetailScreen(captureId: entityId),
            settings,
          );
      }
    }

    // Fallback Not Found (404) Route
    return _buildRoute(NotFoundScreen(path: path), settings);
  }

  static MaterialPageRoute _buildRoute(Widget child, RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => child,
    );
  }
}