import 'package:flutter/foundation.dart';
import '../../features/relationship_intelligence/models/network_connection.dart';
import '../../features/relationship_intelligence/models/network_graph.dart';
import '../../features/relationship_intelligence/models/network_pattern.dart';
import '../../features/relationship_intelligence/models/relationship_cluster.dart';
import '../../features/relationship_intelligence/models/relationship_momentum.dart';
import '../../features/relationship_intelligence/models/relationship_state.dart';
import '../../features/relationship_intelligence/models/relationship_strength.dart';

/// Contract for deterministic pattern recognition across the professional network.
abstract class NetworkPatternEngine {
  List<NetworkPattern> detectPatterns({
    required NetworkGraph graph,
    required List<NetworkConnection> connections,
    required List<RelationshipCluster> clusters,
    Map<String, RelationshipStrength> strengths = const {},
    Map<String, double> attentionScores = const {},
    DateTime? referenceDate,
  });
}

/// Production implementation of deterministic network pattern recognition engine.
@immutable
class DeterministicNetworkPatternEngine implements NetworkPatternEngine {
  const DeterministicNetworkPatternEngine();

  @override
  List<NetworkPattern> detectPatterns({
    required NetworkGraph graph,
    required List<NetworkConnection> connections,
    required List<RelationshipCluster> clusters,
    Map<String, RelationshipStrength> strengths = const {},
    Map<String, double> attentionScores = const {},
    DateTime? referenceDate,
  }) {
    if (graph.isEmpty) return const [];

    final List<NetworkPattern> patterns = [];
    final totalContacts = graph.nodeCount;
    final nodeMap = {for (final n in graph.nodes) n.personId: n};

    // 1. Strong Cluster Pattern
    for (final cluster in clusters) {
      if (cluster.isStrong) {
        final patternId = 'pattern_strong_${cluster.id}';
        final impact = _calculateImpactScore(
          volume: cluster.interactionCount,
          peopleCount: cluster.memberCount,
          avgStrength: cluster.averageRelationshipStrength,
          attentionRisk: cluster.averageAttentionScore,
        );

        patterns.add(
          NetworkPattern(
            id: patternId,
            type: NetworkPatternType.strongCluster,
            severity: NetworkPatternSeverity.high,
            title: 'Strong Cluster: ${cluster.name}',
            description:
                '${cluster.memberCount} strongly connected contacts in ${cluster.name} with average strength ${cluster.averageRelationshipStrength.toInt()}/100 and ${cluster.interactionCount} interactions.',
            evidencePersonIds: cluster.personIds,
            evidenceConnectionIds: connections
                .where((c) => cluster.containsPerson(c.personAId) && cluster.containsPerson(c.personBId))
                .map((c) => c.edgeId)
                .toList(),
            impactScore: impact,
            recommendedAction: 'Leverage momentum in ${cluster.name} to deepen strategic cross-collaborations.',
            generatedAt: referenceDate,
          ),
        );
      }
    }

    // 2. Emerging Cluster Pattern
    for (final cluster in clusters) {
      if (cluster.type == RelationshipClusterType.emerging) {
        final patternId = 'pattern_emerging_${cluster.id}';
        final impact = _calculateImpactScore(
          volume: cluster.interactionCount,
          peopleCount: cluster.memberCount,
          avgStrength: cluster.averageRelationshipStrength,
          attentionRisk: 20.0,
        );

        patterns.add(
          NetworkPattern(
            id: patternId,
            type: NetworkPatternType.emergingCluster,
            severity: NetworkPatternSeverity.info,
            title: 'Emerging Cluster: ${cluster.name}',
            description:
                'Recent shared connections are developing between ${cluster.memberCount} contacts in ${cluster.name}.',
            evidencePersonIds: cluster.personIds,
            evidenceConnectionIds: connections
                .where((c) => cluster.containsPerson(c.personAId) && cluster.containsPerson(c.personBId))
                .map((c) => c.edgeId)
                .toList(),
            impactScore: impact,
            recommendedAction: 'Maintain follow-ups to establish a stable relationship cluster in ${cluster.name}.',
            generatedAt: referenceDate,
          ),
        );
      }
    }

    // 3. Cooling Cluster Pattern
    for (final cluster in clusters) {
      final clusterNodes = graph.nodes.where((n) => cluster.containsPerson(n.personId)).toList();
      final coolingCount = clusterNodes
          .where((n) =>
              n.relationshipState == RelationshipState.cooling ||
              n.relationshipState == RelationshipState.neglected ||
              n.momentumDirection == MomentumDirection.cooling ||
              n.momentumDirection == MomentumDirection.declining)
          .length;

      if (cluster.memberCount >= 2 && coolingCount >= (cluster.memberCount / 2.0).ceil()) {
        final patternId = 'pattern_cooling_${cluster.id}';
        final impact = _calculateImpactScore(
          volume: cluster.interactionCount,
          peopleCount: coolingCount,
          avgStrength: cluster.averageRelationshipStrength,
          attentionRisk: 80.0,
        );

        patterns.add(
          NetworkPattern(
            id: patternId,
            type: NetworkPatternType.coolingCluster,
            severity: NetworkPatternSeverity.critical,
            title: 'Cooling Cluster: ${cluster.name}',
            description:
                '$coolingCount of ${cluster.memberCount} contacts in ${cluster.name} are cooling or declining in interaction rhythm.',
            evidencePersonIds: clusterNodes.where((n) => n.relationshipState == RelationshipState.cooling || n.relationshipState == RelationshipState.neglected).map((n) => n.personId).toList(),
            evidenceConnectionIds: const [],
            impactScore: impact,
            recommendedAction: 'Schedule prioritized reconnects with key contacts in ${cluster.name}.',
            generatedAt: referenceDate,
          ),
        );
      }
    }

    // 4. Company Concentration Pattern
    final Map<String, List<NetworkGraphNode>> companyNodes = {};
    for (final n in graph.nodes) {
      if (n.company.trim().isNotEmpty && n.company.toLowerCase() != 'unknown') {
        companyNodes.putIfAbsent(n.company.trim(), () => []).add(n);
      }
    }

    for (final entry in companyNodes.entries) {
      final companyName = entry.key;
      final count = entry.value.length;
      final percentage = (count / totalContacts) * 100.0;

      if (totalContacts >= 4 && count >= 2 && percentage >= 35.0) {
        final patternId = 'pattern_concentration_${_slugify(companyName)}';
        final severity = percentage >= 50.0 ? NetworkPatternSeverity.high : NetworkPatternSeverity.medium;
        final impact = _calculateImpactScore(
          volume: count * 2,
          peopleCount: count,
          avgStrength: 60.0,
          attentionRisk: 40.0,
        );

        patterns.add(
          NetworkPattern(
            id: patternId,
            type: NetworkPatternType.companyConcentration,
            severity: severity,
            title: 'Company Concentration: $companyName',
            description:
                '${percentage.toStringAsFixed(1)}% of your professional network ($count contacts) is concentrated within $companyName.',
            evidencePersonIds: entry.value.map((n) => n.personId).toList(),
            evidenceConnectionIds: const [],
            impactScore: impact,
            recommendedAction: 'Diversify relationships across other key industry partners to mitigate single-company reliance.',
            generatedAt: referenceDate,
          ),
        );
      }
    }

    // 5. Relationship Bridge Pattern
    for (final node in graph.nodes) {
      final linkedClusters = clusters.where((cl) => cl.containsPerson(node.personId)).toList();
      if (linkedClusters.length >= 2) {
        final patternId = 'pattern_bridge_${node.personId}';
        final impact = _calculateImpactScore(
          volume: node.relationshipStrength.toInt(),
          peopleCount: linkedClusters.fold(0, (sum, cl) => sum + cl.memberCount),
          avgStrength: node.relationshipStrength,
          attentionRisk: 30.0,
        );

        patterns.add(
          NetworkPattern(
            id: patternId,
            type: NetworkPatternType.relationshipBridge,
            severity: NetworkPatternSeverity.medium,
            title: 'Relationship Bridge: ${node.personName}',
            description:
                '${node.personName} serves as a key bridge linking ${linkedClusters.length} distinct clusters (${linkedClusters.map((c) => c.name).join(", ")}).',
            evidencePersonIds: [node.personId],
            evidenceConnectionIds: connections.where((c) => c.involves(node.personId)).map((c) => c.edgeId).toList(),
            impactScore: impact,
            recommendedAction: 'Maintain regular contact with ${node.personName} as a pivotal cross-cluster connector.',
            generatedAt: referenceDate,
          ),
        );
      }
    }

    // 6. Isolated Contacts Pattern
    final isolatedIds = graph.isolatedPersonIds;
    if (isolatedIds.isNotEmpty && totalContacts >= 3) {
      final patternId = 'pattern_isolated_contacts';
      final impact = _calculateImpactScore(
        volume: isolatedIds.length,
        peopleCount: isolatedIds.length,
        avgStrength: 30.0,
        attentionRisk: 50.0,
      );

      patterns.add(
        NetworkPattern(
          id: patternId,
          type: NetworkPatternType.isolatedContact,
          severity: isolatedIds.length >= 3 ? NetworkPatternSeverity.medium : NetworkPatternSeverity.low,
          title: 'Isolated Contacts (${isolatedIds.length})',
          description:
              '${isolatedIds.length} contacts have no recorded connections to other people in your relationship graph.',
          evidencePersonIds: isolatedIds,
          evidenceConnectionIds: const [],
          impactScore: impact,
          recommendedAction: 'Capture shared organization or project metadata to link isolated contacts into the network.',
            generatedAt: referenceDate,
        ),
      );
    }

    // 7. Network Gap Pattern (Low cross-company connectivity when clusters exist)
    if (clusters.length >= 2 && totalContacts >= 4) {
      final crossCompanyConnections = connections.where((c) {
        final nodeA = nodeMap[c.personAId];
        final nodeB = nodeMap[c.personBId];
        return nodeA != null && nodeB != null && nodeA.company.toLowerCase() != nodeB.company.toLowerCase();
      }).length;

      if (crossCompanyConnections == 0) {
        const patternId = 'pattern_gap_cross_company';
        final impact = _calculateImpactScore(
          volume: clusters.length * 2,
          peopleCount: totalContacts,
          avgStrength: 50.0,
          attentionRisk: 60.0,
        );

        patterns.add(
          NetworkPattern(
            id: patternId,
            type: NetworkPatternType.networkGap,
            severity: NetworkPatternSeverity.medium,
            title: 'Network Opportunity: Low Cross-Company Connectivity',
            description:
                'Zero connections currently span between your ${clusters.length} distinct organizational clusters.',
            evidencePersonIds: const [],
            evidenceConnectionIds: const [],
            impactScore: impact,
            recommendedAction: 'Identify mutual introducers or shared industry projects to connect isolated clusters.',
            generatedAt: referenceDate,
          ),
        );
      }
    }

    // 8. Balanced Network Pattern
    if (clusters.length >= 2 && totalContacts >= 4 && isolatedIds.isEmpty && patterns.where((p) => p.severity == NetworkPatternSeverity.critical).isEmpty) {
      const patternId = 'pattern_balanced_network';
      patterns.add(
        NetworkPattern(
          id: patternId,
          type: NetworkPatternType.balancedNetwork,
          severity: NetworkPatternSeverity.info,
          title: 'Balanced Network Connectivity',
          description:
              'Your professional network demonstrates healthy cluster distribution and active connectivity.',
          evidencePersonIds: const [],
          evidenceConnectionIds: const [],
          impactScore: 65.0,
          recommendedAction: 'Continue current interaction rhythms across active clusters.',
            generatedAt: referenceDate,
        ),
      );
    }

    // Sort: severity DESC -> impactScore DESC -> id ASC
    patterns.sort();

    return List.unmodifiable(patterns);
  }

  static double _calculateImpactScore({
    required int volume,
    required int peopleCount,
    required double avgStrength,
    required double attentionRisk,
  }) {
    final volNorm = (volume / 10.0).clamp(0.0, 1.0);
    final peopleNorm = (peopleCount / 5.0).clamp(0.0, 1.0);
    final strNorm = (avgStrength / 100.0).clamp(0.0, 1.0);
    final attNorm = (attentionRisk / 100.0).clamp(0.0, 1.0);

    final score = (volNorm * 0.30 + peopleNorm * 0.25 + strNorm * 0.20 + attNorm * 0.15 + 0.10) * 100.0;
    if (score.isNaN || score.isInfinite) return 0.0;
    return score.clamp(0.0, 100.0);
  }

  static String _slugify(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
