import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Abstract contract for deterministic relationship attention priority assignment.
abstract class RelationshipAttentionPriorityCalculator {
  RelationshipAttentionPriority calculate({
    required double attentionScore,
    required PersonRelationshipIntelligence intelligence,
  });
}

/// Production implementation of deterministic attention priority calculator.
/// Enforces strict precedence: CRITICAL > HIGH > MEDIUM > LOW.
/// Prevents strong relationships without actual risk from escalating to critical.
@immutable
class DeterministicRelationshipAttentionPriorityCalculator
    implements RelationshipAttentionPriorityCalculator {
  const DeterministicRelationshipAttentionPriorityCalculator();

  @override
  RelationshipAttentionPriority calculate({
    required double attentionScore,
    required PersonRelationshipIntelligence intelligence,
  }) {
    final signals = intelligence.signals;
    final state = intelligence.state;

    // Rule 1: CRITICAL (Precedence 1)
    // Severe commitment risk (multiple overdue or overdue on active/strong)
    // OR high attention score (>= 85) with severe commitment or neglected risk condition
    final hasSevereOverdue = signals.overdueFollowUpCount >= 2 ||
        (signals.hasOverdueFollowUp && (state == RelationshipState.strong || state == RelationshipState.active));
    final hasHighRiskNeglect = state == RelationshipState.neglected && signals.interactionCount >= 3;

    if ((attentionScore >= 85.0 && (signals.hasOverdueFollowUp || hasHighRiskNeglect)) || hasSevereOverdue) {
      return RelationshipAttentionPriority.critical;
    }

    // Rule 2: HIGH (Precedence 2)
    // Attention score >= 70 OR neglected with established history OR cooling with meaningful history OR has overdue follow-up
    if (attentionScore >= 70.0 ||
        signals.hasOverdueFollowUp ||
        (state == RelationshipState.neglected && intelligence.isEstablished) ||
        (state == RelationshipState.cooling && signals.interactionCount >= 2)) {
      return RelationshipAttentionPriority.high;
    }

    // Rule 3: MEDIUM (Precedence 3)
    // Attention score >= 40 OR cooling relationship OR active follow-up.
    // NOTE: interactionCount >= 2 alone does NOT trigger medium priority —
    // new contacts with 2 interactions must not receive attention alerts.
    if (attentionScore >= 40.0 ||
        state == RelationshipState.cooling ||
        signals.activeFollowUpCount > 0) {
      return RelationshipAttentionPriority.medium;
    }

    // Rule 4: LOW (Precedence 4)
    return RelationshipAttentionPriority.low;
  }
}
