import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/relationship_signals.dart';
import '../../features/relationship_intelligence/models/relationship_state.dart';
import '../../features/relationship_intelligence/models/relationship_strength.dart';

/// Abstract contract for deterministic relationship state classification.
abstract class RelationshipStateClassifier {
  RelationshipState classify({
    required RelationshipSignals signals,
    required RelationshipStrength strength,
  });
}

/// Production implementation of precedence-ordered relationship state classifier.
@immutable
class DeterministicRelationshipStateClassifier implements RelationshipStateClassifier {
  const DeterministicRelationshipStateClassifier();

  @override
  RelationshipState classify({
    required RelationshipSignals signals,
    required RelationshipStrength strength,
  }) {
    final days = signals.daysSinceLastInteraction;
    final count = signals.interactionCount;
    final memCount = signals.memoryCount;
    final ageDays = signals.relationshipAgeDays;
    final score = strength.score;

    // Rule 1: DORMANT (Precedence 1)
    // Relationship exists in history, but has had zero interactions for > 180 days
    if ((ageDays > 180 || count > 0) && (days == null || days > 180)) {
      return RelationshipState.dormant;
    }

    // Rule 2: NEGLECTED (Precedence 2)
    // Meaningful past connection (>= 3 interactions or >= 2 memories),
    // but no interactions for > 60 days, or has overdue follow-ups
    if ((count >= 3 || memCount >= 2) &&
        ((days != null && days > 60) || signals.hasOverdueFollowUp)) {
      return RelationshipState.neglected;
    }

    // Rule 3: COOLING (Precedence 3)
    // Previously active (>= 2 interactions), but interaction recency is dropping (31â€“60 days)
    if (count >= 2 && days != null && days >= 31 && days <= 60) {
      return RelationshipState.cooling;
    }

    // Rule 4: STRONG (Precedence 4)
    // High relationship strength (>= 70.0), >= 4 interactions, and recent interaction (<= 30 days)
    if (score >= 70.0 && count >= 4 && signals.hasRecentInteraction) {
      return RelationshipState.strong;
    }

    // Rule 5: ACTIVE (Precedence 5)
    // Recent interaction (<= 30 days) and at least 1 interaction
    if (signals.hasRecentInteraction && count >= 1) {
      return RelationshipState.active;
    }

    // Rule 6: NEW (Precedence 6)
    // Default fallback for new contacts or limited historical record
    return RelationshipState.newRelationship;
  }
}