import '../../features/relationship_intelligence/models/models.dart';

/// Pure explanation generator for relationship attention.
/// Grounded strictly in verified Firestore signals without LLM hallucinations.
class RelationshipAttentionExplanation {
  RelationshipAttentionExplanation._();

  /// Generates a list of grounded reasons explaining why a person needs attention.
  static List<RelationshipAttentionReason> generateReasons({
    required PersonRelationshipIntelligence intelligence,
    required String personName,
    String? company,
    RelationshipAction? primaryAction,
  }) {
    final signals = intelligence.signals;
    final state = intelligence.state;
    final reasons = <RelationshipAttentionReason>[];
    final displayName = personName.isNotEmpty ? personName : 'this contact';

    // 1. Overdue follow-ups
    if (signals.hasOverdueFollowUp) {
      final count = signals.overdueFollowUpCount;
      reasons.add(RelationshipAttentionReason(
        code: 'overdue_follow_up',
        title: 'Overdue Commitment',
        description: count == 1
            ? 'You have 1 overdue follow-up with $displayName.'
            : 'You have $count overdue follow-ups with $displayName.',
        weight: 1.0,
      ));
    }

    // 2. Cooling relationship
    if (state == RelationshipState.cooling) {
      final days = signals.daysSinceLastInteraction ?? 35;
      reasons.add(RelationshipAttentionReason(
        code: 'relationship_cooling',
        title: 'Cooling Relationship',
        description: 'Your relationship with $displayName is cooling. Your last recorded interaction was $days days ago.',
        weight: 0.85,
      ));
    }

    // 3. Neglected relationship
    if (state == RelationshipState.neglected) {
      final days = signals.daysSinceLastInteraction ?? 60;
      reasons.add(RelationshipAttentionReason(
        code: 'relationship_neglected',
        title: 'Neglected Relationship',
        description: 'Your connection with $displayName has lapsed with no interactions for $days+ days.',
        weight: 0.90,
      ));
    }

    // 4. High-value / Strong relationship maintenance
    if (state == RelationshipState.strong && (signals.daysSinceLastInteraction ?? 0) >= 15) {
      final days = signals.daysSinceLastInteraction!;
      reasons.add(RelationshipAttentionReason(
        code: 'strong_relationship_check_in',
        title: 'High-Value Check-in',
        description: 'Strong relationship with $displayName has had no check-ins for $days days. Reach out to stay top of mind.',
        weight: 0.70,
      ));
    }

    // 5. Active upcoming follow-ups
    if (signals.activeFollowUpCount > 0 && !signals.hasOverdueFollowUp) {
      final count = signals.activeFollowUpCount;
      reasons.add(RelationshipAttentionReason(
        code: 'recent_commitment',
        title: 'Active Follow-up',
        description: count == 1
            ? 'You have 1 active follow-up with $displayName.'
            : 'You have $count active follow-ups with $displayName.',
        weight: 0.60,
      ));
    }

    // 6. Recent interaction review (only for non-new established contacts)
    if (signals.daysSinceLastInteraction != null &&
        signals.daysSinceLastInteraction! <= 2 &&
        signals.interactionCount >= 3) {
      final days = signals.daysSinceLastInteraction!;
      reasons.add(RelationshipAttentionReason(
        code: 'recent_interaction',
        title: 'Review Recent Interaction',
        description: days == 0
            ? 'You interacted with $displayName today. Review notes and record any follow-ups.'
            : 'You interacted with $displayName $days day(s) ago. Review notes and record any follow-ups.',
        weight: 0.50,
      ));
    }

    // 7. Missing context / Sparse notes
    if (signals.interactionCount >= 3 && signals.memoryCount == 0) {
      reasons.add(RelationshipAttentionReason(
        code: 'missing_context',
        title: 'Capture Missing Context',
        description: 'You have recorded ${signals.interactionCount} interactions with $displayName but no saved context or notes.',
        weight: 0.40,
      ));
    }

    // Fallback: only add periodic review if relationship is established (count >= 3)
    // AND the last interaction was more than 30 days ago.
    // Never trigger for new contacts (count < 3) or recently active contacts.
    if (reasons.isEmpty) {
      final days = signals.daysSinceLastInteraction;
      final isEstablishedWithLapse = signals.interactionCount >= 3 && (days == null || days > 30);
      if (isEstablishedWithLapse) {
        reasons.add(RelationshipAttentionReason(
          code: 'general_review',
          title: 'Periodic Review',
          description: 'Periodic relationship check-in for $displayName.',
          weight: 0.20,
        ));
      }
    }

    return reasons;
  }

  /// Calculates recommended timing based on attention priority and signals.
  static String generateRecommendedTiming({
    required RelationshipAttentionPriority priority,
    required PersonRelationshipIntelligence intelligence,
  }) {
    final signals = intelligence.signals;

    if (priority == RelationshipAttentionPriority.critical || signals.hasOverdueFollowUp) {
      return 'Today';
    }

    if (priority == RelationshipAttentionPriority.high) {
      if (intelligence.state == RelationshipState.cooling || intelligence.state == RelationshipState.neglected) {
        return 'This week';
      }
      return 'Within 2–3 days';
    }

    if (priority == RelationshipAttentionPriority.medium) {
      if (signals.daysSinceLastInteraction != null && signals.daysSinceLastInteraction! <= 2) {
        return 'Within 2–3 days';
      }
      return 'This week';
    }

    return 'Soon';
  }
}
