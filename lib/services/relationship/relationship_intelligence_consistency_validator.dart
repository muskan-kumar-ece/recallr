import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Severity level of a detected consistency anomaly.
enum ConsistencySeverity {
  critical,
  warning,
  info,
}

/// A specific consistency rule violation detected across relationship intelligence outputs.
@immutable
class RelationshipConsistencyIssue {
  final String personId;
  final ConsistencySeverity severity;
  final String rule;
  final String description;

  const RelationshipConsistencyIssue({
    required this.personId,
    required this.severity,
    required this.rule,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        'personId': personId,
        'severity': severity.name,
        'rule': rule,
        'description': description,
      };

  @override
  String toString() => '[$rule][$severity] $personId: $description';
}

/// Comprehensive consistency validation report.
@immutable
class RelationshipConsistencyReport {
  final List<RelationshipConsistencyIssue> issues;
  final DateTime validatedAt;

  RelationshipConsistencyReport({
    List<RelationshipConsistencyIssue> issues = const [],
    DateTime? validatedAt,
  })  : issues = List.unmodifiable(issues),
        validatedAt = validatedAt ?? DateTime.now();

  bool get isValid => issues.isEmpty;
  bool get hasCriticalIssues =>
      issues.any((i) => i.severity == ConsistencySeverity.critical);
  bool get hasWarnings =>
      issues.any((i) => i.severity == ConsistencySeverity.warning);
  int get issueCount => issues.length;
  int get criticalCount =>
      issues.where((i) => i.severity == ConsistencySeverity.critical).length;
  int get warningCount =>
      issues.where((i) => i.severity == ConsistencySeverity.warning).length;

  List<RelationshipConsistencyIssue> issuesForPerson(String personId) =>
      issues.where((i) => i.personId == personId).toList();

  @override
  String toString() => isValid
      ? 'RelationshipConsistencyReport: VALID (0 issues)'
      : 'RelationshipConsistencyReport: INVALID (${issues.length} issues: ${issues.map((i) => i.rule).join(", ")})';
}

/// Exception thrown when strict consistency validation fails on critical issues.
class ConsistencyException implements Exception {
  final List<RelationshipConsistencyIssue> issues;
  const ConsistencyException(this.issues);

  @override
  String toString() => 'ConsistencyException: ${issues.join("; ")}';
}

/// Validates cross-engine consistency across 13H-01 -> 13H-06 relationship intelligence outputs.
///
/// Ensures deterministic facts do not contradict each other (e.g. zero interactions
/// producing strong state or strengthening momentum, critical attention without risk, etc.).
class RelationshipIntelligenceConsistencyValidator {
  const RelationshipIntelligenceConsistencyValidator();

