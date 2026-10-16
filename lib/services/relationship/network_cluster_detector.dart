import 'package:flutter/foundation.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/relationship_intelligence/models/network_connection.dart';
import '../../features/relationship_intelligence/models/relationship_cluster.dart';
import '../../features/relationship_intelligence/models/relationship_strength.dart';

/// Contract for deterministic relationship cluster detection.
abstract class NetworkClusterDetector {
  List<RelationshipCluster> detectClusters({
    required List<PersonProfile> profiles,
    required List<NetworkConnection> connections,
    Map<String, RelationshipStrength> strengths = const {},
    Map<String, double> attentionScores = const {},
    DateTime? referenceDate,
  });
}

/// Production implementation of deterministic explicit-evidence cluster detector.
@immutable
class DeterministicNetworkClusterDetector implements NetworkClusterDetector {
  const DeterministicNetworkClusterDetector();

  @override
  List<RelationshipCluster> detectClusters({
    required List<PersonProfile> profiles,
    required List<NetworkConnection> connections,
    Map<String, RelationshipStrength> strengths = const {},
    Map<String, double> attentionScores = const {},
    DateTime? referenceDate,
  }) {
    if (profiles.length < 2) return const [];

    final Map<String, RelationshipCluster> clustersMap = {};

    // 1. Detect Company Clusters
    final Map<String, List<PersonProfile>> companyGroups = {};
    for (final p in profiles) {
      final comp = p.company.trim();
      if (comp.isEmpty || comp.toLowerCase() == 'unknown' || comp.toLowerCase() == 'n/a' || comp.toLowerCase() == 'none') {
        continue;
      }
      companyGroups.putIfAbsent(comp.toLowerCase(), () => []).add(p);
    }

    for (final entry in companyGroups.entries) {
      final group = entry.value;
      if (group.length < 2) continue;

      final originalCompanyName = group.first.company.trim();
      final slug = _slugify(originalCompanyName);
      final clusterId = 'cluster_company_$slug';
      final memberIds = group.map((p) => p.id).toList();

      final avgStrength = _calculateAvgStrength(memberIds, strengths, group);
      final avgAttention = _calculateAvgAttention(memberIds, attentionScores);
      final totalInteractions = group.fold<int>(0, (sum, p) => sum + p.totalInteractions);

      final clusterType = group.length >= 3
          ? RelationshipClusterType.company
          : RelationshipClusterType.emerging;

      final clusterStrength = _calculateClusterStrength(
        memberCount: group.length,
        avgStrength: avgStrength,
        totalInteractions: totalInteractions,
      );

      final desc = group.length >= 3
          ? 'Established organizational cluster across $originalCompanyName with ${group.length} contacts.'
          : 'Emerging connection between ${group.length} contacts at $originalCompanyName.';

      clustersMap[clusterId] = RelationshipCluster(
        id: clusterId,
        name: originalCompanyName,
        type: clusterType,
        personIds: memberIds,
        averageRelationshipStrength: avgStrength,
        averageAttentionScore: avgAttention,
        interactionCount: totalInteractions,
        sharedContextCount: 1,
        clusterStrength: clusterStrength,
        description: desc,
        generatedAt: referenceDate,
      );
    }

    // 2. Detect Project / Context Clusters from Connections
    final Map<String, Set<String>> contextGroups = {};
    final Map<String, String> contextDisplayNames = {};

    for (final conn in connections) {
      if (conn.sharedContext != null && conn.sharedContext!.trim().isNotEmpty) {
        final ctx = conn.sharedContext!.trim();
        final slug = _slugify(ctx);
        contextGroups.putIfAbsent(slug, () => {})..add(conn.personAId)..add(conn.personBId);
        contextDisplayNames.putIfAbsent(slug, () => ctx);
      }
    }

    for (final entry in contextGroups.entries) {
      final slug = entry.key;
      final memberIds = entry.value.toList();
      if (memberIds.length < 2) continue;

      final clusterId = 'cluster_project_$slug';
      // Skip if this exact cluster ID already exists
      if (clustersMap.containsKey(clusterId)) continue;

      final groupProfiles = profiles.where((p) => memberIds.contains(p.id)).toList();
      final avgStrength = _calculateAvgStrength(memberIds, strengths, groupProfiles);
      final avgAttention = _calculateAvgAttention(memberIds, attentionScores);
      final totalInteractions = groupProfiles.fold<int>(0, (sum, p) => sum + p.totalInteractions);
      final originalName = contextDisplayNames[slug] ?? slug;

      final clusterType = memberIds.length >= 3
          ? RelationshipClusterType.project
          : RelationshipClusterType.emerging;

      final clusterStrength = _calculateClusterStrength(
        memberCount: memberIds.length,
        avgStrength: avgStrength,
        totalInteractions: totalInteractions,
      );

      final desc = memberIds.length >= 3
          ? 'Project collaboration cluster for "$originalName" uniting ${memberIds.length} contacts.'
          : 'Emerging shared context for "$originalName" between ${memberIds.length} contacts.';

      clustersMap[clusterId] = RelationshipCluster(
        id: clusterId,
        name: originalName,
        type: clusterType,
        personIds: memberIds,
        averageRelationshipStrength: avgStrength,
        averageAttentionScore: avgAttention,
        interactionCount: totalInteractions,
        sharedContextCount: 1,
        clusterStrength: clusterStrength,
        description: desc,
        generatedAt: referenceDate,
      );
    }

    final clusters = clustersMap.values.toList();

    // Deterministic sorting: clusterStrength DESC, memberCount DESC, id ASC
    clusters.sort((a, b) {
      final strengthComp = b.clusterStrength.compareTo(a.clusterStrength);
      if (strengthComp != 0) return strengthComp;
      final memberComp = b.memberCount.compareTo(a.memberCount);
      if (memberComp != 0) return memberComp;
      return a.id.compareTo(b.id);
    });

    return List.unmodifiable(clusters);
  }

