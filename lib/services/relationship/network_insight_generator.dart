import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/models.dart';

/// Contract for deterministic generation of grounded network insights.
abstract class NetworkInsightGenerator {
  List<NetworkInsight> generate({
    required NetworkHealth health,
    required List<PersonRelationshipIntelligence> intelligenceList,
    required List<RelationshipAttention> attentionList,
    Map<String, String> nameMap = const {},
  });
}

/// Production implementation of deterministic network insight generator.
@immutable
class DeterministicNetworkInsightGenerator implements NetworkInsightGenerator {
  final int maxInsights;

  const DeterministicNetworkInsightGenerator({this.maxInsights = 5});

  @override
  List<NetworkInsight> generate({
    required NetworkHealth health,
    required List<PersonRelationshipIntelligence> intelligenceList,
    required List<RelationshipAttention> attentionList,
    Map<String, String> nameMap = const {},
  }) {
    if (health.totalPeople == 0) {
      return const [];
    }

    final candidateInsights = <NetworkInsight>[];

    // 1. Critical Overdue Commitments Insight
    if (health.overdueFollowUps > 0) {
      final overduePeople = intelligenceList
          .where((i) => i.signals.hasOverdueFollowUp)
          .map((i) => i.personId)
          .toList();

      candidateInsights.add(NetworkInsight(
        id: 'insight_overdue_follow_ups',
        type: NetworkInsightType.followUpRisk,
        title: '${health.overdueFollowUps} Overdue Commitment${health.overdueFollowUps == 1 ? '' : 's'}',
        description: overduePeople.length == 1
            ? 'You have an overdue follow-up with ${nameMap[overduePeople.first] ?? "a contact"}.'
            : 'You have ${health.overdueFollowUps} overdue follow-ups across ${overduePeople.length} contacts.',
        severity: NetworkInsightSeverity.critical,
        metric: 'Overdue Commitments',
        value: health.overdueFollowUps.toDouble(),
        supportingPersonIds: overduePeople,
      ));
    }

    // 2. High Attention Relationships Insight
    final highPriorityAttention = attentionList
        .where((a) =>
            a.priority == RelationshipAttentionPriority.critical ||
            a.priority == RelationshipAttentionPriority.high)
        .toList();

    if (highPriorityAttention.isNotEmpty) {
      candidateInsights.add(NetworkInsight(
        id: 'insight_attention_required',
        type: NetworkInsightType.attention,
        title: '${highPriorityAttention.length} High-Priority Attention${highPriorityAttention.length == 1 ? '' : 's'}',
        description: highPriorityAttention.length == 1
            ? '${highPriorityAttention.first.personName} requires proactive outreach.'
            : '${highPriorityAttention.length} contacts currently require prioritized relationship attention.',
        severity: highPriorityAttention.any((a) => a.priority == RelationshipAttentionPriority.critical)
            ? NetworkInsightSeverity.critical
            : NetworkInsightSeverity.high,
        metric: 'Priority Attention',
        value: highPriorityAttention.length.toDouble(),
        supportingPersonIds: highPriorityAttention.map((a) => a.personId).toList(),
      ));
    }

    // 3. Cooling Relationships Insight
    if (health.coolingRelationships > 0) {
      final coolingPeople = intelligenceList
          .where((i) => i.state == RelationshipState.cooling)
          .toList();

      final richHistoryCooling = coolingPeople
          .where((i) => i.signals.interactionCount >= 3)
          .length;

      final desc = richHistoryCooling > 0
          ? '${health.coolingRelationships} relationships are cooling, including $richHistoryCooling with meaningful interaction history.'
          : '${health.coolingRelationships} relationships have had no contact for 31–60 days.';

      candidateInsights.add(NetworkInsight(
        id: 'insight_cooling_relationships',
        type: NetworkInsightType.relationshipDecline,
        title: '${health.coolingRelationships} Relationship${health.coolingRelationships == 1 ? '' : 's'} Cooling',
        description: desc,
        severity: NetworkInsightSeverity.high,
        metric: 'Cooling Relationships',
        value: health.coolingRelationships.toDouble(),
        supportingPersonIds: coolingPeople.map((i) => i.personId).toList(),
      ));
    }

    // 4. Neglected Connections Insight
    if (health.neglectedRelationships > 0) {
      final neglectedPeople = intelligenceList
          .where((i) => i.state == RelationshipState.neglected)
          .toList();

      candidateInsights.add(NetworkInsight(
        id: 'insight_neglected_relationships',
        type: NetworkInsightType.relationshipDecline,
        title: '${health.neglectedRelationships} Neglected Connection${health.neglectedRelationships == 1 ? '' : 's'}',
        description: '${health.neglectedRelationships} established connections have had no contact for over 60 days.',
        severity: NetworkInsightSeverity.medium,
        metric: 'Neglected Connections',
        value: health.neglectedRelationships.toDouble(),
        supportingPersonIds: neglectedPeople.map((i) => i.personId).toList(),
      ));
    }

    // 5. Strong & Active Core Insight
    final strongAndActive = health.strongRelationships + health.activeRelationships;
    if (strongAndActive > 0) {
      final pct = ((strongAndActive / health.totalPeople) * 100.0).toInt();
      candidateInsights.add(NetworkInsight(
        id: 'insight_active_core',
        type: NetworkInsightType.relationshipHealth,
        title: '$pct% Active Core Network',
        description: '$strongAndActive of ${health.totalPeople} contacts are actively engaged (${health.strongRelationships} strong, ${health.activeRelationships} active).',
        severity: NetworkInsightSeverity.info,
        metric: 'Active Core Ratio',
        value: strongAndActive.toDouble(),
        supportingPersonIds: intelligenceList
            .where((i) => i.state == RelationshipState.strong || i.state == RelationshipState.active)
            .map((i) => i.personId)
            .toList(),
      ));
    }

    // 6. Interaction Momentum Insight
    if (health.recentInteractionCount > 0) {
      candidateInsights.add(NetworkInsight(
        id: 'insight_recent_momentum',
        type: NetworkInsightType.interactionMomentum,
        title: '${health.recentInteractionCount} Recent Connection${health.recentInteractionCount == 1 ? '' : 's'}',
        description: 'You engaged with ${health.recentInteractionCount} contacts in the past 30 days across ${health.interactionCount} total interactions.',
        severity: NetworkInsightSeverity.info,
        metric: 'Recent Touchpoints',
        value: health.recentInteractionCount.toDouble(),
        supportingPersonIds: intelligenceList
            .where((i) => i.signals.hasRecentInteraction)
            .map((i) => i.personId)
            .toList(),
      ));
    }

    // 7. Context Coverage Insight
    if (health.relationshipCoverage < 0.50 && health.totalPeople >= 3) {
      final coveragePct = (health.relationshipCoverage * 100.0).toInt();
      candidateInsights.add(NetworkInsight(
        id: 'insight_context_coverage_gap',
        type: NetworkInsightType.networkCoverage,
        title: 'Context Coverage at $coveragePct%',
        description: 'More than half of your contacts lack captured encounter notes or memory details.',
        severity: NetworkInsightSeverity.medium,
        metric: 'Context Coverage',
        value: health.relationshipCoverage,
      ));
    }

    // 8. Deterministic Ordering: Severity DESC -> Value DESC -> ID ASC
    candidateInsights.sort((a, b) {
      final prioCmp = b.severity.rank.compareTo(a.severity.rank);
      if (prioCmp != 0) return prioCmp;

      final valCmp = b.value.compareTo(a.value);
      if (valCmp != 0) return valCmp;

      return a.id.compareTo(b.id);
    });

    return candidateInsights.take(maxInsights).toList();
  }
}
