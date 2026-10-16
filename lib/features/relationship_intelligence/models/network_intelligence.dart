import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import 'network_insight.dart';
import 'network_trend.dart';
import 'relationship_attention.dart';
import 'relationship_intelligence.dart';

/// Overall classification of professional network health.
enum NetworkHealthLevel {
  excellent(85.0, 100.0),
  healthy(70.0, 84.9),
  developing(50.0, 69.9),
  atRisk(30.0, 49.9),
  critical(0.0, 29.9);

  final double minScore;
  final double maxScore;
  const NetworkHealthLevel(this.minScore, this.maxScore);

  String get displayName {
    switch (this) {
      case NetworkHealthLevel.excellent:
        return 'Excellent';
      case NetworkHealthLevel.healthy:
        return 'Healthy';
      case NetworkHealthLevel.developing:
        return 'Developing';
      case NetworkHealthLevel.atRisk:
        return 'At Risk';
      case NetworkHealthLevel.critical:
        return 'Critical Attention Required';
    }
  }

  String get badgeLabel => name == 'atRisk' ? 'AT RISK' : name.toUpperCase();

  String get description {
    switch (this) {
      case NetworkHealthLevel.excellent:
        return 'Your professional network is highly engaged with active communication and minimal risk.';
      case NetworkHealthLevel.healthy:
        return 'Your network is active, with most key relationships recently engaged.';
      case NetworkHealthLevel.developing:
        return 'Your network is growing, but several relationships could benefit from renewed contact.';
      case NetworkHealthLevel.atRisk:
        return 'Multiple relationships are cooling or neglected with overdue commitments.';
      case NetworkHealthLevel.critical:
        return 'Significant relationship decay detected across key professional connections.';
    }
  }

  Color get colorToken {
    switch (this) {
      case NetworkHealthLevel.excellent:
        return RecallrColors.emeraldVerified;
      case NetworkHealthLevel.healthy:
        return RecallrColors.aiCyanHighlight;
      case NetworkHealthLevel.developing:
        return RecallrColors.warmAmberGold;
      case NetworkHealthLevel.atRisk:
        return RecallrColors.warmAmberGold;
      case NetworkHealthLevel.critical:
        return RecallrColors.crimsonAlert;
    }
  }
}

/// Small-N statistical confidence tier for network metrics.
enum NetworkConfidence {
  limited,
  moderate,
  high;

  String get displayName {
    switch (this) {
      case NetworkConfidence.limited:
        return 'Limited Data';
      case NetworkConfidence.moderate:
        return 'Developing Dataset';
      case NetworkConfidence.high:
        return 'High Confidence';
    }
  }

  String get description {
    switch (this) {
      case NetworkConfidence.limited:
        return 'Keep building relationship history to unlock more reliable network insights.';
      case NetworkConfidence.moderate:
        return 'Sufficient network size to observe emerging trends and health patterns.';
      case NetworkConfidence.high:
        return 'Strong statistical sample size for comprehensive relationship intelligence.';
    }
  }

  Color get colorToken {
    switch (this) {
      case NetworkConfidence.limited:
        return RecallrColors.textTertiary;
      case NetworkConfidence.moderate:
        return RecallrColors.warmAmberGold;
      case NetworkConfidence.high:
        return RecallrColors.emeraldVerified;
    }
  }
}

/// Aggregate metrics and score representing the overall health of the user's network.
@immutable
class NetworkHealth {
  final double score;
  final NetworkHealthLevel level;
  final NetworkConfidence confidence;
  final int totalPeople;
  final int activeRelationships;
  final int strongRelationships;
  final int coolingRelationships;
  final int neglectedRelationships;
  final int dormantRelationships;
  final int newRelationships;
  final int relationshipsNeedingAttention;
  final int overdueFollowUps;
  final int interactionCount;
  final int recentInteractionCount;
  final double followUpCompletionRate;
  final double relationshipCoverage;
  final DateTime generatedAt;

  const NetworkHealth({
    required this.score,
    required this.level,
    required this.confidence,
    required this.totalPeople,
    required this.activeRelationships,
    required this.strongRelationships,
    required this.coolingRelationships,
    required this.neglectedRelationships,
    required this.dormantRelationships,
    required this.newRelationships,
    required this.relationshipsNeedingAttention,
    required this.overdueFollowUps,
    required this.interactionCount,
    required this.recentInteractionCount,
    required this.followUpCompletionRate,
    required this.relationshipCoverage,
    required this.generatedAt,
  });

