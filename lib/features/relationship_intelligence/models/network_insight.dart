import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Categorical type of explainable network observation.
enum NetworkInsightType {
  attention,
  relationshipHealth,
  followUpRisk,
  interactionMomentum,
  relationshipGrowth,
  relationshipDecline,
  networkCoverage;

  String get displayName {
    switch (this) {
      case NetworkInsightType.attention:
        return 'Attention Needed';
      case NetworkInsightType.relationshipHealth:
        return 'Network Health';
      case NetworkInsightType.followUpRisk:
        return 'Follow-up Risk';
      case NetworkInsightType.interactionMomentum:
        return 'Interaction Momentum';
      case NetworkInsightType.relationshipGrowth:
        return 'Network Growth';
      case NetworkInsightType.relationshipDecline:
        return 'Relationship Cooling';
      case NetworkInsightType.networkCoverage:
        return 'Context Coverage';
    }
  }

  IconData get icon {
    switch (this) {
      case NetworkInsightType.attention:
        return Icons.notifications_active_outlined;
      case NetworkInsightType.relationshipHealth:
        return Icons.favorite_outline_rounded;
      case NetworkInsightType.followUpRisk:
        return Icons.warning_amber_rounded;
      case NetworkInsightType.interactionMomentum:
        return Icons.bolt_rounded;
      case NetworkInsightType.relationshipGrowth:
        return Icons.person_add_outlined;
      case NetworkInsightType.relationshipDecline:
        return Icons.ac_unit_rounded;
      case NetworkInsightType.networkCoverage:
        return Icons.hub_outlined;
    }
  }
}

/// Severity classification for network insights.
enum NetworkInsightSeverity {
  critical(4),
  high(3),
  medium(2),
  info(1);

  final int rank;
  const NetworkInsightSeverity(this.rank);

  Color get colorToken {
    switch (this) {
      case NetworkInsightSeverity.critical:
        return RecallrColors.crimsonAlert;
      case NetworkInsightSeverity.high:
        return RecallrColors.warmAmberGold;
      case NetworkInsightSeverity.medium:
        return RecallrColors.aiCyanHighlight;
      case NetworkInsightSeverity.info:
        return RecallrColors.textSecondary;
    }
  }

  String get badgeLabel => name.toUpperCase();
}

/// Represents one grounded, deterministic observation about the user's network.
@immutable
class NetworkInsight {
  final String id;
  final NetworkInsightType type;
  final String title;
  final String description;
  final NetworkInsightSeverity severity;
  final String metric;
  final double value;
  final List<String> supportingPersonIds;

  const NetworkInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.metric,
    required this.value,
    this.supportingPersonIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'severity': severity.name,
      'metric': metric,
      'value': value,
      'supportingPersonIds': supportingPersonIds,
    };
  }

  factory NetworkInsight.fromMap(Map<String, dynamic> map) {
    return NetworkInsight(
      id: map['id'] as String? ?? 'insight_unknown',
      type: NetworkInsightType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NetworkInsightType.relationshipHealth,
      ),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      severity: NetworkInsightSeverity.values.firstWhere(
        (s) => s.name == map['severity'],
        orElse: () => NetworkInsightSeverity.info,
      ),
      metric: map['metric'] as String? ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      supportingPersonIds: (map['supportingPersonIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
