import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import 'relationship_action.dart';
import 'relationship_state.dart';
import 'relationship_strength.dart';

/// Semantic priority tiers for relationship attention.
typedef AttentionPriority = RelationshipAttentionPriority;

enum RelationshipAttentionPriority {
  critical,
  high,
  medium,
  low;

  static const RelationshipAttentionPriority none = RelationshipAttentionPriority.low;

  String get displayName {
    switch (this) {
      case RelationshipAttentionPriority.critical:
        return 'Critical';
      case RelationshipAttentionPriority.high:
        return 'High Priority';
      case RelationshipAttentionPriority.medium:
        return 'Medium Priority';
      case RelationshipAttentionPriority.low:
        return 'Low Priority';
    }
  }

  String get badgeLabel {
    switch (this) {
      case RelationshipAttentionPriority.critical:
        return 'CRITICAL';
      case RelationshipAttentionPriority.high:
        return 'HIGH';
      case RelationshipAttentionPriority.medium:
        return 'MEDIUM';
      case RelationshipAttentionPriority.low:
        return 'LOW';
    }
  }

  int get rank {
    switch (this) {
      case RelationshipAttentionPriority.critical:
        return 4;
      case RelationshipAttentionPriority.high:
        return 3;
      case RelationshipAttentionPriority.medium:
        return 2;
      case RelationshipAttentionPriority.low:
        return 1;
    }
  }

  Color get colorToken {
    switch (this) {
      case RelationshipAttentionPriority.critical:
        return RecallrColors.crimsonAlert;
      case RelationshipAttentionPriority.high:
        return RecallrColors.warmAmberGold;
      case RelationshipAttentionPriority.medium:
        return RecallrColors.aiCyanHighlight;
      case RelationshipAttentionPriority.low:
        return RecallrColors.textSecondary;
    }
  }

  String get description {
    switch (this) {
      case RelationshipAttentionPriority.critical:
        return 'Severe commitment risk or high-value relationship decay requiring immediate action.';
      case RelationshipAttentionPriority.high:
        return 'Significant cooling or overdue follow-up requiring attention this week.';
      case RelationshipAttentionPriority.medium:
        return 'Moderate attention opportunity or recent interaction review.';
      case RelationshipAttentionPriority.low:
        return 'Routine relationship maintenance or context enrichment.';
    }
  }
}

/// A concrete, explainable reason why a person requires relationship attention.
@immutable
class RelationshipAttentionReason {
  final String code;
  final String title;
  final String description;
  final double weight;

  const RelationshipAttentionReason({
    required this.code,
    required this.title,
    required this.description,
    this.weight = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'weight': weight,
    };
  }

