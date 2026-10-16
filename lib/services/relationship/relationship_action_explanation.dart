import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Grounded, deterministic explanation generator for proactive relationship actions.
class RelationshipActionExplanation {
  RelationshipActionExplanation._();

  /// Formulates human-readable action title.
  static String generateTitle({
    required PersonProfile profile,
    required RelationshipActionType type,
  }) {
    final name = profile.name.isNotEmpty ? profile.name : 'Contact';
    switch (type) {
      case RelationshipActionType.reconnect:
        return 'Reconnect with $name';
      case RelationshipActionType.completeOverdueFollowUp:
        return 'Complete Overdue Commitment for $name';
      case RelationshipActionType.followUp:
        return 'Follow up with $name';
      case RelationshipActionType.reviewRelationship:
        return 'Review Relationship with $name';
      case RelationshipActionType.reviewRecentInteraction:
        return 'Review Recent Interaction with $name';
      case RelationshipActionType.captureMissingContext:
        return 'Capture Details for $name';
    }
  }

  /// Formulates grounded context description without hallucinations.
  static String generateDescription({
    required PersonProfile profile,
    required PersonRelationshipIntelligence intelligence,
    required RelationshipActionType type,
  }) {
    final name = profile.name.isNotEmpty ? profile.name : 'this contact';
    final signals = intelligence.signals;

    switch (type) {
      case RelationshipActionType.reconnect:
        final days = signals.daysSinceLastInteraction ?? 0;
        final count = signals.interactionCount;
        if (count > 0 && days > 0) {
          return 'Your last interaction was $days days ago. You have $count recorded interactions together.';
        }
        return 'It has been $days days since your last recorded interaction with $name.';

      case RelationshipActionType.completeOverdueFollowUp:
        final count = signals.overdueFollowUpCount;
        if (count == 1) {
          return 'You have 1 overdue commitment with $name that needs completion.';
        }
        return 'You have $count overdue commitments with $name requiring attention.';

      case RelationshipActionType.followUp:
        if (signals.hasActiveFollowUp) {
          return 'You have ${signals.activeFollowUpCount} active follow-up scheduled with $name.';
        }
        return 'Schedule a check-in to maintain your active momentum with $name.';

      case RelationshipActionType.reviewRelationship:
        return '$name is a strong connection with ${signals.interactionCount} interactions and a relationship strength score of ${intelligence.strength.score.toInt()}/100.';

      case RelationshipActionType.reviewRecentInteraction:
        final days = signals.daysSinceLastInteraction ?? 0;
        if (days == 0) {
          return 'You interacted with $name today. Review key takeaways and next steps.';
        }
        return 'You interacted with $name $days days ago. Ensure all action items are captured.';

      case RelationshipActionType.captureMissingContext:
        return 'You have ${signals.interactionCount} recorded interactions with $name, but limited saved memories or notes.';
    }
  }

  /// Formulates strict evidence-based reason.
  static String generateReason({
    required PersonProfile profile,
    required PersonRelationshipIntelligence intelligence,
    required RelationshipActionType type,
  }) {
    final signals = intelligence.signals;
    final state = intelligence.state;

    switch (type) {
      case RelationshipActionType.reconnect:
        final days = signals.daysSinceLastInteraction ?? 0;
        final count = signals.interactionCount;
        return 'Relationship state is ${state.displayName} (${days}d since last contact, $count previous interactions).';

      case RelationshipActionType.completeOverdueFollowUp:
        return '${signals.overdueFollowUpCount} follow-up past due date.';

      case RelationshipActionType.followUp:
        return 'Active connection with ${signals.interactionCount} interactions.';

      case RelationshipActionType.reviewRelationship:
        return 'High-strength connection (${intelligence.strength.score.toInt()}/100 score).';

      case RelationshipActionType.reviewRecentInteraction:
        return 'Recent interaction recorded within trailing 48 hours.';

      case RelationshipActionType.captureMissingContext:
        return '${signals.interactionCount} encounters with 0 context memories stored.';
    }
  }

  /// Formulates recommended timing based on action type, priority, and signals.
  static String calculateRecommendedTiming({
    required RelationshipActionType type,
    required RelationshipActionPriority priority,
    required PersonRelationshipIntelligence intelligence,
  }) {
    if (priority == RelationshipActionPriority.urgent) {
      return 'Today';
    }
    if (type == RelationshipActionType.completeOverdueFollowUp) {
      return 'Today';
    }
    if (type == RelationshipActionType.reviewRecentInteraction) {
      return 'Today';
    }
    if (priority == RelationshipActionPriority.high) {
      return 'Within 2–3 days';
    }
    if (type == RelationshipActionType.reconnect) {
      return 'Within this week';
    }
    if (priority == RelationshipActionPriority.medium) {
      return 'This week';
    }
    return 'Soon';
  }
}
