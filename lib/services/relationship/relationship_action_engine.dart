import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/relationship_intelligence/models/models.dart';
import 'relationship_action_explanation.dart';
import 'relationship_action_priority_calculator.dart';

/// Abstract engine contract for evaluating and generating proactive relationship actions.
abstract class RelationshipActionEngine {
  /// Evaluates all eligible proactive actions for a given person profile and intelligence.
  List<RelationshipAction> evaluateActions(
    PersonProfile profile,
    PersonRelationshipIntelligence intelligence, {
    DateTime? referenceDate,
  });

  /// Evaluates and returns the single highest-priority proactive action, or null if none eligible.
  RelationshipAction? getPrimaryAction(
    PersonProfile profile,
    PersonRelationshipIntelligence intelligence, {
    DateTime? referenceDate,
  });
}

/// Production deterministic implementation of RelationshipActionEngine.
class DeterministicRelationshipActionEngine implements RelationshipActionEngine {
  final RelationshipActionPriorityCalculator priorityCalculator;

  const DeterministicRelationshipActionEngine({
    this.priorityCalculator = const DeterministicRelationshipActionPriorityCalculator(),
  });

  @override
  List<RelationshipAction> evaluateActions(
    PersonProfile profile,
    PersonRelationshipIntelligence intelligence, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final signals = intelligence.signals;
    final state = intelligence.state;
    final actions = <RelationshipAction>[];

    // RULE 1: Overdue Follow-ups -> completeOverdueFollowUp
    if (signals.hasOverdueFollowUp) {
      final triggerKey = 'overdue_${signals.overdueFollowUpCount}';
      final dedupKey = 'action_${profile.id}_${RelationshipActionType.completeOverdueFollowUp.name}_$triggerKey';
      final priority = priorityCalculator.calculate(
        intelligence: intelligence,
        type: RelationshipActionType.completeOverdueFollowUp,
      );
      final timing = RelationshipActionExplanation.calculateRecommendedTiming(
        type: RelationshipActionType.completeOverdueFollowUp,
        priority: priority,
        intelligence: intelligence,
      );

      actions.add(
        RelationshipAction(
          id: dedupKey,
          personId: profile.id,
          personName: profile.name,
          type: RelationshipActionType.completeOverdueFollowUp,
          priority: priority,
          status: RelationshipActionStatus.suggested,
          title: RelationshipActionExplanation.generateTitle(
            profile: profile,
            type: RelationshipActionType.completeOverdueFollowUp,
          ),
          description: RelationshipActionExplanation.generateDescription(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.completeOverdueFollowUp,
          ),
          reason: RelationshipActionExplanation.generateReason(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.completeOverdueFollowUp,
          ),
          recommendedAt: timing,
          targetRoute: '/person/${profile.id}',
          sourceSignals: signals,
          relationshipState: state,
          relationshipScore: intelligence.strength.score,
          deduplicationKey: dedupKey,
          generatedAt: now,
        ),
      );
    }

    // RULE 2: Cooling or Neglected Relationship with historical depth -> reconnect
    // (Only recommend when there is meaningful historical context, e.g. interactionCount >= 2 or >= 1 with memories)
    final hasHistory = signals.interactionCount >= 2 || (signals.interactionCount >= 1 && signals.memoryCount >= 1);
    if ((state == RelationshipState.cooling || state == RelationshipState.neglected) && hasHistory) {
      final days = signals.daysSinceLastInteraction ?? 0;
      final triggerKey = '${state.name}_${days}_${signals.interactionCount}';
      final dedupKey = 'action_${profile.id}_${RelationshipActionType.reconnect.name}_$triggerKey';
      final priority = priorityCalculator.calculate(
        intelligence: intelligence,
        type: RelationshipActionType.reconnect,
      );
      final timing = RelationshipActionExplanation.calculateRecommendedTiming(
        type: RelationshipActionType.reconnect,
        priority: priority,
        intelligence: intelligence,
      );

      actions.add(
        RelationshipAction(
          id: dedupKey,
          personId: profile.id,
          personName: profile.name,
          type: RelationshipActionType.reconnect,
          priority: priority,
          status: RelationshipActionStatus.suggested,
          title: RelationshipActionExplanation.generateTitle(
            profile: profile,
            type: RelationshipActionType.reconnect,
          ),
          description: RelationshipActionExplanation.generateDescription(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.reconnect,
          ),
          reason: RelationshipActionExplanation.generateReason(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.reconnect,
          ),
          recommendedAt: timing,
          targetRoute: '/person/${profile.id}',
          sourceSignals: signals,
          relationshipState: state,
          relationshipScore: intelligence.strength.score,
          deduplicationKey: dedupKey,
          generatedAt: now,
        ),
      );
    }

    // RULE 3: Recent Interaction within trailing 48h -> reviewRecentInteraction
    if (signals.daysSinceLastInteraction != null && signals.daysSinceLastInteraction! <= 2 && signals.interactionCount >= 1) {
      final triggerKey = 'recent_${signals.daysSinceLastInteraction}';
      final dedupKey = 'action_${profile.id}_${RelationshipActionType.reviewRecentInteraction.name}_$triggerKey';
      final priority = priorityCalculator.calculate(
        intelligence: intelligence,
        type: RelationshipActionType.reviewRecentInteraction,
      );
      final timing = RelationshipActionExplanation.calculateRecommendedTiming(
        type: RelationshipActionType.reviewRecentInteraction,
        priority: priority,
        intelligence: intelligence,
      );

      actions.add(
        RelationshipAction(
          id: dedupKey,
          personId: profile.id,
          personName: profile.name,
          type: RelationshipActionType.reviewRecentInteraction,
          priority: priority,
          status: RelationshipActionStatus.suggested,
          title: RelationshipActionExplanation.generateTitle(
            profile: profile,
            type: RelationshipActionType.reviewRecentInteraction,
          ),
          description: RelationshipActionExplanation.generateDescription(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.reviewRecentInteraction,
          ),
          reason: RelationshipActionExplanation.generateReason(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.reviewRecentInteraction,
          ),
          recommendedAt: timing,
          targetRoute: '/person/${profile.id}',
          sourceSignals: signals,
          relationshipState: state,
          relationshipScore: intelligence.strength.score,
          deduplicationKey: dedupKey,
          generatedAt: now,
        ),
      );
    }

    // RULE 4: Meaningful interactions but completely sparse context -> captureMissingContext
    final totalMem = signals.memoryCount + signals.captureCount;
    if (signals.interactionCount >= 3 && totalMem == 0 && state != RelationshipState.newRelationship) {
      final triggerKey = 'sparse_mem_${signals.interactionCount}';
      final dedupKey = 'action_${profile.id}_${RelationshipActionType.captureMissingContext.name}_$triggerKey';
      final priority = priorityCalculator.calculate(
        intelligence: intelligence,
        type: RelationshipActionType.captureMissingContext,
      );
      final timing = RelationshipActionExplanation.calculateRecommendedTiming(
        type: RelationshipActionType.captureMissingContext,
        priority: priority,
        intelligence: intelligence,
      );

      actions.add(
        RelationshipAction(
          id: dedupKey,
          personId: profile.id,
          personName: profile.name,
          type: RelationshipActionType.captureMissingContext,
          priority: priority,
          status: RelationshipActionStatus.suggested,
          title: RelationshipActionExplanation.generateTitle(
            profile: profile,
            type: RelationshipActionType.captureMissingContext,
          ),
          description: RelationshipActionExplanation.generateDescription(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.captureMissingContext,
          ),
          reason: RelationshipActionExplanation.generateReason(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.captureMissingContext,
          ),
          recommendedAt: timing,
          targetRoute: '/person/${profile.id}',
          sourceSignals: signals,
          relationshipState: state,
          relationshipScore: intelligence.strength.score,
          deduplicationKey: dedupKey,
          generatedAt: now,
        ),
      );
    }

    // RULE 5: Strong relationship with no contact in 15-30 days -> reviewRelationship
    if (state == RelationshipState.strong &&
        signals.daysSinceLastInteraction != null &&
        signals.daysSinceLastInteraction! >= 15 &&
        signals.daysSinceLastInteraction! <= 30 &&
        !signals.hasActiveFollowUp &&
        !signals.hasOverdueFollowUp) {
      final triggerKey = 'strong_review_${signals.daysSinceLastInteraction}';
      final dedupKey = 'action_${profile.id}_${RelationshipActionType.reviewRelationship.name}_$triggerKey';
      final priority = priorityCalculator.calculate(
        intelligence: intelligence,
        type: RelationshipActionType.reviewRelationship,
      );
      final timing = RelationshipActionExplanation.calculateRecommendedTiming(
        type: RelationshipActionType.reviewRelationship,
        priority: priority,
        intelligence: intelligence,
      );

      actions.add(
        RelationshipAction(
          id: dedupKey,
          personId: profile.id,
          personName: profile.name,
          type: RelationshipActionType.reviewRelationship,
          priority: priority,
          status: RelationshipActionStatus.suggested,
          title: RelationshipActionExplanation.generateTitle(
            profile: profile,
            type: RelationshipActionType.reviewRelationship,
          ),
          description: RelationshipActionExplanation.generateDescription(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.reviewRelationship,
          ),
          reason: RelationshipActionExplanation.generateReason(
            profile: profile,
            intelligence: intelligence,
            type: RelationshipActionType.reviewRelationship,
          ),
          recommendedAt: timing,
          targetRoute: '/person/${profile.id}',
          sourceSignals: signals,
          relationshipState: state,
          relationshipScore: intelligence.strength.score,
          deduplicationKey: dedupKey,
          generatedAt: now,
        ),
      );
    }

    // Sort actions by priority rank (highest first), then score
    actions.sort((a, b) {
      final pComp = b.priority.rank.compareTo(a.priority.rank);
      if (pComp != 0) return pComp;
      return b.relationshipScore.compareTo(a.relationshipScore);
    });

    return actions;
  }

  @override
  RelationshipAction? getPrimaryAction(
    PersonProfile profile,
    PersonRelationshipIntelligence intelligence, {
    DateTime? referenceDate,
  }) {
    final actions = evaluateActions(profile, intelligence, referenceDate: referenceDate);
    if (actions.isEmpty) return null;
    return actions.first;
  }
}