  /// Validates a single person's composed intelligence.
  List<RelationshipConsistencyIssue> validatePerson(
    UnifiedPersonRelationshipIntelligence person, {
    bool throwOnCritical = false,
  }) {
    final issues = <RelationshipConsistencyIssue>[];
    final pId = person.personId;
    final totalInteractions = person.relationshipSignals.interactionCount;

    // Rule 1: Zero interactions cannot yield RelationshipState.strong
    if (totalInteractions == 0 &&
        person.relationshipState == RelationshipState.strong) {
      issues.add(
        RelationshipConsistencyIssue(
          personId: pId,
          severity: ConsistencySeverity.critical,
          rule: 'NO_INTERACTION_STRONG_STATE',
          description:
              'Relationship for $pId has 0 recorded interactions but is marked as RelationshipState.strong.',
        ),
      );
    }

    // Rule 2: Zero interactions cannot yield MomentumDirection.strengthening
    if (totalInteractions == 0 &&
        person.momentumDirection == MomentumDirection.strengthening) {
      issues.add(
        RelationshipConsistencyIssue(
          personId: pId,
          severity: ConsistencySeverity.critical,
          rule: 'NO_INTERACTION_STRENGTHENING_MOMENTUM',
          description:
              'Relationship for $pId has 0 recorded interactions but is marked as MomentumDirection.strengthening.',
        ),
      );
    }

    // Rule 3: Attention marked critical must have a non-empty reason or score >= 50
    if (person.attentionPriority == AttentionPriority.critical) {
      final reasons = person.relationshipAttention?.reasons ?? const [];
      final score = person.attentionScore;
      if (reasons.isEmpty && score < 50.0) {
        issues.add(
          RelationshipConsistencyIssue(
            personId: pId,
            severity: ConsistencySeverity.critical,
            rule: 'UNSUPPORTED_CRITICAL_ATTENTION',
            description:
                'Attention for $pId is marked critical without supporting risk reasons or sufficient score ($score).',
          ),
        );
      }
    }

    // Rule 4: InsufficientHistory momentum must not claim an active/strict cadence ratio
    if (person.momentumDirection == MomentumDirection.insufficientHistory &&
        person.relationshipMomentum != null) {
      final cadence = person.relationshipMomentum!.cadence;
      if (cadence.totalDistinctDates > 2 && (cadence.cadenceRatio ?? 0.0) > 0.0) {
        issues.add(
          RelationshipConsistencyIssue(
            personId: pId,
            severity: ConsistencySeverity.warning,
            rule: 'INSUFFICIENT_HISTORY_WITH_CADENCE',
            description:
                'Momentum is insufficientHistory but cadence reports ${cadence.totalDistinctDates} dates with cadenceRatio ${cadence.cadenceRatio}.',
          ),
        );
      }
    }

    // Rule 5: Strong healthy relationships with zero risk must not be critical attention
    if (person.relationshipState == RelationshipState.strong &&
        person.relationshipSignals.overdueFollowUpCount == 0 &&
        person.attentionPriority == AttentionPriority.critical &&
        (person.relationshipAttention?.reasons.isEmpty ?? true)) {
      issues.add(
        RelationshipConsistencyIssue(
          personId: pId,
          severity: ConsistencySeverity.critical,
          rule: 'HEALTHY_STRONG_AS_CRITICAL_ATTENTION',
          description:
              'Strong relationship with 0 overdue follow-ups and no risk factors is marked critical attention.',
        ),
      );
    }

    if (throwOnCritical &&
        issues.any((i) => i.severity == ConsistencySeverity.critical)) {
      throw ConsistencyException(issues);
    }

    return issues;
  }

  /// Validates the entire network intelligence against person models.
  List<RelationshipConsistencyIssue> validateNetwork(
    UnifiedNetworkRelationshipIntelligence network,
    List<UnifiedPersonRelationshipIntelligence> people,
  ) {
    final issues = <RelationshipConsistencyIssue>[];

    // Rule 6: Network aggregate counts must match actual people count
    if (network.totalPeople != people.length) {
      issues.add(
        RelationshipConsistencyIssue(
          personId: 'NETWORK_AGGREGATE',
          severity: ConsistencySeverity.critical,
          rule: 'NETWORK_COUNT_MISMATCH',
          description:
              'Network health totalPeople (${network.totalPeople}) does not equal snapshot people count (${people.length}).',
        ),
      );
    }

    // Rule 7: Connected + isolated must equal total graph nodes
    if (network.graph.nodeCount > 0 &&
        (network.connectedPeople + network.isolatedPeople) != network.graph.nodeCount) {
      issues.add(
        RelationshipConsistencyIssue(
          personId: 'NETWORK_TOPOLOGY',
          severity: ConsistencySeverity.warning,
          rule: 'TOPOLOGY_COUNT_MISMATCH',
          description:
              'Connected (${network.connectedPeople}) + isolated (${network.isolatedPeople}) does not match graph nodes (${network.graph.nodeCount}).',
        ),
      );
    }

    return issues;
  }

  /// Validates a complete snapshot.
  RelationshipConsistencyReport validateSnapshot(
    RelationshipIntelligenceSnapshot snapshot,
  ) {
    final allIssues = <RelationshipConsistencyIssue>[];

    for (final person in snapshot.people) {
      allIssues.addAll(validatePerson(person));
    }

    allIssues.addAll(validateNetwork(snapshot.network, snapshot.people));

    return RelationshipConsistencyReport(
      issues: allIssues,
      validatedAt: DateTime.now(),
    );
  }
}
