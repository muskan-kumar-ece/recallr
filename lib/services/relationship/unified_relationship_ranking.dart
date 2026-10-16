import '../../features/relationship_intelligence/models/models.dart';

/// Categories for deterministic people ranking and browsing.
enum UnifiedPeopleCategory {
  all,
  needsAttention,
  strongest,
  strengthening,
  cooling,
  recentlyActive,
  recentlyAdded,
  isolated,
  bridgeContacts,
}

extension UnifiedPeopleCategoryExtensions on UnifiedPeopleCategory {
  String get label {
    switch (this) {
      case UnifiedPeopleCategory.all:
        return 'All';
      case UnifiedPeopleCategory.needsAttention:
        return 'Needs Attention';
      case UnifiedPeopleCategory.strongest:
        return 'Strongest';
      case UnifiedPeopleCategory.strengthening:
        return 'Strengthening';
      case UnifiedPeopleCategory.cooling:
        return 'Cooling';
      case UnifiedPeopleCategory.recentlyActive:
        return 'Recently Active';
      case UnifiedPeopleCategory.recentlyAdded:
        return 'Recently Added';
      case UnifiedPeopleCategory.isolated:
        return 'Isolated';
      case UnifiedPeopleCategory.bridgeContacts:
        return 'Bridge Contacts';
    }
  }
}

/// Canonical, deterministic ranking algorithms for relationship intelligence.
class UnifiedRelationshipRanking {
  const UnifiedRelationshipRanking();

  /// Attention ranking:
  /// priority DESC -> attentionScore DESC -> relationshipStrength DESC -> personName ASC -> personId ASC
  List<RelationshipAttention> rankAttention(List<RelationshipAttention> attention) {
    final list = List<RelationshipAttention>.from(attention);
    list.sort((a, b) {
      // 1. Priority DESC
      final pCmp = b.priority.rank.compareTo(a.priority.rank);
      if (pCmp != 0) return pCmp;

      // 2. Attention Score DESC
      final sCmp = b.score.compareTo(a.score);
      if (sCmp != 0) return sCmp;

      // 3. Person Name ASC
      final nCmp = a.personName.compareTo(b.personName);
      if (nCmp != 0) return nCmp;

      // 4. Person ID ASC
      return a.personId.compareTo(b.personId);
    });
    return List.unmodifiable(list);
  }

  /// Action ranking:
  /// priority DESC -> relationshipScore DESC -> recommendedAt ASC -> personName ASC -> personId ASC
  List<RelationshipAction> rankActions(List<RelationshipAction> actions) {
    final list = List<RelationshipAction>.from(actions);
    list.sort((a, b) {
      // 1. Priority DESC
      final pCmp = b.priority.rank.compareTo(a.priority.rank);
      if (pCmp != 0) return pCmp;

      // 2. Score DESC
      final sCmp = b.relationshipScore.compareTo(a.relationshipScore);
      if (sCmp != 0) return sCmp;

      // 3. Timing / recommendedAt ASC
      final tCmp = a.recommendedAt.compareTo(b.recommendedAt);
      if (tCmp != 0) return tCmp;

      // 4. Person Name ASC
      final nCmp = a.personName.compareTo(b.personName);
      if (nCmp != 0) return nCmp;

      // 5. Person ID ASC
      return a.personId.compareTo(b.personId);
    });
    return List.unmodifiable(list);
  }

  /// Momentum ranking:
  /// momentum significance DESC -> momentumScore DESC -> personName ASC -> personId ASC
  List<RelationshipMomentum> rankMomentum(List<RelationshipMomentum> momentum) {
    final list = List<RelationshipMomentum>.from(momentum);
    list.sort((a, b) {
      // 1. Momentum significance DESC
      final sigA = _momentumSignificance(a.direction);
      final sigB = _momentumSignificance(b.direction);
      final sigCmp = sigB.compareTo(sigA);
      if (sigCmp != 0) return sigCmp;

      // 2. Momentum Score DESC
      final sCmp = b.momentumScore.compareTo(a.momentumScore);
      if (sCmp != 0) return sCmp;

      // 3. Person ID ASC
      return a.personId.compareTo(b.personId);
    });
    return List.unmodifiable(list);
  }

