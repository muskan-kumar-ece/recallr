import 'dart:async';
import '../../features/activity/models/activity_models.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/relationship_intelligence/models/models.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/follow_up_repository.dart';
import '../../repositories/people_repository.dart';
import '../../repositories/person_detail_repository.dart';
import 'relationship_intelligence_service.dart';
import 'relationship_momentum_engine.dart';

/// Contract for fetching and streaming relationship momentum.
abstract class RelationshipMomentumService {
  Future<RelationshipMomentum> getMomentum(String personId, {DateTime? referenceDate});
  Future<List<RelationshipMomentum>> getBulkMomentum(List<String> personIds, {DateTime? referenceDate});
  Stream<RelationshipMomentum> streamMomentum(String personId, {DateTime? referenceDate});
}

/// Production implementation composing authentic Firestore repositories.
class DeterministicRelationshipMomentumService implements RelationshipMomentumService {
  final PeopleRepository peopleRepository;
  final PersonDetailRepository personDetailRepository;
  final ActivityRepository activityRepository;
  final FollowUpRepository followUpRepository;
  final RelationshipIntelligenceService relationshipIntelligenceService;
  final RelationshipMomentumEngine momentumEngine;

  DeterministicRelationshipMomentumService({
    required this.peopleRepository,
    required this.personDetailRepository,
    required this.activityRepository,
    required this.followUpRepository,
    required this.relationshipIntelligenceService,
    RelationshipMomentumEngine? momentumEngine,
  }) : momentumEngine = momentumEngine ?? const DeterministicRelationshipMomentumEngine();

  @override
  Future<RelationshipMomentum> getMomentum(String personId, {DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();

    final results = await Future.wait([
      personDetailRepository.getProfile(personId),
      activityRepository.streamActivities().first,
      relationshipIntelligenceService.getIntelligence(personId, referenceDate: now),
    ]);

    final profile = results[0] as PersonProfile?;
    final allActivities = results[1] as List<ActivityItem>;
    final intelligence = results[2] as PersonRelationshipIntelligence;

    final dates = _extractInteractionDates(personId, profile, allActivities);
    final overdueCount = intelligence.signals.overdueFollowUpCount;

    return momentumEngine.getMomentumSync(
      intelligence: intelligence,
      interactionDates: dates,
      profile: profile,
      overdueFollowUps: overdueCount,
      referenceDate: now,
    );
  }

  @override
  Future<List<RelationshipMomentum>> getBulkMomentum(List<String> personIds, {DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();

    final results = await Future.wait([
      relationshipIntelligenceService.getBulkIntelligence(personIds, referenceDate: now),
      activityRepository.streamActivities().first,
    ]);

    final intelList = results[0] as List<PersonRelationshipIntelligence>;
    final allActivities = results[1] as List<ActivityItem>;

    final datesMap = <String, List<DateTime>>{};
    for (final id in personIds) {
      datesMap[id] = _extractInteractionDates(id, null, allActivities);
    }

    return momentumEngine.rankMomentumSync(
      intelList,
      interactionDatesMap: datesMap,
      referenceDate: now,
    );
  }

  @override
  Stream<RelationshipMomentum> streamMomentum(String personId, {DateTime? referenceDate}) {
    return activityRepository.streamActivities().asyncMap((_) => getMomentum(personId, referenceDate: referenceDate));
  }

  List<DateTime> _extractInteractionDates(
    String personId,
    PersonProfile? profile,
    List<ActivityItem> allActivities,
  ) {
    final dates = <DateTime>[];

    // From timeline in profile if present
    if (profile != null) {
      for (final t in profile.timeline) {
        final d = DateTime.tryParse(t.date);
        if (d != null) {
          dates.add(d);
        }
      }
    }

    // From activities matching personId
    for (final a in allActivities) {
      if (a.personId == personId) {
        final d = a.createdAt ?? DateTime.tryParse(a.timestamp);
        if (d != null) {
          dates.add(d);
        }
      }
    }

    dates.sort((a, b) => a.compareTo(b));
    return dates;
  }
}
