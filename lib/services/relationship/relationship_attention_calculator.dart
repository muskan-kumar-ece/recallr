import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/relationship_signals.dart';
import '../../features/relationship_intelligence/models/relationship_state.dart';
import '../../features/relationship_intelligence/models/relationship_strength.dart';

/// Abstract contract for deterministic relationship attention score calculation.
abstract class RelationshipAttentionCalculator {
  double calculate({
    required RelationshipSignals signals,
    required RelationshipStrength strength,
    required RelationshipState state,
  });
}

/// Production implementation of transparent weighted attention score calculator.
/// Note: Relationship Strength != Relationship Attention Score.
/// Attention Score measures urgency and risk of connection decay, not relationship quality.
@immutable
class DeterministicRelationshipAttentionCalculator implements RelationshipAttentionCalculator {
  const DeterministicRelationshipAttentionCalculator();

  @override
  double calculate({
    required RelationshipSignals signals,
    required RelationshipStrength strength,
    required RelationshipState state,
  }) {
    // 1. Urgency / Commitment Risk (30% weight)
    final double urgencyRisk;
    if (signals.overdueFollowUpCount >= 3) {
      urgencyRisk = 1.00;
    } else if (signals.overdueFollowUpCount == 2) {
      urgencyRisk = 0.85;
    } else if (signals.overdueFollowUpCount == 1) {
      urgencyRisk = 0.70;
    } else if (signals.activeFollowUpCount > 0) {
      urgencyRisk = 0.35;
    } else {
      urgencyRisk = 0.00;
    }

    // 2. Relationship Risk / State Decay (25% weight)
    final double relRisk;
    switch (state) {
      case RelationshipState.neglected:
        relRisk = 1.00;
        break;
      case RelationshipState.cooling:
        relRisk = 0.80;
        break;
      case RelationshipState.dormant:
        relRisk = 0.65;
        break;
      case RelationshipState.active:
        relRisk = 0.25;
        break;
      case RelationshipState.strong:
        relRisk = 0.10;
        break;
      case RelationshipState.newRelationship:
        relRisk = 0.05;
        break;
    }

    // 3. Recency Risk (20% weight)
    final days = signals.daysSinceLastInteraction;
    final double recencyRisk;
    if (days == null) {
      recencyRisk = 0.65;
    } else if (days <= 7) {
      recencyRisk = 0.05;
    } else if (days <= 30) {
      recencyRisk = 0.20;
    } else if (days <= 60) {
      recencyRisk = 0.55;
    } else if (days <= 90) {
      recencyRisk = 0.75;
    } else if (days <= 180) {
      recencyRisk = 0.90;
    } else {
      recencyRisk = 1.00;
    }

    // 4. Relationship Strength (15% weight)
    final double strengthNorm = (strength.score / 100.0).clamp(0.0, 1.0);

    // 5. Context Richness (10% weight)
    final double totalContext = (signals.interactionCount +
        signals.memoryCount +
        signals.captureCount +
        signals.recentActivityCount).toDouble();
    final double contextNorm = (totalContext / 10.0).clamp(0.0, 1.0);

    // Weighted sum (0.0 .. 1.0) -> (0.0 .. 100.0)
    final rawScore = (urgencyRisk * 0.30 +
            relRisk * 0.25 +
            recencyRisk * 0.20 +
            strengthNorm * 0.15 +
            contextNorm * 0.10) *
        100.0;

    if (rawScore.isNaN || rawScore.isInfinite) {
      return 0.0;
    }

    return rawScore.clamp(0.0, 100.0);
  }
}
