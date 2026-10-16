import 'dart:async';
import '../../core/logging/safe_logger.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/capture/models/capture_models.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/relationship_intelligence/models/models.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/capture_repository.dart';
import '../../repositories/follow_up_repository.dart';
import '../../repositories/person_detail_repository.dart';
import 'relationship_state_classifier.dart';
import 'relationship_strength_calculator.dart';

/// Abstract service contract for calculating relationship intelligence.
abstract class RelationshipIntelligenceService {
  Future<PersonRelationshipIntelligence> getIntelligence(
    String personId, {
    PersonProfile? profile,
    DateTime? referenceDate,
  });

  Stream<PersonRelationshipIntelligence> streamIntelligence(
    String personId, {
    DateTime? referenceDate,
  });

  Future<List<PersonRelationshipIntelligence>> getBulkIntelligence(
    List<String> personIds, {
    DateTime? referenceDate,
  });
}

/// Production deterministic implementation of RelationshipIntelligenceService.
class DeterministicRelationshipIntelligenceService
    implements RelationshipIntelligenceService {
  static final SafeLogger _logger = SafeLogger('RelationshipIntelligenceService');
  final PersonDetailRepository personDetailRepository;
  final ActivityRepository? activityRepository;
  final FollowUpRepository? followUpRepository;
  final CaptureRepository? captureRepository;
  final RelationshipStrengthCalculator strengthCalculator;
  final RelationshipStateClassifier stateClassifier;

  const DeterministicRelationshipIntelligenceService({
    required this.personDetailRepository,
    this.activityRepository,
    this.followUpRepository,
    this.captureRepository,
    this.strengthCalculator = const DeterministicRelationshipStrengthCalculator(),
    this.stateClassifier = const DeterministicRelationshipStateClassifier(),
  });

  @override
  Future<PersonRelationshipIntelligence> getIntelligence(
    String personId, {
    PersonProfile? profile,
    DateTime? referenceDate,
  }) async {
    try {
      PersonProfile? prof = profile;
      if (prof == null) {
        prof = await personDetailRepository.getProfile(personId);
      }

      if (prof == null) {
        return PersonRelationshipIntelligence.empty(personId);
      }

      // Gather activities for this person if activityRepository is present
      List<ActivityItem> activities = const [];
      if (activityRepository != null) {
        try {
          final allActivities = await activityRepository!.streamActivities().first;
          activities = allActivities
              .where((a) => a.personId == personId || a.personName == prof?.name)
              .toList();
        } catch (_) {}
      }

      // Gather follow-ups for this person
      List<FollowUpItem> followUps = const [];
      if (followUpRepository != null) {
        try {
          final allFUs = await followUpRepository!.streamFollowUps().first;
          followUps = allFUs
              .where((f) => f.personId == personId || f.personName == prof?.name)
              .toList();
        } catch (_) {}
      }

      // Gather captures for this person
      List<CaptureItem> captures = const [];
      if (captureRepository != null) {
        try {
          final allCaps = await captureRepository!.streamRecentCaptures(limit: 50).first;
          captures = allCaps
              .where((c) => c.personId == personId || c.personName == prof?.name)
              .toList();
        } catch (_) {}
      }

      // Compute signals
      final signals = RelationshipSignals.fromDomainData(
        profile: prof,
        activities: activities,
        followUps: followUps,
        captures: captures,
        referenceDate: referenceDate,
      );

      // Compute strength
      final strength = strengthCalculator.calculate(signals);

      // Classify state
      final state = stateClassifier.classify(
        signals: signals,
        strength: strength,
      );

      // Generate explainability statements
      final explanations = _generateExplanations(prof, signals, strength, state);

      // Filter top factors
      final topFactors = _extractTopFactors(strength.factors);

      return PersonRelationshipIntelligence(
        personId: personId,
        signals: signals,
        strength: strength,
        state: state,
        generatedAt: DateTime.now(),
        explanations: explanations,
        topFactors: topFactors,
      );
    } catch (e, st) {
      _logger.error('Failed to compute relationship intelligence', e, st);
      return PersonRelationshipIntelligence.empty(personId);
    }
  }

  @override
  Stream<PersonRelationshipIntelligence> streamIntelligence(
    String personId, {
    DateTime? referenceDate,
  }) {
    return personDetailRepository.streamProfile(personId).asyncMap(
      (profile) async {
        if (profile == null) {
          return PersonRelationshipIntelligence.empty(personId);
        }
        return await getIntelligence(
          personId,
          profile: profile,
          referenceDate: referenceDate,
        );
      },
    );
  }

  @override
  Future<List<PersonRelationshipIntelligence>> getBulkIntelligence(
    List<String> personIds, {
    DateTime? referenceDate,
  }) async {
    final results = <PersonRelationshipIntelligence>[];
    for (final id in personIds) {
      results.add(await getIntelligence(id, referenceDate: referenceDate));
    }
    return results;
  }

  List<String> _generateExplanations(
    PersonProfile profile,
    RelationshipSignals signals,
    RelationshipStrength strength,
    RelationshipState state,
  ) {
    final items = <String>[];

    // Recency note
    if (signals.daysSinceLastInteraction != null) {
      final days = signals.daysSinceLastInteraction!;
      if (days == 0) {
        items.add('Interacted today');
      } else if (days <= 7) {
        items.add('Recent interaction $days day${days == 1 ? '' : 's'} ago');
      } else if (days <= 30) {
        items.add('Last interaction was $days days ago');
      } else if (days > 60) {
        items.add('No interaction in over $days days');
      }
    } else {
      items.add('No recent interaction recorded');
    }

    // Interaction frequency note
    if (signals.interactionCount >= 6) {
      items.add('Frequent interaction history (${signals.interactionCount} encounters)');
    } else if (signals.interactionCount >= 2) {
      items.add('${signals.interactionCount} recorded interactions');
    }

    // Memory richness note
    final totalMem = signals.memoryCount + signals.captureCount;
    if (totalMem >= 3) {
      items.add('$totalMem remembered context details and captures');
    } else if (totalMem > 0) {
      items.add('$totalMem context item stored');
    }

    // Follow-up engagement note
    if (signals.hasOverdueFollowUp) {
      items.add('${signals.overdueFollowUpCount} overdue commitment requires attention');
    } else if (signals.hasActiveFollowUp) {
      items.add('${signals.activeFollowUpCount} active follow-up in progress');
    } else if (signals.completedFollowUpCount > 0) {
      items.add('${signals.completedFollowUpCount} commitments fulfilled');
    }

    if (items.isEmpty) {
      items.add(state.description);
    }

    return items;
  }

  List<StrengthFactor> _extractTopFactors(List<StrengthFactor> factors) {
    final sorted = List<StrengthFactor>.from(factors)
      ..sort((a, b) => b.weightedScore.compareTo(a.weightedScore));
    return sorted.take(3).toList();
  }
}
