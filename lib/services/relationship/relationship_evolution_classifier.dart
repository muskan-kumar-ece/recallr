import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Contract for deterministic classification of relationship evolution and momentum.
abstract class RelationshipEvolutionClassifier {
  RelationshipMomentum classify({
    required String personId,
    required RelationshipSignals signals,
    required RelationshipState state,
    required RelationshipStrength strength,
    required RelationshipVelocity velocity,
    required CadenceAnalysis cadence,
    int overdueFollowUps = 0,
    DateTime? contactCreatedDate,
    DateTime? referenceDate,
  });
}

/// Production implementation of deterministic evolution classifier.
@immutable
class DeterministicRelationshipEvolutionClassifier implements RelationshipEvolutionClassifier {
  const DeterministicRelationshipEvolutionClassifier();

  @override
  RelationshipMomentum classify({
    required String personId,
    required RelationshipSignals signals,
    required RelationshipState state,
    required RelationshipStrength strength,
    required RelationshipVelocity velocity,
    required CadenceAnalysis cadence,
    int overdueFollowUps = 0,
    DateTime? contactCreatedDate,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final factors = <String>[];

    // RULE 1: Insufficient History Guard
    // When fewer than 2 distinct encounters are recorded, cadence and trajectory cannot be established.
    if (velocity.historicalCount < 2 || !velocity.hasSufficientData && cadence.totalDistinctDates < 2) {
      return RelationshipMomentum.insufficientHistory(
        personId: personId,
        velocity: velocity,
        cadence: cadence,
        referenceDate: now,
      );
    }

    // RULE 2: Newly Developing
    // Brand new contact with high initial velocity (>= 2 encounters) within 60 days of creation and no prior baseline
    final isNewContact = contactCreatedDate != null && now.difference(contactCreatedDate).inDays <= 60;
    if ((isNewContact || state == RelationshipState.newRelationship) && velocity.recentCount >= 2 && velocity.previousCount == 0 && velocity.priorCount == 0) {
      factors.add('${velocity.recentCount} encounters recorded in initial 30-day window');
      if (cadence.hasSufficientCadence) {
        factors.add('Early cadence established at every ${cadence.averageCadenceDays!.toInt()} days');
      }

      return RelationshipMomentum(
        personId: personId,
        direction: MomentumDirection.newlyDeveloping,
        momentumScore: 75.0,
        velocity: velocity,
        cadence: cadence,
        headline: 'Newly Developing: ${velocity.recentCount} interactions recorded since connection.',
        explanation: 'Active initial engagement with ${velocity.recentCount} interactions in the last 30 days.',
        keyEvolutionFactors: factors,
        generatedAt: now,
      );
    }

    // RULE 3: Recovering
    // Reconnected within the last 30 days after a prior period of silence (previousCount == 0 && priorCount == 0 && total >= 3)
    // or relationship state was cooling/neglected and has fresh contact
    final wasInactive = (velocity.previousCount == 0 && velocity.priorCount == 0 && velocity.historicalCount >= 3) ||
        (state == RelationshipState.cooling && signals.hasRecentInteraction);

    if (velocity.recentCount >= 1 && wasInactive) {
      factors.add('Re-engaged with ${velocity.recentCount} recent encounter${velocity.recentCount == 1 ? '' : 's'} after hiatus');
      if (cadence.daysSinceLastInteraction != null) {
        factors.add('Latest contact was ${cadence.daysSinceLastInteraction} days ago');
      }

      final score = (70.0 + (velocity.recentCount * 5.0)).clamp(0.0, 85.0);

      return RelationshipMomentum(
        personId: personId,
        direction: MomentumDirection.recovering,
        momentumScore: score,
        velocity: velocity,
        cadence: cadence,
        headline: 'Recovering: Reconnected recently with ${velocity.recentCount} touchpoint${velocity.recentCount == 1 ? '' : 's'}.',
        explanation: 'Relationship is regaining momentum after a period of dormancy.',
        keyEvolutionFactors: factors,
        generatedAt: now,
      );
    }

    // RULE 4: Strengthening
    // Positive velocity delta (>= 1) with at least 2 recent encounters and on-pace cadence
    if (velocity.velocityDelta >= 1.0 && velocity.recentCount >= 2 && (!cadence.isOffCadence)) {
      final pctText = velocity.percentageChange != null ? ' (+${velocity.percentageChange!.toInt()}%)' : '';
      factors.add('${velocity.recentCount} interactions in trailing 30 days vs ${velocity.previousCount} in prior 30 days$pctText');
      if (cadence.hasSufficientCadence) {
        factors.add('Rhythm is on-pace at every ${cadence.averageCadenceDays!.toInt()} days');
      }

      final score = (80.0 + (velocity.velocityDelta * 5.0)).clamp(0.0, 100.0);

      return RelationshipMomentum(
        personId: personId,
        direction: MomentumDirection.strengthening,
        momentumScore: score,
        velocity: velocity,
        cadence: cadence,
        headline: 'Strengthening: ${velocity.recentCount} interactions in the last 30 days (up from ${velocity.previousCount}).',
        explanation: 'Increasing interaction frequency and sustained engagement over the last 30 days.',
        keyEvolutionFactors: factors,
        generatedAt: now,
      );
    }

    // RULE 5: Declining
    // Critical off-cadence (>= 2.5x), > 60 days without contact, neglected state, or multiple overdue commitments
    final isCriticallyStale = cadence.isCriticallyOffCadence ||
        (signals.daysSinceLastInteraction != null && signals.daysSinceLastInteraction! > 60 && velocity.recentCount == 0);
    final hasHighRisk = state == RelationshipState.neglected || state == RelationshipState.dormant || overdueFollowUps >= 2;

    if (isCriticallyStale || hasHighRisk) {
      if (signals.daysSinceLastInteraction != null) {
        factors.add('${signals.daysSinceLastInteraction} days since last recorded encounter');
      }
      if (cadence.cadenceRatio != null) {
        factors.add('Current silence is ${cadence.cadenceRatio!.toStringAsFixed(1)}x your historical average interval');
      }
      if (overdueFollowUps > 0) {
        factors.add('$overdueFollowUps overdue follow-up commitment${overdueFollowUps == 1 ? '' : 's'}');
      }

      final score = (30.0 - (overdueFollowUps * 5.0)).clamp(0.0, 45.0);
      final daysText = signals.daysSinceLastInteraction != null ? '${signals.daysSinceLastInteraction} days' : 'extended period';

      return RelationshipMomentum(
        personId: personId,
        direction: MomentumDirection.declining,
        momentumScore: score,
        velocity: velocity,
        cadence: cadence,
        headline: 'Declining: No contact for $daysText with relationship at risk.',
        explanation: 'Contact frequency has severely decayed relative to historical relationship baseline.',
        keyEvolutionFactors: factors,
        generatedAt: now,
      );
    }

    // RULE 6: Cooling
    // Off-cadence (1.5x - 2.5x), 31–60 days of silence, or state == cooling
    final isCoolingCadence = cadence.isOffCadence ||
        (signals.daysSinceLastInteraction != null && signals.daysSinceLastInteraction! >= 31 && signals.daysSinceLastInteraction! <= 60);

    if (isCoolingCadence || state == RelationshipState.cooling || velocity.isDecelerating) {
      if (signals.daysSinceLastInteraction != null) {
        factors.add('${signals.daysSinceLastInteraction} days have passed since last contact');
      }
      if (cadence.averageCadenceDays != null) {
        factors.add('Historical rhythm was every ${cadence.averageCadenceDays!.toInt()} days (${cadence.cadenceRatio?.toStringAsFixed(1) ?? "1.5"}x overdue)');
      }
      if (velocity.velocityDelta < 0) {
        factors.add('Activity dropped from ${velocity.previousCount} to ${velocity.recentCount} in the last 30 days');
      }

      return RelationshipMomentum(
        personId: personId,
        direction: MomentumDirection.cooling,
        momentumScore: 45.0,
        velocity: velocity,
        cadence: cadence,
        headline: 'Cooling: ${signals.daysSinceLastInteraction ?? 35} days since last interaction.',
        explanation: 'Interaction rhythm is slowing down compared to historical baseline.',
        keyEvolutionFactors: factors,
        generatedAt: now,
      );
    }

    // RULE 7: Stable (Default for consistent cadence and activity)
    factors.add('Interaction cadence matches historical baseline');
    if (cadence.hasSufficientCadence) {
      factors.add('Steady pace of every ~${cadence.averageCadenceDays!.toInt()} days');
    }

    return RelationshipMomentum(
      personId: personId,
      direction: MomentumDirection.stable,
      momentumScore: 60.0,
      velocity: velocity,
      cadence: cadence,
      headline: 'Stable: Consistent interaction rhythm matching relationship strength.',
      explanation: 'Healthy, predictable communication rhythm with steady engagement.',
      keyEvolutionFactors: factors,
      generatedAt: now,
    );
  }
}
