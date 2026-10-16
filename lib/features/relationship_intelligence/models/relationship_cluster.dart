import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Categories of relationship clusters detected from authentic network data.
enum RelationshipClusterType {
  company,
  project,
  interaction,
  context,
  mixed,
  emerging,
}

extension RelationshipClusterTypeExt on RelationshipClusterType {
  String get label {
    switch (this) {
      case RelationshipClusterType.company:
        return 'Company Cluster';
      case RelationshipClusterType.project:
        return 'Project Cluster';
      case RelationshipClusterType.interaction:
        return 'Interaction Cluster';
      case RelationshipClusterType.context:
        return 'Context Cluster';
      case RelationshipClusterType.mixed:
        return 'Cross-Domain Cluster';
      case RelationshipClusterType.emerging:
        return 'Emerging Cluster';
    }
  }

  IconData get icon {
    switch (this) {
      case RelationshipClusterType.company:
        return Icons.business_outlined;
      case RelationshipClusterType.project:
        return Icons.rocket_launch_outlined;
      case RelationshipClusterType.interaction:
        return Icons.forum_outlined;
      case RelationshipClusterType.context:
        return Icons.category_outlined;
      case RelationshipClusterType.mixed:
        return Icons.hub_outlined;
      case RelationshipClusterType.emerging:
        return Icons.auto_awesome_outlined;
    }
  }

  Color get colorToken {
    switch (this) {
      case RelationshipClusterType.company:
        return RecallrColors.aiCyanHighlight;
      case RelationshipClusterType.project:
        return RecallrColors.aiElectricViolet;
      case RelationshipClusterType.interaction:
        return RecallrColors.emeraldVerified;
      case RelationshipClusterType.context:
        return RecallrColors.warmAmberGold;
      case RelationshipClusterType.mixed:
        return RecallrColors.aiCyanHighlight;
      case RelationshipClusterType.emerging:
        return RecallrColors.textSecondary;
    }
  }
}

/// An explainable, evidence-backed cluster of interconnected professional contacts.
@immutable
class RelationshipCluster {
  final String id; // Deterministic slug, e.g., cluster_company_mosaic_labs
  final String name;
  final RelationshipClusterType type;
  final List<String> personIds;
  final int memberCount;
  final double averageRelationshipStrength; // 0.0 to 100.0
  final double averageAttentionScore; // 0.0 to 100.0
  final int interactionCount;
  final int sharedContextCount;
  final double clusterStrength; // 0.0 to 100.0 composite score
  final String description;
  final DateTime generatedAt;

  RelationshipCluster({
    required this.id,
    required this.name,
    required this.type,
    required List<String> personIds,
    required double averageRelationshipStrength,
    required double averageAttentionScore,
    required this.interactionCount,
    required this.sharedContextCount,
    required double clusterStrength,
    required this.description,
    DateTime? generatedAt,
  })  : personIds = List.unmodifiable(List<String>.from(personIds)..sort()),
        memberCount = personIds.length,
        averageRelationshipStrength = averageRelationshipStrength.clamp(0.0, 100.0),
        averageAttentionScore = averageAttentionScore.clamp(0.0, 100.0),
        clusterStrength = clusterStrength.clamp(0.0, 100.0),
        generatedAt = generatedAt ?? DateTime.now();

  /// Whether this cluster is established (>= 3 members) vs emerging (2 members).
  bool get isEstablished => memberCount >= 3;

  /// Whether this cluster is strong (clusterStrength >= 70.0 and memberCount >= 3).
  bool get isStrong => clusterStrength >= 70.0 && memberCount >= 3;

  /// Whether the specified contact is a member of this cluster.
  bool containsPerson(String personId) => personIds.contains(personId);

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'personIds': personIds,
        'memberCount': memberCount,
        'averageRelationshipStrength': averageRelationshipStrength,
        'averageAttentionScore': averageAttentionScore,
        'interactionCount': interactionCount,
        'sharedContextCount': sharedContextCount,
        'clusterStrength': clusterStrength,
        'description': description,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory RelationshipCluster.fromMap(Map<String, dynamic> map) {
    final rawIds = (map['personIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const <String>[];
    return RelationshipCluster(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: RelationshipClusterType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RelationshipClusterType.context,
      ),
      personIds: rawIds,
      averageRelationshipStrength: (map['averageRelationshipStrength'] as num?)?.toDouble() ?? 0.0,
      averageAttentionScore: (map['averageAttentionScore'] as num?)?.toDouble() ?? 0.0,
      interactionCount: (map['interactionCount'] as num?)?.toInt() ?? 0,
      sharedContextCount: (map['sharedContextCount'] as num?)?.toInt() ?? 0,
      clusterStrength: (map['clusterStrength'] as num?)?.toDouble() ?? 0.0,
      description: map['description']?.toString() ?? '',
      generatedAt: map['generatedAt'] != null ? DateTime.tryParse(map['generatedAt'].toString()) : null,
    );
  }

  factory RelationshipCluster.fromJson(Map<String, dynamic> json) => RelationshipCluster.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelationshipCluster &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
