import 'package:flutter/foundation.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/relationship_intelligence/models/models.dart';
import 'relationship_action_engine.dart';
import 'relationship_attention_calculator.dart';
import 'relationship_attention_explanation.dart';
import 'relationship_attention_priority_calculator.dart';

/// Abstract contract for computing and ranking relationship attention across contacts.
abstract class RelationshipAttentionEngine {
  Future<RelationshipAttention> getAttention(
    PersonRelationshipIntelligence intelligence, {
    PersonProfile? profile,
    String? company,
    String? personName,
    RelationshipAction? primaryAction,
  });

  RelationshipAttention getAttentionSync(
    PersonRelationshipIntelligence intelligence, {
    PersonProfile? profile,
    String? company,
    String? personName,
    RelationshipAction? primaryAction,
  });

  Future<List<RelationshipAttention>> rankAttention(
    List<PersonRelationshipIntelligence> relationships, {
    Map<String, PersonProfile>? profiles,
    Map<String, RelationshipAction?>? primaryActions,
    Map<String, String>? companyMap,
    Map<String, String>? nameMap,
  });

  List<RelationshipAttention> rankAttentionSync(
    List<PersonRelationshipIntelligence> relationships, {
    Map<String, PersonProfile>? profiles,
    Map<String, RelationshipAction?>? primaryActions,
    Map<String, String>? companyMap,
    Map<String, String>? nameMap,
  });

  RelationshipAttention? getTopAttention(
    List<PersonRelationshipIntelligence> relationships, {
    Map<String, PersonProfile>? profiles,
    Map<String, RelationshipAction?>? primaryActions,
    Map<String, String>? companyMap,
    Map<String, String>? nameMap,
  });
}

/// Production implementation of deterministic relationship attention engine.
@immutable
class DeterministicRelationshipAttentionEngine implements RelationshipAttentionEngine {
  final RelationshipAttentionCalculator calculator;
  final RelationshipAttentionPriorityCalculator priorityCalculator;
  final RelationshipActionEngine actionEngine;

  const DeterministicRelationshipAttentionEngine({
    this.calculator = const DeterministicRelationshipAttentionCalculator(),
    this.priorityCalculator = const DeterministicRelationshipAttentionPriorityCalculator(),
    this.actionEngine = const DeterministicRelationshipActionEngine(),
  });

  @override
  Future<RelationshipAttention> getAttention(
    PersonRelationshipIntelligence intelligence, {
    PersonProfile? profile,
    String? company,
    String? personName,
    RelationshipAction? primaryAction,
  }) async {
    return getAttentionSync(
      intelligence,
      profile: profile,
      company: company,
      personName: personName,
      primaryAction: primaryAction,
    );
  }

  @override
  RelationshipAttention getAttentionSync(
    PersonRelationshipIntelligence intelligence, {
    PersonProfile? profile,
    String? company,
    String? personName,
    RelationshipAction? primaryAction,
  }) {
    final name = personName ?? profile?.name ?? 'Contact';
    final comp = company ?? profile?.company;

    // 1. Calculate deterministic attention score (0.0 .. 100.0)
    final score = calculator.calculate(
      signals: intelligence.signals,
      strength: intelligence.strength,
      state: intelligence.state,
    );

    // 2. Calculate priority tier
    final priority = priorityCalculator.calculate(
      attentionScore: score,
      intelligence: intelligence,
    );

    // 3. Resolve primary action from 13H-02 engine if profile is available and action not explicitly supplied
    final action = primaryAction ??
        (profile != null ? actionEngine.getPrimaryAction(profile, intelligence) : null);

    // 4. Generate grounded explainable reasons
    final reasons = RelationshipAttentionExplanation.generateReasons(
      intelligence: intelligence,
      personName: name,
      company: comp,
      primaryAction: action,
    );

    // 5. Generate recommended timing
    final timing = RelationshipAttentionExplanation.generateRecommendedTiming(
      priority: priority,
      intelligence: intelligence,
    );

    // 6. Generate stable deduplication key
    final primaryReasonCode = reasons.isNotEmpty ? reasons.first.code : 'general';
    final deduplicationKey = 'attention_${intelligence.personId}_${priority.name}_$primaryReasonCode';

    return RelationshipAttention(
      personId: intelligence.personId,
      personName: name,
      company: comp,
      attentionScore: score,
      priority: priority,
      relationshipState: intelligence.state,
      relationshipStrength: intelligence.strength,
      reasons: reasons,
      primaryAction: action,
      recommendedTiming: timing,
      generatedAt: DateTime.now(),
      deduplicationKey: deduplicationKey,
    );
  }

  @override
  Future<List<RelationshipAttention>> rankAttention(
    List<PersonRelationshipIntelligence> relationships, {
    Map<String, PersonProfile>? profiles,
    Map<String, RelationshipAction?>? primaryActions,
    Map<String, String>? companyMap,
    Map<String, String>? nameMap,
  }) async {
    return rankAttentionSync(
      relationships,
      profiles: profiles,
      primaryActions: primaryActions,
      companyMap: companyMap,
      nameMap: nameMap,
    );
  }

  @override
  List<RelationshipAttention> rankAttentionSync(
    List<PersonRelationshipIntelligence> relationships, {
    Map<String, PersonProfile>? profiles,
    Map<String, RelationshipAction?>? primaryActions,
    Map<String, String>? companyMap,
    Map<String, String>? nameMap,
  }) {
    if (relationships.isEmpty) {
      return const [];
    }

    // Collapse multiple intelligence items per personId into ONE attention item
    final uniqueMap = <String, PersonRelationshipIntelligence>{};
    for (final rel in relationships) {
      uniqueMap[rel.personId] = rel;
    }

    final attentionList = <RelationshipAttention>[];
    for (final entry in uniqueMap.entries) {
      final id = entry.key;
      final intel = entry.value;
      final prof = profiles?[id];
      final comp = companyMap?[id] ?? prof?.company;
      final name = nameMap?[id] ?? prof?.name ?? 'Contact';
      final action = primaryActions?[id];

      final attention = getAttentionSync(
        intel,
        profile: prof,
        company: comp,
        personName: name,
        primaryAction: action,
      );
      attentionList.add(attention);
    }

    // Deterministic sorting order:
    // 1. priority rank DESC
    // 2. attention score DESC
    // 3. relationship strength DESC
    // 4. person name ASC
    // 5. personId ASC
    attentionList.sort((a, b) {
      final prioComp = b.priority.rank.compareTo(a.priority.rank);
      if (prioComp != 0) return prioComp;

      final scoreComp = b.attentionScore.compareTo(a.attentionScore);
      if (scoreComp != 0) return scoreComp;

      final strengthComp = b.relationshipStrength.score.compareTo(a.relationshipStrength.score);
      if (strengthComp != 0) return strengthComp;

      final nameComp = a.personName.compareTo(b.personName);
      if (nameComp != 0) return nameComp;

      return a.personId.compareTo(b.personId);
    });

    return attentionList;
  }

  @override
  RelationshipAttention? getTopAttention(
    List<PersonRelationshipIntelligence> relationships, {
    Map<String, PersonProfile>? profiles,
    Map<String, RelationshipAction?>? primaryActions,
    Map<String, String>? companyMap,
    Map<String, String>? nameMap,
  }) {
    final ranked = rankAttentionSync(
      relationships,
      profiles: profiles,
      primaryActions: primaryActions,
      companyMap: companyMap,
      nameMap: nameMap,
    );
    return ranked.isNotEmpty ? ranked.first : null;
  }
}
