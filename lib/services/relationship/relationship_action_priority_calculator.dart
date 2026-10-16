import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Abstract contract for calculating deterministic action priority.
abstract class RelationshipActionPriorityCalculator {
  RelationshipActionPriority calculate({
    required PersonRelationshipIntelligence intelligence,
    required RelationshipActionType type,
    FollowUpItem? specificFollowUp,
  });
}

/// Production deterministic implementation of RelationshipActionPriorityCalculator.
class DeterministicRelationshipActionPriorityCalculator
    implements RelationshipActionPriorityCalculator {
  const DeterministicRelationshipActionPriorityCalculator();

  @override
  RelationshipActionPriority calculate({
    required PersonRelationshipIntelligence intelligence,
    required RelationshipActionType type,
    FollowUpItem? specificFollowUp,
  }) {
    final signals = intelligence.signals;
    final state = intelligence.state;
    final score = intelligence.strength.score;

    switch (type) {
      case RelationshipActionType.completeOverdueFollowUp:
        // Overdue follow-up on strong or high-value relationship is URGENT
        if (state == RelationshipState.strong || score >= 70.0 || (signals.overdueFollowUpCount >= 2)) {
          return RelationshipActionPriority.urgent;
        }
        return RelationshipActionPriority.high;

      case RelationshipActionType.reconnect:
        // Neglected with deep history
        if (state == RelationshipState.neglected) {
          if (signals.interactionCount >= 5 || score >= 60.0) {
            return RelationshipActionPriority.high;
          }
          return RelationshipActionPriority.high;
        }
        // Cooling relationship with established past connection
        if (state == RelationshipState.cooling) {
          if (score >= 65.0 || signals.interactionCount >= 4) {
            return RelationshipActionPriority.high;
          }
          return RelationshipActionPriority.medium;
        }
        // Dormant relationship
        if (state == RelationshipState.dormant) {
          return RelationshipActionPriority.low;
        }
        return RelationshipActionPriority.medium;

      case RelationshipActionType.followUp:
        if (signals.hasActiveFollowUp) {
          return RelationshipActionPriority.medium;
        }
        if (state == RelationshipState.active) {
          return RelationshipActionPriority.medium;
        }
        return RelationshipActionPriority.low;

      case RelationshipActionType.reviewRecentInteraction:
        final days = signals.daysSinceLastInteraction;
        if (days != null && days <= 2) {
          return RelationshipActionPriority.medium;
        }
        return RelationshipActionPriority.low;

      case RelationshipActionType.captureMissingContext:
        if (signals.interactionCount >= 4 && (signals.memoryCount + signals.captureCount) == 0) {
          return RelationshipActionPriority.medium;
        }
        return RelationshipActionPriority.low;

      case RelationshipActionType.reviewRelationship:
        if (state == RelationshipState.strong) {
          return RelationshipActionPriority.medium;
        }
        return RelationshipActionPriority.low;
    }
  }
}
