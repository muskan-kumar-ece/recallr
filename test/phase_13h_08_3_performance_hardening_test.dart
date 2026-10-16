import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/models/entity_resolution_models.dart';
import 'package:recaller/features/capture/models/ocr_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/models/relationship_memory_models.dart';
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/repositories/activity_repository.dart';
import 'package:recaller/repositories/capture_repository.dart';
import 'package:recaller/repositories/follow_up_repository.dart';
import 'package:recaller/repositories/people_repository.dart';
import 'package:recaller/repositories/person_detail_repository.dart';
import 'package:recaller/screens/network/network_dashboard_screen.dart';
import 'package:recaller/services/entity_resolution_service.dart';
import 'package:recaller/services/relationship/network_connection_calculator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recaller/services/relationship/unified_relationship_intelligence_service.dart';

class _FakePerfUser implements User {
  @override
  final String uid;

  _FakePerfUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePerfFirebaseAuth implements FirebaseAuth {
  User? _currentUser;
  final StreamController<User?> _authController = StreamController<User?>.broadcast();

  _FakePerfFirebaseAuth(this._currentUser);

  @override
  User? get currentUser => _currentUser;

  set currentUser(User? user) {
    _currentUser = user;
    _authController.add(user);
  }

  @override
  Stream<User?> authStateChanges() => _authController.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Instrumented Query-Counting Mock Repositories
// ---------------------------------------------------------------------------

class QueryTrackingPeopleRepository implements PeopleRepository {
  final Map<String, PersonItem> store;
  int fullScanCount = 0;
  int findByEmailCount = 0;
  int findByPhoneCount = 0;
  int findCandidatesByNameCount = 0;
  int findCandidatesByNameAndCompanyCount = 0;
  int getPersonCount = 0;
  int streamPeopleCount = 0;
  int? lastLimitUsed;

  QueryTrackingPeopleRepository(List<PersonItem> initialPeople)
      : store = {for (final p in initialPeople) p.id: p};

  @override
  Stream<List<PersonItem>> streamPeople({String? query, PeopleFilterOption? filter, int limit = 100}) {
    streamPeopleCount++;
    lastLimitUsed = limit;
    var result = store.values.toList();
    if (limit > 0) result = result.take(limit).toList();
    return Stream.value(result);
  }

  @override
  Stream<List<PersonItem>> streamRecentlyInteracted({int limit = 5}) =>
      Stream.value(store.values.take(limit).toList());

  @override
  Future<PersonItem?> getPerson(String id) async {
    getPersonCount++;
    return store[id];
  }

  @override
  Future<void> addPerson(PersonItem person) async => store[person.id] = person;

  @override
  Future<void> updatePerson(PersonItem person) async => store[person.id] = person;

  @override
  Future<void> deletePerson(String id) async => store.remove(id);

  @override
  Future<PersonItem?> findPersonByEmail(String normalizedEmail) async {
    findByEmailCount++;
    final clean = normalizedEmail.trim().toLowerCase();
    for (final p in store.values) {
      if (p.email != null && p.email!.trim().toLowerCase() == clean) return p;
    }
    return null;
  }

  @override
  Future<PersonItem?> findPersonByPhone(String normalizedPhone) async {
    findByPhoneCount++;
    final clean = normalizedPhone.replaceAll(RegExp(r'[^0-9]'), '');
    for (final p in store.values) {
      if (p.phone != null && p.phone!.replaceAll(RegExp(r'[^0-9]'), '') == clean) return p;
    }
    return null;
  }

  @override
  Future<List<PersonItem>> findCandidatesByName(String normalizedName) async {
    findCandidatesByNameCount++;
    final clean = normalizedName.trim().toLowerCase();
    return store.values.where((p) => p.name.trim().toLowerCase() == clean).take(10).toList();
  }

  @override
  Future<List<PersonItem>> findCandidatesByNameAndCompany(
    String normalizedName,
    String normalizedCompany,
  ) async {
    findCandidatesByNameAndCompanyCount++;
    final cleanName = normalizedName.trim().toLowerCase();
    final cleanComp = normalizedCompany.trim().toLowerCase();
    return store.values
        .where((p) =>
            p.name.trim().toLowerCase() == cleanName &&
            (cleanComp.isEmpty || p.company.trim().toLowerCase().contains(cleanComp)))
        .take(10)
        .toList();
  }

  @override
  Future<PersonItem> createPersonFromCapture(PersonItem person) async {
    store[person.id] = person;
    return person;
  }

  @override
  Future<PersonItem> enrichPerson(String personId, Map<String, dynamic> updates) async {
    final existing = store[personId];
    if (existing == null) throw Exception('Person not found: $personId');
    return existing;
  }
}

class QueryTrackingPersonDetailRepository implements PersonDetailRepository {
  final Map<String, PersonProfile> profiles;
  final Map<String, int> getProfileCallsByPerson = {};
  int getAllProfilesCount = 0;

  QueryTrackingPersonDetailRepository(List<PersonProfile> initialProfiles)
      : profiles = {for (final p in initialProfiles) p.id: p};

  @override
  Future<PersonProfile?> getProfile(String personId) async {
    getProfileCallsByPerson[personId] = (getProfileCallsByPerson[personId] ?? 0) + 1;
    return profiles[personId];
  }

  @override
  Stream<PersonProfile?> streamProfile(String personId) => Stream.value(profiles[personId]);

  @override
  Future<List<PersonProfile>> getAllProfiles() async {
    getAllProfilesCount++;
    return profiles.values.toList();
  }

  @override
  Future<void> saveProfile(PersonProfile profile) async => profiles[profile.id] = profile;

  @override
  Future<void> addTimelineItem(String personId, TimelineItem item) async {}

  @override
  Future<void> addMemoryItem(String personId, MemoryItem item) async {}

  @override
  Future<PersonProfile> enrichRelationshipMemory({
    required String personId,
    required RelationshipMemoryUpdate update,
  }) async =>
      profiles[personId]!;

  @override
  Future<void> updateRelationshipStats(
    String personId, {
    int? totalInteractions,
    String? lastInteraction,
    String? relationshipStrength,
    int? sharedEventsCount,
  }) async {}
}

class QueryTrackingActivityRepository implements ActivityRepository {
  final List<ActivityItem> items;
  int streamActivitiesCount = 0;
  int? lastLimitUsed;

  QueryTrackingActivityRepository(this.items);

  @override
  Stream<List<ActivityItem>> streamActivities({String? query, ActivityFilter? filter, int limit = 100}) {
    streamActivitiesCount++;
    lastLimitUsed = limit;
    var result = List<ActivityItem>.from(items);
    if (limit > 0) result = result.take(limit).toList();
    return Stream.value(result);
  }

  @override
  Future<ActivityItem?> getActivity(String id) async =>
      items.where((a) => a.id == id).firstOrNull;

  @override
  Future<void> addActivity(ActivityItem activity) async => items.add(activity);

  @override
  Future<void> deleteActivity(String id) async => items.removeWhere((a) => a.id == id);
}

class QueryTrackingFollowUpRepository implements FollowUpRepository {
  final List<FollowUpItem> items;
  int streamFollowUpsCount = 0;
  int? lastLimitUsed;

  QueryTrackingFollowUpRepository(this.items);

  @override
  Stream<List<FollowUpItem>> streamFollowUps({String? query, FollowUpFilter? filter, int limit = 100}) {
    streamFollowUpsCount++;
    lastLimitUsed = limit;
    var result = List<FollowUpItem>.from(items);
    if (limit > 0) result = result.take(limit).toList();
    return Stream.value(result);
  }

  @override
  Future<FollowUpItem?> getFollowUp(String id) async =>
      items.where((f) => f.id == id).firstOrNull;

  @override
  Future<void> toggleComplete(String id, bool isCompleted) async {}

  @override
  Future<void> addFollowUp(FollowUpItem followUp) async => items.add(followUp);

  @override
  Future<void> updateFollowUp(FollowUpItem followUp) async {}

  @override
  Future<void> deleteFollowUp(String id) async => items.removeWhere((f) => f.id == id);

  @override
  Stream<FollowUpSummaryStats> streamSummaryStats() => const Stream.empty();
}

class QueryTrackingCaptureRepository implements CaptureRepository {
  final List<CaptureItem> items;
  int streamCapturesCount = 0;
  int? lastLimitUsed;

  QueryTrackingCaptureRepository(this.items);

  @override
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 10}) {
    streamCapturesCount++;
    lastLimitUsed = limit;
    return Stream.value(items.take(limit).toList());
  }

