import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import 'relationship_signals.dart';
import 'relationship_state.dart';

/// Categories of proactive relationship intelligence actions in Recallr.
enum RelationshipActionType {
  /// Proactive reconnection with a contact whose interaction recency has cooled off.
  reconnect,

  /// General relationship follow-up or scheduled check-in.
  followUp,

  /// High-priority resolution of an unfulfilled commitment past due date.
  completeOverdueFollowUp,

  /// Periodic review of an active or high-strength relationship.
  reviewRelationship,

  /// Review and reflection on a recently completed interaction or meeting.
  reviewRecentInteraction,

  /// Suggestion to capture missing context/cards for contacts with interactions but sparse memories.
  captureMissingContext;

  /// Display title prefix for action cards.
  String get label {
    switch (this) {
      case RelationshipActionType.reconnect:
        return 'Reconnect';
      case RelationshipActionType.followUp:
        return 'Follow-up';
      case RelationshipActionType.completeOverdueFollowUp:
        return 'Complete Overdue Commitment';
      case RelationshipActionType.reviewRelationship:
        return 'Relationship Review';
      case RelationshipActionType.reviewRecentInteraction:
        return 'Review Interaction';
      case RelationshipActionType.captureMissingContext:
        return 'Capture Missing Details';
    }
  }

  /// Default icon representing this action.
  IconData get icon {
    switch (this) {
      case RelationshipActionType.reconnect:
        return Icons.sync_alt_rounded;
      case RelationshipActionType.followUp:
        return Icons.task_alt_rounded;
      case RelationshipActionType.completeOverdueFollowUp:
        return Icons.error_outline_rounded;
      case RelationshipActionType.reviewRelationship:
        return Icons.visibility_outlined;
      case RelationshipActionType.reviewRecentInteraction:
        return Icons.history_edu_rounded;
      case RelationshipActionType.captureMissingContext:
        return Icons.note_add_outlined;
    }
  }
}

/// Deterministic urgency and priority tiers for recommended actions.
enum RelationshipActionPriority {
  urgent,
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case RelationshipActionPriority.urgent:
        return 'Urgent';
      case RelationshipActionPriority.high:
        return 'High';
      case RelationshipActionPriority.medium:
        return 'Medium';
      case RelationshipActionPriority.low:
        return 'Low';
    }
  }

  String get badgeLabel {
    switch (this) {
      case RelationshipActionPriority.urgent:
        return 'URGENT';
      case RelationshipActionPriority.high:
        return 'HIGH';
      case RelationshipActionPriority.medium:
        return 'MEDIUM';
      case RelationshipActionPriority.low:
        return 'LOW';
    }
  }

  Color get colorToken {
    switch (this) {
      case RelationshipActionPriority.urgent:
        return RecallrColors.crimsonAlert;
      case RelationshipActionPriority.high:
        return RecallrColors.warmAmberGold;
      case RelationshipActionPriority.medium:
        return RecallrColors.aiCyanHighlight;
      case RelationshipActionPriority.low:
        return RecallrColors.textSecondary;
    }
  }

  int get rank {
    switch (this) {
      case RelationshipActionPriority.urgent:
        return 4;
      case RelationshipActionPriority.high:
        return 3;
      case RelationshipActionPriority.medium:
        return 2;
      case RelationshipActionPriority.low:
        return 1;
    }
  }
}

/// Lifecycle status of a proactive relationship action.
enum RelationshipActionStatus {
  suggested,
  dismissed,
  snoozed,
  completed;

  String get label {
    switch (this) {
      case RelationshipActionStatus.suggested:
        return 'Suggested';
      case RelationshipActionStatus.dismissed:
        return 'Dismissed';
      case RelationshipActionStatus.snoozed:
        return 'Snoozed';
      case RelationshipActionStatus.completed:
        return 'Completed';
    }
  }
}

/// Structured, deterministic proactive recommendation for a relationship.
@immutable
class RelationshipAction {
  final String id;
  final String personId;
  final String personName;
  final RelationshipActionType type;
  final RelationshipActionPriority priority;
  final RelationshipActionStatus status;
  final String title;
  final String description;
  final String reason;
  final String recommendedAt;
  final String targetRoute;
  final RelationshipSignals? sourceSignals;
  final RelationshipState relationshipState;
  final double relationshipScore;
  final String deduplicationKey;
  final DateTime generatedAt;

