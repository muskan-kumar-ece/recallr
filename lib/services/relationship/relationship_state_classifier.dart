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
///
/// Priority Order (evaluated top-to-bottom):
/// 1. NEW      — count <=2 OR ageDays <7 (score capped at 30 by strength calculator)
/// 2. DORMANT  — daysSinceLast >180 AND ageDays >180 (requires real parsed date)
/// 3. NEGLECTED— count >=3 AND (daysSinceLast >60 OR hasOverdueFollowUp)
/// 4. COOLING  — count >=2 AND daysSinceLast 31–60
/// 5. STRONG   — score >=70 AND count >=4 AND daysSinceLast <=30
/// 6. ACTIVE   — daysSinceLast <=30 AND count >=1
/// 7. QUIET    — Fallback (unparseable date on established contact, or unmatched)
///
/// KEY INVARIANTS:
/// - When daysSinceLast is null (unparseable date + no lastInteractionAt):
///   contact is NEVER DORMANT, NEGLECTED, COOLING, STRONG, or ACTIVE.
///   Falls to QUIET, not DORMANT.
/// - NEW always takes precedence over everything else when count <=2 or ageDays <7.
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
    final ageDays = signals.relationshipAgeDays;
    final score = strength.score;

    // Rule 1: NEW (Precedence 1) — always evaluated first.
    // A contact is NEW when it has <=2 interactions OR the relationship
    // was created within the last 7 days. Score is capped at 30 by the
    // strength calculator for these contacts.
    if (count <= 2 || (ageDays > 0 && ageDays < 7) || count == 0) {
      return RelationshipState.newRelationship;
    }

    // Rules 2-6 require daysSinceLast to be non-null.
    // If null (unparseable date + no lastInteractionAt), fall to QUIET — never DORMANT.
    if (days == null) {
      return RelationshipState.quiet;
    }

    // Rule 2: DORMANT (Precedence 2)
    // Long-standing silence: >180 days AND relationship itself >180 days old.
    if (days > 180 && ageDays > 180) {
      return RelationshipState.dormant;
    }

    // Rule 3: NEGLECTED (Precedence 3)
    // Established relationship (>=3 interactions) but lapsed or has overdue commitments.
    if (count >= 3 && (days > 60 || signals.hasOverdueFollowUp)) {
      return RelationshipState.neglected;
    }

    // Rule 4: COOLING (Precedence 4)
    // Established relationship (>=2 interactions) with declining recency (31-60 days).
    if (count >= 2 && days >= 31 && days <= 60) {
      return RelationshipState.cooling;
    }

    // Rule 5: STRONG (Precedence 5)
    // High-strength, high-frequency, recent relationship.
    if (score >= 70.0 && count >= 4 && days <= 30) {
      return RelationshipState.strong;
    }

    // Rule 6: ACTIVE (Precedence 6)
    // Recent interaction within last 30 days with at least 1 interaction.
    if (days <= 30 && count >= 1) {
      return RelationshipState.active;
    }

    // Rule 7: QUIET (Fallback)
    // Any unmatched state: 1-2 interactions with silence, etc.
    return RelationshipState.quiet;
  }
}
