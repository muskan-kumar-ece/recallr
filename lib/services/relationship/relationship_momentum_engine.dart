import 'package:flutter/foundation.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/relationship_intelligence/models/models.dart';
import 'relationship_cadence_calculator.dart';
import 'relationship_evolution_classifier.dart';
import 'relationship_velocity_calculator.dart';

/// Contract for computing relationship evolution and momentum across contacts.
abstract class RelationshipMomentumEngine {
  RelationshipMomentum getMomentumSync({
    required PersonRelationshipIntelligence intelligence,
    required List<DateTime> interactionDates,
    PersonProfile? profile,
    int overdueFollowUps = 0,
    DateTime? referenceDate,
  });

  Future<RelationshipMomentum> getMomentum({
    required PersonRelationshipIntelligence intelligence,
    required List<DateTime> interactionDates,
    PersonProfile? profile,
    int overdueFollowUps = 0,
    DateTime? referenceDate,
  });

  List<RelationshipMomentum> rankMomentumSync(
    List<PersonRelationshipIntelligence> intelligenceList, {
    Map<String, List<DateTime>> interactionDatesMap = const {},
    Map<String, PersonProfile> profileMap = const {},
    Map<String, int> overdueFollowUpsMap = const {},
    DateTime? referenceDate,
  });
}

/// Production implementation of deterministic relationship momentum engine.
@immutable
class DeterministicRelationshipMomentumEngine implements RelationshipMomentumEngine {
  final RelationshipCadenceCalculator cadenceCalculator;
  final RelationshipVelocityCalculator velocityCalculator;
  final RelationshipEvolutionClassifier evolutionClassifier;

  const DeterministicRelationshipMomentumEngine({
    this.cadenceCalculator = const DeterministicRelationshipCadenceCalculator(),
    this.velocityCalculator = const DeterministicRelationshipVelocityCalculator(),
    this.evolutionClassifier = const DeterministicRelationshipEvolutionClassifier(),
  });

  @override
  RelationshipMomentum getMomentumSync({
    required PersonRelationshipIntelligence intelligence,
    required List<DateTime> interactionDates,
    PersonProfile? profile,
    int overdueFollowUps = 0,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    final cadence = cadenceCalculator.calculate(
      interactionDates: interactionDates,
      referenceDate: now,
    );

    final velocity = velocityCalculator.calculate(
      interactionDates: interactionDates,
      referenceDate: now,
    );

    final createdDate = profile?.createdAt;

    return evolutionClassifier.classify(
      personId: intelligence.personId,
      signals: intelligence.signals,
      state: intelligence.state,
      strength: intelligence.strength,
      velocity: velocity,
      cadence: cadence,
      overdueFollowUps: overdueFollowUps,
      contactCreatedDate: createdDate,
      referenceDate: now,
    );
  }

  @override
  Future<RelationshipMomentum> getMomentum({
    required PersonRelationshipIntelligence intelligence,
    required List<DateTime> interactionDates,
    PersonProfile? profile,
    int overdueFollowUps = 0,
    DateTime? referenceDate,
  }) async {
    return getMomentumSync(
      intelligence: intelligence,
      interactionDates: interactionDates,
      profile: profile,
      overdueFollowUps: overdueFollowUps,
      referenceDate: referenceDate,
    );
  }

  @override
  List<RelationshipMomentum> rankMomentumSync(
    List<PersonRelationshipIntelligence> intelligenceList, {
    Map<String, List<DateTime>> interactionDatesMap = const {},
    Map<String, PersonProfile> profileMap = const {},
    Map<String, int> overdueFollowUpsMap = const {},
    DateTime? referenceDate,
  }) {
    final results = <RelationshipMomentum>[];

    for (final intel in intelligenceList) {
      final dates = interactionDatesMap[intel.personId] ?? const [];
      final profile = profileMap[intel.personId];
      final overdue = overdueFollowUpsMap[intel.personId] ?? intel.signals.overdueFollowUpCount;

      final momentum = getMomentumSync(
        intelligence: intel,
        interactionDates: dates,
        profile: profile,
        overdueFollowUps: overdue,
        referenceDate: referenceDate,
      );
      results.add(momentum);
    }

    // Deterministic Sort:
    // 1. Recovering & Strengthening first, then Stable, Cooling, Declining, InsufficientHistory
    // 2. Score DESC
    // 3. PersonId ASC
    results.sort((a, b) {
      final scoreCmp = b.momentumScore.compareTo(a.momentumScore);
      if (scoreCmp != 0) return scoreCmp;
      return a.personId.compareTo(b.personId);
    });

    return results;
  }
}