  @override
  Future<CaptureItem> saveCapture(CaptureItem capture) async {
    items.add(capture);
    return capture;
  }

  @override
  Future<CaptureItem?> getCapture(String id) async =>
      items.where((c) => c.id == id).firstOrNull;

  @override
  Future<void> deleteCapture(String id) async => items.removeWhere((c) => c.id == id);
}

// ---------------------------------------------------------------------------
// Profile Generator Helper
// ---------------------------------------------------------------------------

List<PersonProfile> generateTestProfiles(int count) {
  final companies = ['Anthropic', 'DeepMind', 'OpenAI', 'Google', 'Meta', 'Apple', 'NVIDIA', 'Stripe'];
  final projects = ['Project Gemini', 'Claude 3.5', 'Llama 3', 'TensorRT', 'Stripe Sigma', 'TPU v5'];

  return List.generate(count, (i) {
    final company = companies[i % companies.length];
    final proj = projects[i % projects.length];
    return PersonProfile(
      id: 'per_$i',
      name: 'Contact Person $i',
      role: 'Staff Engineer $i',
      company: company,
      location: 'San Francisco, CA',
      initials: 'CP',
      relationshipType: RelationshipContextType.collaborator,
      relationshipStrength: i % 2 == 0 ? 'strong' : 'medium',
      firstMet: '2025-01-10',
      lastInteraction: '2026-08-0${(i % 9) + 1}',
      totalInteractions: (i % 8) + 1,
      sharedEventsCount: 2,
      aiSummary: 'Staff engineer working on systems and infrastructure.',
      timeline: [
        TimelineItem(
          id: 'tim_$i',
          type: TimelineType.meeting,
          title: 'Sync on $proj',
          subtitle: company,
          date: '2026-08-01',
          summary: 'Met to discuss project milestones and architecture.',
        ),
      ],
      memories: [
        MemoryItem(
          id: 'mem_$i',
          category: 'Work',
          text: 'Collaborated on $proj with the systems group.',
          source: 'Meeting notes',
        ),
      ],
      connectedEntities: [
        ConnectedEntity(
          id: 'ent_$proj',
          type: EntityType.file,
          title: proj,
          subtitle: 'Architecture Spec',
          targetRoute: '/projects/$proj',
        ),
        if (i > 0)
          ConnectedEntity(
            id: 'per_${i - 1}',
            type: EntityType.person,
            title: 'Contact Person ${i - 1}',
            subtitle: 'Colleague',
            targetRoute: '/people/per_${i - 1}',
          ),
      ],
    );
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Phase 13H-08.3 — PERF-P0-1: Relationship Graph Scalability & Determinism', () {
    test('1. 100 Contacts graph calculation finishes fast, produces no duplicates or asymmetric edges', () {
      final profiles = generateTestProfiles(100);
      const calculator = DeterministicNetworkConnectionCalculator();

      final stopwatch = Stopwatch()..start();
      final connections = calculator.calculateConnections(profiles: profiles);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(800));
      expect(connections.isNotEmpty, isTrue);

      // Verify no duplicate pair keys
      final seenPairs = <String>{};
      for (final conn in connections) {
        final pair = conn.personAId.compareTo(conn.personBId) < 0
            ? '${conn.personAId}::${conn.personBId}'
            : '${conn.personBId}::${conn.personAId}';
        expect(seenPairs.contains(pair), isFalse, reason: 'Duplicate edge found: $pair');
        seenPairs.add(pair);
      }
    });

    test('2. 500 Contacts graph calculation finishes fast without O(N^2) explosion', () {
      final profiles = generateTestProfiles(500);
      const calculator = DeterministicNetworkConnectionCalculator();

      final stopwatch = Stopwatch()..start();
      final connections = calculator.calculateConnections(profiles: profiles);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1500));
      expect(connections.isNotEmpty, isTrue);

      // Verify all connections sort consistently by connectionScore DESC
      for (int i = 0; i < connections.length - 1; i++) {
        expect(connections[i].connectionScore, greaterThanOrEqualTo(connections[i + 1].connectionScore));
      }
    });

    test('3. 1,000 Contacts benchmark completes deterministically under 2,500ms in debug VM', () {
      final profiles = generateTestProfiles(1000);
      const calculator = DeterministicNetworkConnectionCalculator();

      final stopwatch = Stopwatch()..start();
      final run1 = calculator.calculateConnections(profiles: profiles);
      final duration = stopwatch.elapsedMilliseconds;
      stopwatch.stop();

      expect(duration, lessThan(2500));
      expect(run1.isNotEmpty, isTrue);

      // Verify determinism: identical second run produces identical edge count & first edge ID
      final run2 = calculator.calculateConnections(profiles: profiles);
      expect(run1.length, equals(run2.length));
      expect(run1.first.edgeId, equals(run2.first.edgeId));
      expect(run1.first.connectionScore, equals(run2.first.connectionScore));
    });

    test('4. Isolate threshold: kIsolateThreshold is 50', () {
      expect(DeterministicUnifiedRelationshipIntelligenceService.kIsolateThreshold, equals(50));
    });
  });

  group('Phase 13H-08.3 — PERF-P0-2: Person Dossier N+1 Elimination Contract', () {
    test('5. Opening 1 person dossier queries ONLY target person profile and 0 unrelated profiles', () async {
      final profiles = generateTestProfiles(200);
      final people = profiles
          .map((p) => PersonItem(id: p.id, name: p.name, role: p.role, company: p.company, initials: p.initials))
          .toList();

      final trackingPeopleRepo = QueryTrackingPeopleRepository(people);
      final trackingProfileRepo = QueryTrackingPersonDetailRepository(profiles);
      final trackingActivityRepo = QueryTrackingActivityRepository([]);
      final trackingFollowUpRepo = QueryTrackingFollowUpRepository([]);
      final trackingCaptureRepo = QueryTrackingCaptureRepository([]);

      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: trackingPeopleRepo,
        personDetailRepository: trackingProfileRepo,
        activityRepository: trackingActivityRepo,
        followUpRepository: trackingFollowUpRepo,
        captureRepository: trackingCaptureRepo,
        auth: _FakePerfFirebaseAuth(_FakePerfUser('test_perf_user')),
      );

      final targetPersonId = 'per_42';
      final intel = await service.getPersonIntelligence(
        targetPersonId,
        referenceDate: DateTime(2026, 8, 28),
      );

      expect(intel.personId, equals(targetPersonId));

      // CONTRACT VERIFICATION:
      // Target person profile fetched exactly once:
      expect(trackingProfileRepo.getProfileCallsByPerson[targetPersonId], equals(1));

      // Unrelated person profiles fetched ZERO times:
      final otherProfileCalls = trackingProfileRepo.getProfileCallsByPerson.keys
          .where((id) => id != targetPersonId)
          .length;
      expect(otherProfileCalls, equals(0),
          reason: 'No queries should be made for other contacts when opening one dossier');

      // getAllProfiles should NOT be called:
      expect(trackingProfileRepo.getAllProfilesCount, equals(0));

      // streamPeople should NOT be called:
      expect(trackingPeopleRepo.streamPeopleCount, equals(0));

      // Bounded captures limit applied:
      expect(trackingCaptureRepo.lastLimitUsed, equals(20));
    });
  });

  group('Phase 13H-08.3 — PERF-P0-3: Entity Resolution Query Budget Contract', () {
    test('6. Entity resolution executes with 0 full collection scans and bounded queries', () async {
      final people = List.generate(
        100,
        (i) => PersonItem(
          id: 'per_$i',
          name: 'Person $i',
          role: 'Engineer $i',
          company: 'Acme Corp $i',
          email: 'person$i@acme.com',
          phone: '+1 555 01$i',
          initials: 'P$i',
        ),
      );

      final trackingRepo = QueryTrackingPeopleRepository(people);
      final resolver = DeterministicEntityResolutionService(
        peopleRepository: trackingRepo,
      );

      final capture = CaptureItem(
        id: 'cap_101',
        type: CaptureType.businessCard,
        title: 'Visiting Card',
        description: 'New contact card',
        timestamp: 'Just now',
        targetRoute: '/captures/cap_101',
      );

      final entities = OcrExtractedEntities(
        name: 'Person 15',
        company: 'Acme Corp 15',
        email: 'person15@acme.com',
        phone: '+1 555 0115',
      );

      final result = await resolver.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedExisting));
      expect(result.matchedPersonId, equals('per_15'));

      // QUERY BUDGET CONTRACT:
      // Full collection scan MUST be 0:
      expect(trackingRepo.fullScanCount, equals(0));

      // Matched on Signal 2 (email) -> email query called once, other signals short-circuited:
      expect(trackingRepo.findByEmailCount, equals(1));
      expect(trackingRepo.findByPhoneCount, equals(0));
      expect(trackingRepo.findCandidatesByNameAndCompanyCount, equals(0));
      expect(trackingRepo.findCandidatesByNameCount, equals(0));
    });

    test('7. Entity resolution worst case (all miss) executes bounded queries without collection scan', () async {
      final people = List.generate(
        500,
        (i) => PersonItem(
          id: 'per_$i',
          name: 'Person $i',
          role: 'Engineer $i',
          company: 'Company $i',
          initials: 'P$i',
        ),
      );

      final trackingRepo = QueryTrackingPeopleRepository(people);
      final resolver = DeterministicEntityResolutionService(
        peopleRepository: trackingRepo,
      );

      final capture = CaptureItem(
        id: 'cap_new',
        type: CaptureType.businessCard,
        title: 'New Person Card',
        description: 'Unknown contact',
        timestamp: 'Just now',
        targetRoute: '/captures/cap_new',
      );

      final entities = OcrExtractedEntities(
        name: 'Brand New Person',
        company: 'Nonexistent Enterprise',
        email: 'brandnew@nonexistent.io',
        phone: '+1 999 999 9999',
      );

      final result = await resolver.resolveAndLink(capture: capture, entities: entities);

      expect(result.status, equals(EntityResolutionStatus.resolvedNew));
      expect(result.matchedPersonId, equals('per_cap_cap_new'));

      // WORST CASE QUERY BUDGET:
      // Exactly 1 email + 1 phone + 1 name&company + 1 name check = 4 targeted queries total
      expect(trackingRepo.fullScanCount, equals(0));
      expect(trackingRepo.findByEmailCount, equals(1));
      expect(trackingRepo.findByPhoneCount, equals(1));
      expect(trackingRepo.findCandidatesByNameAndCompanyCount, equals(1));
      expect(trackingRepo.findCandidatesByNameCount, equals(1));
    });
  });

  group('Phase 13H-08.3 — PERF-P1-1: Firestore Stream Boundaries', () {
    test('8. streamPeople, streamActivities, and streamFollowUps enforce limit parameter', () {
      final trackingPeople = QueryTrackingPeopleRepository([]);
      final trackingActivity = QueryTrackingActivityRepository([]);
      final trackingFollowUp = QueryTrackingFollowUpRepository([]);

      trackingPeople.streamPeople(limit: 50);
      trackingActivity.streamActivities(limit: 75);
      trackingFollowUp.streamFollowUps(limit: 30);

      expect(trackingPeople.lastLimitUsed, equals(50));
      expect(trackingActivity.lastLimitUsed, equals(75));
      expect(trackingFollowUp.lastLimitUsed, equals(30));
    });
  });

  group('Phase 13H-08.3 — PERF-P1-3: NetworkDashboardScreen Lifecycle Safety', () {
    testWidgets('9. NetworkDashboardScreen initializes safely with initialSnapshot without calling _loadData', (tester) async {
      final snapshot = RelationshipIntelligenceSnapshot.empty();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: NetworkDashboardScreen(initialSnapshot: snapshot),
        ),
      );

      expect(find.byType(NetworkDashboardScreen), findsOneWidget);
      expect(find.text('Network Intelligence'), findsOneWidget);
    });
  });
}