  const RelationshipAction({
    required this.id,
    required this.personId,
    required this.personName,
    required this.type,
    required this.priority,
    this.status = RelationshipActionStatus.suggested,
    required this.title,
    required this.description,
    required this.reason,
    required this.recommendedAt,
    required this.targetRoute,
    this.sourceSignals,
    this.relationshipState = RelationshipState.newRelationship,
    this.relationshipScore = 0.0,
    required this.deduplicationKey,
    required this.generatedAt,
  });

  factory RelationshipAction.simple({
    required String id,
    required String personId,
    required String personName,
    required RelationshipActionType type,
    RelationshipActionPriority priority = RelationshipActionPriority.medium,
    RelationshipActionStatus status = RelationshipActionStatus.suggested,
    required String title,
    String description = '',
    String reason = '',
    String? recommendedAt,
    String? targetRoute,
    String? deduplicationKey,
    DateTime? generatedAt,
  }) {
    final now = generatedAt ?? DateTime.now();
    return RelationshipAction(
      id: id,
      personId: personId,
      personName: personName,
      type: type,
      priority: priority,
      status: status,
      title: title,
      description: description,
      reason: reason,
      recommendedAt: recommendedAt ?? now.toIso8601String(),
      targetRoute: targetRoute ?? '/person/$personId',
      deduplicationKey: deduplicationKey ?? 'action_${id}_${now.millisecondsSinceEpoch}',
      generatedAt: now,
    );
  }

  /// True if the action is currently active and awaiting user decision.
  bool get isSuggested => status == RelationshipActionStatus.suggested;

  /// True if priority is high or urgent.
  bool get isHighPriority =>
      priority == RelationshipActionPriority.urgent ||
      priority == RelationshipActionPriority.high;

  RelationshipAction copyWith({
    String? id,
    String? personId,
    String? personName,
    RelationshipActionType? type,
    RelationshipActionPriority? priority,
    RelationshipActionStatus? status,
    String? title,
    String? description,
    String? reason,
    String? recommendedAt,
    String? targetRoute,
    RelationshipSignals? sourceSignals,
    RelationshipState? relationshipState,
    double? relationshipScore,
    String? deduplicationKey,
    DateTime? generatedAt,
  }) {
    return RelationshipAction(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      recommendedAt: recommendedAt ?? this.recommendedAt,
      targetRoute: targetRoute ?? this.targetRoute,
      sourceSignals: sourceSignals ?? this.sourceSignals,
      relationshipState: relationshipState ?? this.relationshipState,
      relationshipScore: relationshipScore ?? this.relationshipScore,
      deduplicationKey: deduplicationKey ?? this.deduplicationKey,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personId': personId,
      'personName': personName,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'title': title,
      'description': description,
      'reason': reason,
      'recommendedAt': recommendedAt,
      'targetRoute': targetRoute,
      'relationshipState': relationshipState.name,
      'relationshipScore': relationshipScore,
      'deduplicationKey': deduplicationKey,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory RelationshipAction.fromMap(Map<String, dynamic> map, [String? docId]) {
    return RelationshipAction(
      id: docId ?? map['id']?.toString() ?? '',
      personId: map['personId']?.toString() ?? '',
      personName: map['personName']?.toString() ?? '',
      type: RelationshipActionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RelationshipActionType.followUp,
      ),
      priority: RelationshipActionPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => RelationshipActionPriority.medium,
      ),
      status: RelationshipActionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RelationshipActionStatus.suggested,
      ),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      recommendedAt: map['recommendedAt']?.toString() ?? 'Soon',
      targetRoute: map['targetRoute']?.toString() ?? '',
      relationshipState: RelationshipState.fromValue(map['relationshipState']?.toString()),
      relationshipScore: (map['relationshipScore'] as num?)?.toDouble() ?? 0.0,
      deduplicationKey: map['deduplicationKey']?.toString() ?? '',
      generatedAt: DateTime.tryParse(map['generatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