  static double _calculateAvgStrength(
    List<String> memberIds,
    Map<String, RelationshipStrength> strengths,
    List<PersonProfile> profiles,
  ) {
    if (memberIds.isEmpty) return 0.0;
    final Map<String, PersonProfile> profileMap = {
      for (final p in profiles) p.id: p,
    };
    double total = 0.0;
    for (final id in memberIds) {
      if (strengths.containsKey(id)) {
        total += strengths[id]!.score;
      } else {
        final profile = profileMap[id];
        if (profile != null) {
          total += (profile.totalInteractions >= 4 ? 75.0 : (profile.totalInteractions >= 2 ? 50.0 : 25.0));
        } else {
          total += 50.0;
        }
      }
    }
    return (total / memberIds.length).clamp(0.0, 100.0);
  }

  static double _calculateAvgAttention(
    List<String> memberIds,
    Map<String, double> attentionScores,
  ) {
    if (memberIds.isEmpty) return 0.0;
    double total = 0.0;
    for (final id in memberIds) {
      total += attentionScores[id] ?? 0.0;
    }
    return (total / memberIds.length).clamp(0.0, 100.0);
  }

  static double _calculateClusterStrength({
    required int memberCount,
    required double avgStrength,
    required int totalInteractions,
  }) {
    final memberFactor = (memberCount / 5.0).clamp(0.2, 1.0);
    final strFactor = (avgStrength / 100.0).clamp(0.0, 1.0);
    final interFactor = (totalInteractions / 15.0).clamp(0.0, 1.0);

    final score = (memberFactor * 0.40 + strFactor * 0.40 + interFactor * 0.20) * 100.0;
    if (score.isNaN || score.isInfinite) return 0.0;
    return score.clamp(0.0, 100.0);
  }

  static String _slugify(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
