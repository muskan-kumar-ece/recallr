import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Contract for deterministic network health calculations.
abstract class NetworkHealthCalculator {
  NetworkHealth calculate({
    required List<PersonRelationshipIntelligence> intelligenceList,
    required List<RelationshipAttention> attentionList,
    int totalFollowUps = 0,
    int completedFollowUps = 0,
    int overdueFollowUps = 0,
    DateTime? referenceDate,
  });
}

/// Production implementation of transparent, weighted network health scoring.
@immutable
class DeterministicNetworkHealthCalculator implements NetworkHealthCalculator {
  final double stateWeight;
  final double recencyWeight;
  final double followUpWeight;
  final double attentionRiskWeight;
  final double coverageWeight;

  const DeterministicNetworkHealthCalculator({
    this.stateWeight = 0.35,
    this.recencyWeight = 0.20,
    this.followUpWeight = 0.15,
    this.attentionRiskWeight = 0.15,
    this.coverageWeight = 0.15,
  });

  @override
  NetworkHealth calculate({
    required List<PersonRelationshipIntelligence> intelligenceList,
    required List<RelationshipAttention> attentionList,
    int totalFollowUps = 0,
    int completedFollowUps = 0,
    int overdueFollowUps = 0,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final totalPeople = intelligenceList.length;

    // 1. Empty Network Safeguard
    if (totalPeople == 0) {
      return NetworkHealth.empty(referenceDate: now);
    }

    // 2. Aggregate Distribution Counts
    int activeCount = 0;
    int strongCount = 0;
    int coolingCount = 0;
    int neglectedCount = 0;
    int dormantCount = 0;
    int newCount = 0;
    int interactionTotal = 0;
    int recentInteractionTotal = 0;
    int contextCount = 0;

    double stateHealthSum = 0.0;

    for (final intel in intelligenceList) {
      final state = intel.state;
      final signals = intel.signals;

      interactionTotal += signals.interactionCount;
      if (signals.hasRecentInteraction) {
        recentInteractionTotal++;
      }
      if (signals.interactionCount > 0 || signals.memoryCount > 0 || signals.captureCount > 0) {
        contextCount++;
      }

      switch (state) {
        case RelationshipState.strong:
          strongCount++;
          stateHealthSum += 1.00;
          break;
        case RelationshipState.active:
          activeCount++;
          stateHealthSum += 0.85;
          break;
        case RelationshipState.newRelationship:
          newCount++;
          stateHealthSum += 0.65;
          break;
        case RelationshipState.cooling:
          coolingCount++;
          stateHealthSum += 0.45;
          break;
        case RelationshipState.neglected:
          neglectedCount++;
          stateHealthSum += 0.25;
          break;
        case RelationshipState.dormant:
          dormantCount++;
          stateHealthSum += 0.10;
          break;
        case RelationshipState.quiet:
          stateHealthSum += 0.35;
          break;
      }
    }

    // 3. Normalized Component Calculations
    // A. Relationship State Health (35%)
    final relStateScore = totalPeople > 0 ? (stateHealthSum / totalPeople) : 0.0;

    // B. Recent Interaction Health (20%)
    final recencyScore = totalPeople > 0 ? (recentInteractionTotal / totalPeople).clamp(0.0, 1.0) : 0.0;

    // C. Follow-up Reliability (15%)
    // Neutral fallback (0.85) when no follow-ups exist to avoid penalizing clean accounts
    final double followUpReliability;
    if (totalFollowUps == 0 && overdueFollowUps == 0) {
      followUpReliability = 0.85;
    } else {
      final safeTotal = math.max(1, completedFollowUps + overdueFollowUps);
      final rawRate = completedFollowUps / safeTotal;
      final overduePenalty = (overdueFollowUps * 0.25).clamp(0.0, 0.75);
      followUpReliability = (rawRate - overduePenalty).clamp(0.0, 1.0);
    }

    // D. Attention Risk (15%)
    // Critical and High attention reduce score more than Medium/Low
    int criticalAtt = 0;
    int highAtt = 0;
    int mediumAtt = 0;
    for (final att in attentionList) {
      if (att.priority == RelationshipAttentionPriority.critical) {
        criticalAtt++;
      } else if (att.priority == RelationshipAttentionPriority.high) {
        highAtt++;
      } else if (att.priority == RelationshipAttentionPriority.medium) {
        mediumAtt++;
      }
    }
    final penalty = (criticalAtt * 0.40 + highAtt * 0.20 + mediumAtt * 0.10) / math.max(1, totalPeople);
    final attentionScore = (1.0 - penalty).clamp(0.0, 1.0);

    // E. Relationship Context Coverage (15%)
    final coverageScore = totalPeople > 0 ? (contextCount / totalPeople).clamp(0.0, 1.0) : 0.0;

    // 4. Final Weighted Mathematical Score
    double rawCalculatedScore = (stateWeight * relStateScore +
            recencyWeight * recencyScore +
            followUpWeight * followUpReliability +
            attentionRiskWeight * attentionScore +
            coverageWeight * coverageScore) *
        100.0;

    // NaN / Infinity Safety
    if (rawCalculatedScore.isNaN || rawCalculatedScore.isInfinite) {
      rawCalculatedScore = 0.0;
    }
    final finalScore = rawCalculatedScore.clamp(0.0, 100.0);

    // 5. Determine Health Level
    final NetworkHealthLevel level;
    if (finalScore >= 85.0) {
      level = NetworkHealthLevel.excellent;
    } else if (finalScore >= 70.0) {
      level = NetworkHealthLevel.healthy;
    } else if (finalScore >= 50.0) {
      level = NetworkHealthLevel.developing;
    } else if (finalScore >= 30.0) {
      level = NetworkHealthLevel.atRisk;
    } else {
      level = NetworkHealthLevel.critical;
    }

    // 6. Small-N Statistical Confidence Tier
    final NetworkConfidence confidence;
    if (totalPeople <= 2) {
      confidence = NetworkConfidence.limited;
    } else if (totalPeople <= 9) {
      confidence = NetworkConfidence.moderate;
    } else {
      confidence = NetworkConfidence.high;
    }

    final followUpRate = totalFollowUps > 0
        ? (completedFollowUps / totalFollowUps).clamp(0.0, 1.0)
        : 1.0;

    return NetworkHealth(
      score: finalScore,
      level: level,
      confidence: confidence,
      totalPeople: totalPeople,
      activeRelationships: activeCount,
      strongRelationships: strongCount,
      coolingRelationships: coolingCount,
      neglectedRelationships: neglectedCount,
      dormantRelationships: dormantCount,
      newRelationships: newCount,
      relationshipsNeedingAttention: attentionList.where((a) => a.needsAttention).length,
      overdueFollowUps: overdueFollowUps,
      interactionCount: interactionTotal,
      recentInteractionCount: recentInteractionTotal,
      followUpCompletionRate: followUpRate,
      relationshipCoverage: coverageScore,
      generatedAt: now,
    );
  }
}
