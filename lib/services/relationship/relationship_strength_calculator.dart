import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/relationship_signals.dart';
import '../../features/relationship_intelligence/models/relationship_strength.dart';

/// Abstract contract for calculating deterministic relationship strength.
abstract class RelationshipStrengthCalculator {
  RelationshipStrength calculate(RelationshipSignals signals);
}

/// Production implementation of transparent weighted relationship strength calculation.
@immutable
class DeterministicRelationshipStrengthCalculator implements RelationshipStrengthCalculator {
  /// Weights for strength factors (must sum to 1.0).
  final double recencyWeight;
  final double frequencyWeight;
  final double depthWeight;
  final double memoryWeight;
  final double followUpWeight;

  const DeterministicRelationshipStrengthCalculator({
    this.recencyWeight = 0.30,
    this.frequencyWeight = 0.25,
    this.depthWeight = 0.20,
    this.memoryWeight = 0.15,
    this.followUpWeight = 0.10,
  });

  @override
  RelationshipStrength calculate(RelationshipSignals signals) {
    // If there is zero data across all metrics, return clean zero strength
    if (signals.interactionCount == 0 &&
        signals.memoryCount == 0 &&
        signals.captureCount == 0 &&
        signals.totalFollowUps == 0) {
      return RelationshipStrength.zero(
        reason: 'Not enough interaction history to compute relationship strength.',
      );
    }

    final factors = <StrengthFactor>[
      _calculateRecencyFactor(signals),
      _calculateFrequencyFactor(signals),
      _calculateDepthFactor(signals),
      _calculateMemoryFactor(signals),
      _calculateFollowUpFactor(signals),
    ];

    final rawStrength = RelationshipStrength.fromFactors(factors: factors);

    // Score cap: contacts with <=2 interactions OR relationship age <7 days
    // must be capped at 30 to align with NEW status invariant.
    final isNew = signals.interactionCount <= 2 || (signals.relationshipAgeDays > 0 && signals.relationshipAgeDays < 7);
    if (isNew && rawStrength.score > 30.0) {
      return RelationshipStrength(
        score: 30.0,
        factors: rawStrength.factors,
        level: rawStrength.level,
        summary: rawStrength.summary,
      );
    }

    return rawStrength;
  }

  StrengthFactor _calculateRecencyFactor(RelationshipSignals signals) {
    final days = signals.daysSinceLastInteraction;
    double score;
    String explanation;

    if (days == null) {
      score = 0.0;
      explanation = 'No recorded interaction dates.';
    } else if (days <= 0) {
      score = 1.0;
      explanation = 'Interacted today.';
    } else if (days <= 7) {
      score = 1.0;
      explanation = 'Last interaction was $days day${days == 1 ? '' : 's'} ago.';
    } else if (days <= 30) {
      score = 0.85;
      explanation = 'Last interaction was $days days ago (within the last month).';
    } else if (days <= 90) {
      score = 0.55;
      explanation = 'Last interaction was $days days ago.';
    } else if (days <= 180) {
      score = 0.25;
      explanation = 'Last interaction was $days days ago (over 3 months).';
    } else {
      score = 0.05;
      explanation = 'Last interaction was $days days ago (over 6 months).';
    }

    return StrengthFactor(
      name: 'Recency',
      score: score,
      weight: recencyWeight,
      explanation: explanation,
    );
  }

  StrengthFactor _calculateFrequencyFactor(RelationshipSignals signals) {
    final count = signals.interactionCount;
    final recentCount = signals.recentInteractionCount;
    double score;
    String explanation;

    if (count == 0) {
      score = 0.0;
      explanation = 'No recorded interactions.';
    } else if (recentCount >= 4 || count >= 12) {
      score = 1.0;
      explanation = 'Frequent communication with $count recorded interaction${count == 1 ? '' : 's'}.';
    } else if (recentCount >= 2 || count >= 6) {
      score = 0.80;
      explanation = 'Regular interaction cadence ($count recorded interaction${count == 1 ? '' : 's'}).';
    } else if (recentCount >= 1 || count >= 3) {
      score = 0.55;
      explanation = 'Moderate interaction pace ($count interaction${count == 1 ? '' : 's'}).';
    } else {
      score = 0.25;
      explanation = 'Initial contact ($count recorded interaction).';
    }

    return StrengthFactor(
      name: 'Frequency',
      score: score,
      weight: frequencyWeight,
      explanation: explanation,
    );
  }

  StrengthFactor _calculateDepthFactor(RelationshipSignals signals) {
    final count = signals.interactionCount;
    double score;
    String explanation;

    if (count == 0) {
      score = 0.0;
      explanation = 'No historical encounters recorded.';
    } else if (count >= 10) {
      score = 1.0;
      explanation = 'Extensive relationship depth with $count logged interactions.';
    } else if (count >= 5) {
      score = 0.80;
      explanation = 'Substantial interaction depth ($count logged interactions).';
    } else if (count >= 2) {
      score = 0.50;
      explanation = 'Multiple historical touchpoints ($count interactions).';
    } else {
      score = 0.25;
      explanation = 'Single recorded meeting.';
    }

    return StrengthFactor(
      name: 'Interaction Depth',
      score: score,
      weight: depthWeight,
      explanation: explanation,
    );
  }

  StrengthFactor _calculateMemoryFactor(RelationshipSignals signals) {
    final totalMemories = signals.memoryCount + signals.captureCount;
    double score;
    String explanation;

    if (totalMemories == 0) {
      score = 0.0;
      explanation = 'No structured memory claims or captures stored.';
    } else if (totalMemories >= 6) {
      score = 1.0;
      explanation = 'Rich relationship context with $totalMemories memory points and captures.';
    } else if (totalMemories >= 3) {
      score = 0.75;
      explanation = 'Well-documented context ($totalMemories verified memories).';
    } else {
      score = 0.40;
      explanation = 'Basic context ($totalMemories memory item${totalMemories == 1 ? '' : 's'}).';
    }

    return StrengthFactor(
      name: 'Memory Richness',
      score: score,
      weight: memoryWeight,
      explanation: explanation,
    );
  }

  StrengthFactor _calculateFollowUpFactor(RelationshipSignals signals) {
    final active = signals.activeFollowUpCount;
    final completed = signals.completedFollowUpCount;
    final overdue = signals.overdueFollowUpCount;
    final total = signals.totalFollowUps;
    double score;
    String explanation;

    if (total == 0) {
      score = 0.30;
      explanation = 'No commitments or follow-ups tracked.';
    } else if (overdue > 0) {
      score = 0.20;
      explanation = '$overdue overdue follow-up${overdue == 1 ? '' : 's'} needing attention.';
    } else if (completed >= 2) {
      score = 1.0;
      explanation = '$completed completed commitments with high reliability.';
    } else if (active > 0) {
      score = 0.85;
      explanation = '$active active commitment${active == 1 ? '' : 's'} in progress.';
    } else {
      score = 0.60;
      explanation = '$completed commitment completed.';
    }

    return StrengthFactor(
      name: 'Follow-up Engagement',
      score: score,
      weight: followUpWeight,
      explanation: explanation,
    );
  }
}