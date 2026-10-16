import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Discrete network patterns deterministically recognized across the relationship graph.
enum NetworkPatternType {
  strongCluster,
  emergingCluster,
  coolingCluster,
  companyConcentration,
  relationshipBridge,
  isolatedContact,
  sharedContext,
  interactionConcentration,
  networkGap,
  balancedNetwork,
}

extension NetworkPatternTypeExt on NetworkPatternType {
  String get label {
    switch (this) {
      case NetworkPatternType.strongCluster:
        return 'Strong Relationship Cluster';
      case NetworkPatternType.emergingCluster:
        return 'Emerging Cluster';
      case NetworkPatternType.coolingCluster:
        return 'Cooling Cluster';
      case NetworkPatternType.companyConcentration:
        return 'Company Concentration';
      case NetworkPatternType.relationshipBridge:
        return 'Relationship Bridge';
      case NetworkPatternType.isolatedContact:
        return 'Isolated Contact';
      case NetworkPatternType.sharedContext:
        return 'Shared Project / Context';
      case NetworkPatternType.interactionConcentration:
        return 'Interaction Concentration';
      case NetworkPatternType.networkGap:
        return 'Network Gap';
      case NetworkPatternType.balancedNetwork:
        return 'Balanced Network';
    }
  }

  IconData get icon {
    switch (this) {
      case NetworkPatternType.strongCluster:
        return Icons.hub_outlined;
      case NetworkPatternType.emergingCluster:
        return Icons.auto_awesome_outlined;
      case NetworkPatternType.coolingCluster:
        return Icons.ac_unit_rounded;
      case NetworkPatternType.companyConcentration:
        return Icons.business_outlined;
      case NetworkPatternType.relationshipBridge:
        return Icons.alt_route_rounded;
      case NetworkPatternType.isolatedContact:
        return Icons.person_outline_rounded;
      case NetworkPatternType.sharedContext:
        return Icons.interests_outlined;
      case NetworkPatternType.interactionConcentration:
        return Icons.forum_outlined;
      case NetworkPatternType.networkGap:
        return Icons.warning_amber_rounded;
      case NetworkPatternType.balancedNetwork:
        return Icons.verified_outlined;
    }
  }
}

/// Priority / severity tier for detected network patterns.
enum NetworkPatternSeverity {
  critical,
  high,
  medium,
  low,
  info,
}

extension NetworkPatternSeverityExt on NetworkPatternSeverity {
  String get badgeLabel {
    switch (this) {
      case NetworkPatternSeverity.critical:
        return 'CRITICAL';
      case NetworkPatternSeverity.high:
        return 'HIGH';
      case NetworkPatternSeverity.medium:
        return 'MEDIUM';
      case NetworkPatternSeverity.low:
        return 'LOW';
      case NetworkPatternSeverity.info:
        return 'INFO';
    }
  }

  Color get colorToken {
    switch (this) {
      case NetworkPatternSeverity.critical:
        return RecallrColors.crimsonAlert;
      case NetworkPatternSeverity.high:
        return RecallrColors.warmAmberGold;
      case NetworkPatternSeverity.medium:
        return RecallrColors.aiCyanHighlight;
      case NetworkPatternSeverity.low:
        return RecallrColors.textSecondary;
      case NetworkPatternSeverity.info:
        return RecallrColors.aiElectricViolet;
    }
  }

  int get rankOrder {
    switch (this) {
      case NetworkPatternSeverity.critical:
        return 5;
      case NetworkPatternSeverity.high:
        return 4;
      case NetworkPatternSeverity.medium:
        return 3;
      case NetworkPatternSeverity.low:
        return 2;
      case NetworkPatternSeverity.info:
        return 1;
    }
  }
}

/// A factual, actionable pattern detected across the professional relationship network.
@immutable
class NetworkPattern implements Comparable<NetworkPattern> {
  final String id;
  final NetworkPatternType type;
  final NetworkPatternSeverity severity;
  final String title;
  final String description;
  final List<String> evidencePersonIds;
  final List<String> evidenceConnectionIds;
  final double impactScore; // Strictly bounded 0.0 to 100.0
  final String recommendedAction;
  final DateTime generatedAt;

  NetworkPattern({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required List<String> evidencePersonIds,
    required List<String> evidenceConnectionIds,
    required double impactScore,
    required this.recommendedAction,
    DateTime? generatedAt,
  })  : evidencePersonIds = List.unmodifiable(List<String>.from(evidencePersonIds)..sort()),
        evidenceConnectionIds = List.unmodifiable(List<String>.from(evidenceConnectionIds)..sort()),
        impactScore = impactScore.clamp(0.0, 100.0),
        generatedAt = generatedAt ?? DateTime.now();

  /// Deterministic sort order: severity DESC -> impactScore DESC -> id ASC.
  @override
  int compareTo(NetworkPattern other) {
    final severityComp = other.severity.rankOrder.compareTo(severity.rankOrder);
    if (severityComp != 0) return severityComp;

    final impactComp = other.impactScore.compareTo(impactScore);
    if (impactComp != 0) return impactComp;

    return id.compareTo(other.id);
  }

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'severity': severity.name,
        'title': title,
        'description': description,
        'evidencePersonIds': evidencePersonIds,
        'evidenceConnectionIds': evidenceConnectionIds,
        'impactScore': impactScore,
        'recommendedAction': recommendedAction,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory NetworkPattern.fromMap(Map<String, dynamic> map) {
    return NetworkPattern(
      id: map['id']?.toString() ?? '',
      type: NetworkPatternType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NetworkPatternType.sharedContext,
      ),
      severity: NetworkPatternSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => NetworkPatternSeverity.info,
      ),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      evidencePersonIds: (map['evidencePersonIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      evidenceConnectionIds: (map['evidenceConnectionIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      impactScore: (map['impactScore'] as num?)?.toDouble() ?? 0.0,
      recommendedAction: map['recommendedAction']?.toString() ?? '',
      generatedAt: map['generatedAt'] != null ? DateTime.tryParse(map['generatedAt'].toString()) : null,
    );
  }

  factory NetworkPattern.fromJson(Map<String, dynamic> json) => NetworkPattern.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkPattern &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