  /// Factory for an empty network (0 contacts).
  factory NetworkHealth.empty({DateTime? referenceDate}) {
    return NetworkHealth(
      score: 0.0,
      level: NetworkHealthLevel.developing,
      confidence: NetworkConfidence.limited,
      totalPeople: 0,
      activeRelationships: 0,
      strongRelationships: 0,
      coolingRelationships: 0,
      neglectedRelationships: 0,
      dormantRelationships: 0,
      newRelationships: 0,
      relationshipsNeedingAttention: 0,
      overdueFollowUps: 0,
      interactionCount: 0,
      recentInteractionCount: 0,
      followUpCompletionRate: 1.0,
      relationshipCoverage: 0.0,
      generatedAt: referenceDate ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'level': level.name,
      'confidence': confidence.name,
      'totalPeople': totalPeople,
      'activeRelationships': activeRelationships,
      'strongRelationships': strongRelationships,
      'coolingRelationships': coolingRelationships,
      'neglectedRelationships': neglectedRelationships,
      'dormantRelationships': dormantRelationships,
      'newRelationships': newRelationships,
      'relationshipsNeedingAttention': relationshipsNeedingAttention,
      'overdueFollowUps': overdueFollowUps,
      'interactionCount': interactionCount,
      'recentInteractionCount': recentInteractionCount,
      'followUpCompletionRate': followUpCompletionRate,
      'relationshipCoverage': relationshipCoverage,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory NetworkHealth.fromMap(Map<String, dynamic> map) {
    return NetworkHealth(
      score: (map['score'] as num?)?.toDouble().clamp(0.0, 100.0) ?? 0.0,
      level: NetworkHealthLevel.values.firstWhere(
        (l) => l.name == map['level'],
        orElse: () => NetworkHealthLevel.developing,
      ),
      confidence: NetworkConfidence.values.firstWhere(
        (c) => c.name == map['confidence'],
        orElse: () => NetworkConfidence.limited,
      ),
      totalPeople: (map['totalPeople'] as num?)?.toInt() ?? 0,
      activeRelationships: (map['activeRelationships'] as num?)?.toInt() ?? 0,
      strongRelationships: (map['strongRelationships'] as num?)?.toInt() ?? 0,
      coolingRelationships: (map['coolingRelationships'] as num?)?.toInt() ?? 0,
      neglectedRelationships: (map['neglectedRelationships'] as num?)?.toInt() ?? 0,
      dormantRelationships: (map['dormantRelationships'] as num?)?.toInt() ?? 0,
      newRelationships: (map['newRelationships'] as num?)?.toInt() ?? 0,
      relationshipsNeedingAttention: (map['relationshipsNeedingAttention'] as num?)?.toInt() ?? 0,
      overdueFollowUps: (map['overdueFollowUps'] as num?)?.toInt() ?? 0,
      interactionCount: (map['interactionCount'] as num?)?.toInt() ?? 0,
      recentInteractionCount: (map['recentInteractionCount'] as num?)?.toInt() ?? 0,
      followUpCompletionRate: (map['followUpCompletionRate'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0,
      relationshipCoverage: (map['relationshipCoverage'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0,
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Canonical snapshot of complete network-level relationship intelligence.
@immutable
class NetworkIntelligence {
  final NetworkHealth health;
  final List<NetworkTrend> trends;
  final List<NetworkInsight> insights;
  final List<RelationshipAttention> topAttention;
  final List<PersonRelationshipIntelligence> recentlyStrengthened;
  final List<PersonRelationshipIntelligence> coolingRelationships;
  final DateTime generatedAt;

  const NetworkIntelligence({
    required this.health,
    this.trends = const [],
    this.insights = const [],
    this.topAttention = const [],
    this.recentlyStrengthened = const [],
    this.coolingRelationships = const [],
    required this.generatedAt,
  });

  /// Factory for empty network intelligence snapshot.
  factory NetworkIntelligence.empty({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    return NetworkIntelligence(
      health: NetworkHealth.empty(referenceDate: now),
      trends: const [],
      insights: const [],
      topAttention: const [],
      recentlyStrengthened: const [],
      coolingRelationships: const [],
      generatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'health': health.toMap(),
      'trends': trends.map((t) => t.toMap()).toList(),
      'insights': insights.map((i) => i.toMap()).toList(),
      'topAttention': topAttention.map((a) => a.toMap()).toList(),
      'recentlyStrengthened': recentlyStrengthened.map((s) => s.toMap()).toList(),
      'coolingRelationships': coolingRelationships.map((c) => c.toMap()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory NetworkIntelligence.fromMap(Map<String, dynamic> map) {
    return NetworkIntelligence(
      health: map['health'] != null
          ? NetworkHealth.fromMap(Map<String, dynamic>.from(map['health'] as Map))
          : NetworkHealth.empty(),
      trends: (map['trends'] as List<dynamic>?)
              ?.map((t) => NetworkTrend.fromMap(Map<String, dynamic>.from(t as Map)))
              .toList() ??
          const [],
      insights: (map['insights'] as List<dynamic>?)
              ?.map((i) => NetworkInsight.fromMap(Map<String, dynamic>.from(i as Map)))
              .toList() ??
          const [],
      topAttention: (map['topAttention'] as List<dynamic>?)
              ?.map((a) => RelationshipAttention.fromMap(Map<String, dynamic>.from(a as Map)))
              .toList() ??
          const [],
      recentlyStrengthened: (map['recentlyStrengthened'] as List<dynamic>?)
              ?.map((s) => PersonRelationshipIntelligence.fromMap(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          const [],
      coolingRelationships: (map['coolingRelationships'] as List<dynamic>?)
              ?.map((c) => PersonRelationshipIntelligence.fromMap(Map<String, dynamic>.from(c as Map)))
              .toList() ??
          const [],
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