  factory RelationshipAttentionReason.fromMap(Map<String, dynamic> map) {
    return RelationshipAttentionReason(
      code: map['code']?.toString() ?? 'general_review',
      title: map['title']?.toString() ?? 'Relationship Review',
      description: map['description']?.toString() ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelationshipAttentionReason &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          title == other.title &&
          description == other.description &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(code, title, description, weight);
}

/// Canonical, immutable domain entity representing prioritized relationship attention for a person.
@immutable
class RelationshipAttention {
  final String personId;
  final String personName;
  final String? company;
  final double attentionScore;
  final RelationshipAttentionPriority priority;
  final RelationshipState relationshipState;
  final RelationshipStrength relationshipStrength;
  final List<RelationshipAttentionReason> reasons;
  final RelationshipAction? primaryAction;
  final String recommendedTiming;
  final DateTime generatedAt;
  final String deduplicationKey;

  const RelationshipAttention({
    required this.personId,
    required this.personName,
    this.company,
    required this.attentionScore,
    required this.priority,
    required this.relationshipState,
    required this.relationshipStrength,
    required this.reasons,
    this.primaryAction,
    required this.recommendedTiming,
    required this.generatedAt,
    required this.deduplicationKey,
  });

  factory RelationshipAttention.simple({
    required String personId,
    required String personName,
    String? company,
    double attentionScore = 0.0,
    RelationshipAttentionPriority priority = RelationshipAttentionPriority.none,
    RelationshipState relationshipState = RelationshipState.newRelationship,
    RelationshipStrength? relationshipStrength,
    List<RelationshipAttentionReason> reasons = const [],
    RelationshipAction? primaryAction,
    String recommendedTiming = 'Within 14 days',
    DateTime? generatedAt,
    String? deduplicationKey,
  }) {
    final now = generatedAt ?? DateTime.now();
    return RelationshipAttention(
      personId: personId,
      personName: personName,
      company: company,
      attentionScore: attentionScore,
      priority: priority,
      relationshipState: relationshipState,
      relationshipStrength: relationshipStrength ?? RelationshipStrength.zero(),
      reasons: reasons,
      primaryAction: primaryAction,
      recommendedTiming: recommendedTiming,
      generatedAt: now,
      deduplicationKey: deduplicationKey ?? 'attention_${personId}_${now.millisecondsSinceEpoch}',
    );
  }

  /// Primary explanation reason if available.
  RelationshipAttentionReason? get primaryReason =>
      reasons.isNotEmpty ? reasons.first : null;

  /// Supporting secondary reasons.
  List<RelationshipAttentionReason> get supportingReasons =>
      reasons.length > 1 ? reasons.sublist(1) : const [];

  /// Alias for attentionScore.
  double get score => attentionScore;

  /// Whether this relationship requires active attention.
  bool get needsAttention =>
      priority == RelationshipAttentionPriority.critical ||
      priority == RelationshipAttentionPriority.high ||
      attentionScore >= 35.0;

  /// Human-readable summary of attention rationale.
  String get summary {
    if (reasons.isEmpty) {
      return 'No urgent attention required for $personName.';
    }
    return reasons.first.description;
  }

  RelationshipAttention copyWith({
    String? personId,
    String? personName,
    String? company,
    double? attentionScore,
    RelationshipAttentionPriority? priority,
    RelationshipState? relationshipState,
    RelationshipStrength? relationshipStrength,
    List<RelationshipAttentionReason>? reasons,
    RelationshipAction? primaryAction,
    String? recommendedTiming,
    DateTime? generatedAt,
    String? deduplicationKey,
  }) {
    return RelationshipAttention(
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      company: company ?? this.company,
      attentionScore: attentionScore ?? this.attentionScore,
      priority: priority ?? this.priority,
      relationshipState: relationshipState ?? this.relationshipState,
      relationshipStrength: relationshipStrength ?? this.relationshipStrength,
      reasons: reasons ?? this.reasons,
      primaryAction: primaryAction ?? this.primaryAction,
      recommendedTiming: recommendedTiming ?? this.recommendedTiming,
      generatedAt: generatedAt ?? this.generatedAt,
      deduplicationKey: deduplicationKey ?? this.deduplicationKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'personName': personName,
      'company': company,
      'attentionScore': attentionScore,
      'priority': priority.name,
      'relationshipState': relationshipState.toValue(),
      'relationshipStrength': relationshipStrength.toJson(),
      'reasons': reasons.map((r) => r.toMap()).toList(),
      'primaryAction': primaryAction?.toMap(),
      'recommendedTiming': recommendedTiming,
      'generatedAt': generatedAt.toIso8601String(),
      'deduplicationKey': deduplicationKey,
    };
  }

  factory RelationshipAttention.fromMap(Map<String, dynamic> map) {
    final priorityStr = map['priority']?.toString() ?? 'low';
    final priority = RelationshipAttentionPriority.values.firstWhere(
      (p) => p.name == priorityStr,
      orElse: () => RelationshipAttentionPriority.low,
    );

    final stateStr = map['relationshipState']?.toString() ?? 'new';
    final state = RelationshipState.values.firstWhere(
      (s) => s.toValue() == stateStr || s.name == stateStr,
      orElse: () => RelationshipState.newRelationship,
    );

    final rawStrength = map['relationshipStrength'];
    final strength = rawStrength is Map<String, dynamic>
        ? RelationshipStrength.fromJson(rawStrength)
        : RelationshipStrength.zero();

    final rawReasons = map['reasons'];
    final reasons = rawReasons is List
        ? rawReasons
            .map((r) => RelationshipAttentionReason.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList()
        : <RelationshipAttentionReason>[];

    final rawAction = map['primaryAction'];
    final primaryAction = rawAction is Map<String, dynamic>
        ? RelationshipAction.fromMap(rawAction, rawAction['id']?.toString() ?? '')
        : null;

    final scoreRaw = (map['attentionScore'] as num?)?.toDouble() ?? 0.0;
    final score = scoreRaw.isNaN || scoreRaw.isInfinite ? 0.0 : scoreRaw.clamp(0.0, 100.0);

    return RelationshipAttention(
      personId: map['personId']?.toString() ?? '',
      personName: map['personName']?.toString() ?? '',
      company: map['company']?.toString(),
      attentionScore: score,
      priority: priority,
      relationshipState: state,
      relationshipStrength: strength,
      reasons: reasons,
      primaryAction: primaryAction,
      recommendedTiming: map['recommendedTiming']?.toString() ?? 'Soon',
      generatedAt: DateTime.tryParse(map['generatedAt']?.toString() ?? '') ?? DateTime.now(),
      deduplicationKey: map['deduplicationKey']?.toString() ?? '',
    );
  }
}