  int _momentumSignificance(MomentumDirection direction) {
    switch (direction) {
      case MomentumDirection.strengthening:
        return 5;
      case MomentumDirection.cooling:
        return 4;
      case MomentumDirection.declining:
        return 3;
      case MomentumDirection.recovering:
        return 2;
      case MomentumDirection.newlyDeveloping:
        return 2;
      case MomentumDirection.stable:
        return 1;
      case MomentumDirection.insufficientHistory:
        return 0;
    }
  }

  /// Categorical people ranking with deterministic tie-breaking.
  List<UnifiedPersonRelationshipIntelligence> rankPeople(
    List<UnifiedPersonRelationshipIntelligence> people, {
    UnifiedPeopleCategory category = UnifiedPeopleCategory.all,
  }) {
    final list = List<UnifiedPersonRelationshipIntelligence>.from(people);

    switch (category) {
      case UnifiedPeopleCategory.all:
        list.sort((a, b) {
          final nCmp = a.personName.compareTo(b.personName);
          if (nCmp != 0) return nCmp;
          return a.personId.compareTo(b.personId);
        });
        return List.unmodifiable(list);

      case UnifiedPeopleCategory.needsAttention:
        final filtered = list.where((p) => p.needsAttention).toList();
        filtered.sort((a, b) {
          final pCmp = b.attentionPriority.rank.compareTo(a.attentionPriority.rank);
          if (pCmp != 0) return pCmp;
          final sCmp = b.attentionScore.compareTo(a.attentionScore);
          if (sCmp != 0) return sCmp;
          return a.personName.compareTo(b.personName);
        });
        return List.unmodifiable(filtered);

      case UnifiedPeopleCategory.strongest:
        list.sort((a, b) {
          final sCmp = b.strengthScore.compareTo(a.strengthScore);
          if (sCmp != 0) return sCmp;
          final iCmp = b.relationshipSignals.interactionCount
              .compareTo(a.relationshipSignals.interactionCount);
          if (iCmp != 0) return iCmp;
          return a.personName.compareTo(b.personName);
        });
        return List.unmodifiable(list);

      case UnifiedPeopleCategory.strengthening:
        final filtered = list
            .where((p) =>
                p.momentumDirection == MomentumDirection.strengthening ||
                p.momentumDirection == MomentumDirection.recovering)
            .toList();
        filtered.sort((a, b) {
          final mCmp = b.momentumScore.compareTo(a.momentumScore);
          if (mCmp != 0) return mCmp;
          return b.strengthScore.compareTo(a.strengthScore);
        });
        return List.unmodifiable(filtered);

      case UnifiedPeopleCategory.cooling:
        final filtered = list
            .where((p) =>
                p.momentumDirection == MomentumDirection.cooling ||
                p.momentumDirection == MomentumDirection.declining ||
                p.relationshipState == RelationshipState.cooling ||
                p.relationshipState == RelationshipState.neglected)
            .toList();
        filtered.sort((a, b) {
          final aCmp = b.attentionScore.compareTo(a.attentionScore);
          if (aCmp != 0) return aCmp;
          return a.strengthScore.compareTo(b.strengthScore);
        });
        return List.unmodifiable(filtered);

      case UnifiedPeopleCategory.recentlyActive:
        list.sort((a, b) {
          final daysA = a.relationshipSignals.daysSinceLastInteraction ?? 9999;
          final daysB = b.relationshipSignals.daysSinceLastInteraction ?? 9999;
          final dCmp = daysA.compareTo(daysB);
          if (dCmp != 0) return dCmp;
          return a.personName.compareTo(b.personName);
        });
        return List.unmodifiable(list);

      case UnifiedPeopleCategory.recentlyAdded:
        list.sort((a, b) {
          return a.personId.compareTo(b.personId);
        });
        return List.unmodifiable(list);

      case UnifiedPeopleCategory.isolated:
        final filtered = list.where((p) => p.isIsolated).toList();
        filtered.sort((a, b) => a.personName.compareTo(b.personName));
        return List.unmodifiable(filtered);

      case UnifiedPeopleCategory.bridgeContacts:
        final filtered = list.where((p) => p.isBridge).toList();
        filtered.sort((a, b) => a.personName.compareTo(b.personName));
        return List.unmodifiable(filtered);
    }
  }
}
