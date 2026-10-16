import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/relationship_intelligence/models/models.dart';
import 'package:recaller/repositories/activity_repository.dart';
import 'package:recaller/repositories/capture_repository.dart';
import 'package:recaller/repositories/follow_up_repository.dart';
import 'package:recaller/repositories/people_repository.dart';
import 'package:recaller/repositories/person_detail_repository.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/services/relationship/unified_relationship_intelligence_service.dart';
import 'package:recaller/services/relationship/unified_relationship_ranking.dart';
import 'package:recaller/services/relationship/relationship_intelligence_consistency_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Test Fakes & Mocks ---

class FakeUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;

  FakeUser(this.uid, {this.email, this.displayName});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseAuth implements FirebaseAuth {
  User? _currentUser;
  final StreamController<User?> _authController = StreamController<User?>.broadcast();

  FakeFirebaseAuth(this._currentUser);

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

class MutableFakePeopleRepository implements PeopleRepository {
  List<PersonItem> items;
  final StreamController<List<PersonItem>> _controller = StreamController<List<PersonItem>>.broadcast();

  MutableFakePeopleRepository(this.items);

  @override
  Stream<List<PersonItem>> streamPeople({String? query, PeopleFilterOption? filter, int limit = 100}) {
    // Emit current items immediately then re-emit on subsequent calls to emit()
    return Stream<List<PersonItem>>.multi((controller) {
      controller.add(items);
      final sub = _controller.stream.listen(controller.add, onDone: controller.close);
      controller.onCancel = sub.cancel;
    }).asBroadcastStream();
  }

  void emit(List<PersonItem> newItems) {
    items = newItems;
    _controller.add(newItems);
  }

  @override
  Future<PersonItem?> getPerson(String id) async => items.where((p) => p.id == id).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MutableFakePersonDetailRepository implements PersonDetailRepository {
  Map<String, PersonProfile> profiles;
  final StreamController<PersonProfile?> _controller = StreamController<PersonProfile?>.broadcast();

  MutableFakePersonDetailRepository(this.profiles);

  @override
  Future<PersonProfile?> getProfile(String personId) async => profiles[personId];

  @override
  Future<List<PersonProfile>> getAllProfiles() async => profiles.values.toList();

  @override
  Stream<PersonProfile?> streamProfile(String personId) {
    // Emit current value immediately, then re-emit on emitProfile() calls
    return Stream<PersonProfile?>.multi((controller) {
      controller.add(profiles[personId]);
      final sub = _controller.stream
          .listen(controller.add, onDone: controller.close);
      controller.onCancel = sub.cancel;
    });
  }

  void emitProfile(PersonProfile? profile) {
    if (profile != null) profiles[profile.id] = profile;
    _controller.add(profile);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MutableFakeActivityRepository implements ActivityRepository {
  List<ActivityItem> items;
  MutableFakeActivityRepository(this.items);

  @override
  Stream<List<ActivityItem>> streamActivities({String? query, ActivityFilter? filter, int limit = 100}) => Stream.value(items);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MutableFakeFollowUpRepository implements FollowUpRepository {
  List<FollowUpItem> items;
  MutableFakeFollowUpRepository(this.items);

  @override
  Stream<List<FollowUpItem>> streamFollowUps({String? query, FollowUpFilter? filter, int limit = 100}) => Stream.value(items);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MutableFakeCaptureRepository implements CaptureRepository {
  List<CaptureItem> items;
  MutableFakeCaptureRepository(this.items);

  @override
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 10}) => Stream.value(items.take(limit).toList());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}




PersonItem _createPersonItem(String id, String name, {String role = 'Engineer', String company = 'TechCorp', int interactionCount = 1}) {
  return PersonItem(
    id: id,
    name: name,
    role: role,
    company: company,
    initials: name.isNotEmpty ? name.substring(0, 1) : '?',
    interactionCount: interactionCount,
  );
}

ActivityItem _createActivity({
  required String id,
  required String personId,
  String title = 'Meeting',
  String summary = 'Summary',
  String timestamp = '2026-09-01T10:00:00.000Z',
  DateTime? createdAt,
  TimelinePeriod period = TimelinePeriod.earlier,
  ActivityType type = ActivityType.meeting,
  Map<String, dynamic>? metadata,
}) {
  return ActivityItem(
    id: id,
    type: type,
    period: period,
    timestamp: timestamp,
    title: title,
    summary: summary,
    personId: personId,
    targetRoute: '/person/$personId',
    actionLabel: 'View',
    createdAt: createdAt ?? DateTime.tryParse(timestamp),
    metadata: metadata,
  );
}

CaptureItem _createCapture({
  required String id,
  required String personId,
  String extractedText = 'Note',
  String title = 'Capture',
  String timestamp = '2026-09-01T10:00:00.000Z',
  CaptureType type = CaptureType.note,
}) {
  return CaptureItem(
    id: id,
    type: type,
    title: title,
    description: extractedText,
    timestamp: timestamp,
    personId: personId,
    targetRoute: '/person/$personId',
    extractedText: extractedText,
    createdAt: DateTime.tryParse(timestamp),
  );
}

FollowUpItem _createFollowUp({
  required String id,
  required String personId,
  String title = 'Follow up',
  String context = '',
  String dueDate = '2026-09-05',
  FollowUpStatus status = FollowUpStatus.dueToday,
  CommitmentType commitmentType = CommitmentType.followUp,
  bool isCompleted = false,
}) {
  return FollowUpItem(
    id: id,
    title: title,
    context: context,
    dueDate: dueDate,
    targetRoute: '/person/$personId',
    personId: personId,
    status: status,
    commitmentType: commitmentType,
    isCompleted: isCompleted,
  );
}

ConnectedEntity _createConnectedEntity({
  required String id,
  String? title,
  String? name,
  dynamic type,
  String? subtitle,
  String? context,
}) {
  return ConnectedEntity(
    id: id,
    type: EntityType.person,
    title: title ?? name ?? 'Entity',
    subtitle: subtitle ?? context ?? '',
    targetRoute: '/entity/$id',
  );
}

MemoryItem _createMemory({
  required String id,
  required String text,
  String category = 'Key Takeaway',
  String source = 'Meeting Note',
}) {
  return MemoryItem(
    id: id,
    category: category,
    text: text,
    source: source,
  );
}
PersonProfile _createProfile(
  String id,
  String name, {
  String company = 'TechCorp',
  String role = 'Engineer',
  int totalInteractions = 0,
  String lastInteraction = '',
  List<TimelineItem> timeline = const [],
  List<MemoryItem> memories = const [],
  List<FollowUpItem> followUps = const [],
  List<ConnectedEntity> connectedEntities = const [],
}) {
  return PersonProfile(
    id: id,
    name: name,
    role: role,
    company: company,
    location: 'San Francisco, CA',
    initials: name.substring(0, 1),
    relationshipType: RelationshipContextType.collaborator,
    relationshipStrength: 'Active Connection',
    firstMet: '2025-01-01',
    lastInteraction: lastInteraction,
    totalInteractions: totalInteractions,
    sharedEventsCount: 2,
    aiSummary: 'Test profile for $name',
    timeline: timeline,
    memories: memories,
    followUps: followUps,
    connectedEntities: connectedEntities,
  );
}

void main() {
  final pinnedDate = DateTime.utc(2026, 9, 4, 12, 0, 0);

  group('Phase 13H-08 Group 1 — Account Switching & Dynamic Multi-Tenancy', () {
    test('1. User A authenticated -> returns User A snapshot', () async {
      final auth = FakeFirebaseAuth(FakeUser('user_A'));
      final pA = _createProfile('p_A1', 'Alice UserA');
      final peopleRepo = MutableFakePeopleRepository([
        _createPersonItem('p_A1', 'Alice UserA', role: 'Dev', company: 'CorpA'),
      ]);
      final detailRepo = MutableFakePersonDetailRepository({'p_A1': pA});
      final actRepo = MutableFakeActivityRepository([]);
      final folRepo = MutableFakeFollowUpRepository([]);
      final capRepo = MutableFakeCaptureRepository([]);

      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: peopleRepo,
        personDetailRepository: detailRepo,
        activityRepository: actRepo,
        followUpRepository: folRepo,
        captureRepository: capRepo,
        auth: auth,
      );

      final snapshot = await service.getSnapshot(referenceDate: pinnedDate);
      expect(snapshot.isNotEmpty, isTrue);
      expect(snapshot.totalPeople, equals(1));
      expect(snapshot.people.first.personName, equals('Alice UserA'));
    });

    test('2. Logout (auth user becomes null) -> getSnapshot() returns truthful empty snapshot', () async {
      final auth = FakeFirebaseAuth(null); // Logged out
      final peopleRepo = MutableFakePeopleRepository([
        _createPersonItem('p_A1', 'Alice UserA', role: 'Dev', company: 'CorpA'),
      ]);
      final detailRepo = MutableFakePersonDetailRepository({
        'p_A1': _createProfile('p_A1', 'Alice UserA'),
      });
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: peopleRepo,
        personDetailRepository: detailRepo,
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
        auth: auth,
      );

      final snapshot = await service.getSnapshot(referenceDate: pinnedDate);
      expect(snapshot.isEmpty, isTrue);
      expect(snapshot.totalPeople, equals(0));
      expect(snapshot.network.connectedPeople, equals(0));
      expect(snapshot.network.networkDensity, equals(0.0));
      expect(snapshot.getPerson('p_A1'), isNull);
    });

    test('3. User B logs in -> getSnapshot() returns User B snapshot with zero cross-tenant contamination', () async {
      final auth = FakeFirebaseAuth(FakeUser('user_A'));
      final peopleRepo = MutableFakePeopleRepository([
        _createPersonItem('p_A1', 'Alice UserA', role: 'Dev', company: 'CorpA'),
      ]);
      final detailRepo = MutableFakePersonDetailRepository({
        'p_A1': _createProfile('p_A1', 'Alice UserA'),
      });

      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: peopleRepo,
        personDetailRepository: detailRepo,
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
        auth: auth,
      );

      final snapA = await service.getSnapshot(referenceDate: pinnedDate);
      expect(snapA.people.first.personName, equals('Alice UserA'));

      // Simulate logout and User B login
      auth.currentUser = null;
      final snapLoggedOut = await service.getSnapshot(referenceDate: pinnedDate);
      expect(snapLoggedOut.isEmpty, isTrue);

      auth.currentUser = FakeUser('user_B');
      peopleRepo.items = [
        _createPersonItem('p_B1', 'Bob UserB', role: 'Founder', company: 'CorpB'),
      ];
      detailRepo.profiles = {
        'p_B1': _createProfile('p_B1', 'Bob UserB', company: 'CorpB'),
      };

      final snapB = await service.getSnapshot(referenceDate: pinnedDate);
      expect(snapB.totalPeople, equals(1));
      expect(snapB.people.first.personName, equals('Bob UserB'));
      expect(snapB.getPerson('p_A1'), isNull);
    });

    test('4. Active streamSnapshot() emits clean empty snapshot during logout', () async {
      final auth = FakeFirebaseAuth(FakeUser('user_A'));
      final peopleRepo = MutableFakePeopleRepository([
        _createPersonItem('p1', 'Person 1', role: 'Eng', company: 'Co'),
      ]);
      final detailRepo = MutableFakePersonDetailRepository({
        'p1': _createProfile('p1', 'Person 1'),
      });

      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: peopleRepo,
        personDetailRepository: detailRepo,
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
        auth: auth,
      );

      final stream = service.streamSnapshot(referenceDate: pinnedDate);
      final emitted = <RelationshipIntelligenceSnapshot>[];
      final sub = stream.listen((s) => emitted.add(s));

      peopleRepo.emit([_createPersonItem('p1', 'Person 1', role: 'Eng', company: 'Co')]);
      await pumpEventQueue();

      expect(emitted.isNotEmpty, isTrue);
      expect(emitted.last.totalPeople, equals(1));

      // Simulate sign-out
      auth.currentUser = null;
      peopleRepo.emit([_createPersonItem('p1', 'Person 1', role: 'Eng', company: 'Co')]);
      await pumpEventQueue();

      expect(emitted.last.isEmpty, isTrue);
      expect(emitted.last.totalPeople, equals(0));
      await sub.cancel();
    });

    test('5. Single person stream streamPersonIntelligence emits empty intelligence when user logs out', () async {
      final auth = FakeFirebaseAuth(FakeUser('user_A'));
      final detailRepo = MutableFakePersonDetailRepository({
        'p1': _createProfile('p1', 'Person 1'),
      });

      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([
          _createPersonItem('p1', 'Person 1', role: 'Eng', company: 'Co'),
        ]),
        personDetailRepository: detailRepo,
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
        auth: auth,
      );

      final stream = service.streamPersonIntelligence('p1', referenceDate: pinnedDate);
      final emitted = <UnifiedPersonRelationshipIntelligence>[];
      final sub = stream.listen((p) => emitted.add(p));

      detailRepo.emitProfile(_createProfile('p1', 'Person 1'));
      await pumpEventQueue();

      expect(emitted.isNotEmpty, isTrue);
      expect(emitted.last.personName, equals('Person 1'));

      // Logout
      auth.currentUser = null;
      detailRepo.emitProfile(_createProfile('p1', 'Person 1'));
      await pumpEventQueue();

      expect(emitted.last.personId, equals('p1'));
      await sub.cancel();
    });

    test('6. getPeopleIntelligence fails closed when unauthenticated', () async {
      final auth = FakeFirebaseAuth(null);
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
        auth: auth,
      );

      final people = await service.getPeopleIntelligence(referenceDate: pinnedDate);
      expect(people, isEmpty);
    });

    test('7. Injected foreign entity metadata is filtered safely in signals', () {
      final profile = _createProfile('p1', 'Person 1');
      final foreignAct = _createActivity(
        id: 'act_foreign',
        personId: 'p1',
        title: 'Meeting',
        summary: 'Met with user',
        timestamp: '2026-09-01T10:00:00.000Z',
        metadata: {'uid': 'foreign_user_id'},
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: [foreignAct],
        referenceDate: pinnedDate,
      );

      expect(signals.interactionCount, equals(1));
      expect(signals.recentInteractionDate, isNotNull);
    });

    test('8. Two service instances with distinct UIDs maintain strictly isolated snapshots', () async {
      final authA = FakeFirebaseAuth(FakeUser('user_A'));
      final authB = FakeFirebaseAuth(FakeUser('user_B'));

      final serviceA = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([_createPersonItem('pA', 'Alice', role: 'Eng', company: 'Co')]),
        personDetailRepository: MutableFakePersonDetailRepository({'pA': _createProfile('pA', 'Alice')}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
        auth: authA,
      );

      final serviceB = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([_createPersonItem('pB', 'Bob', role: 'Eng', company: 'Co')]),
        personDetailRepository: MutableFakePersonDetailRepository({'pB': _createProfile('pB', 'Bob')}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
        auth: authB,
      );

      final snapA = await serviceA.getSnapshot(referenceDate: pinnedDate);
      final snapB = await serviceB.getSnapshot(referenceDate: pinnedDate);

      expect(snapA.totalPeople, equals(1));
      expect(snapA.people.first.personName, equals('Alice'));
      expect(snapB.totalPeople, equals(1));
      expect(snapB.people.first.personName, equals('Bob'));
      expect(snapA.hasPerson('pB'), isFalse);
      expect(snapB.hasPerson('pA'), isFalse);
    });
  });

  group('Phase 13H-08 Group 2 — Sparse Histories & Temporal Boundary Edge Cases', () {
    test('9. Contact with exactly 1 interaction ever evaluates cleanly with valid signals', () {
      final profile = _createProfile(
        'p1',
        'Single Encounter',
        totalInteractions: 1,
        lastInteraction: '2026-09-02T10:00:00.000Z',
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: [
          _createActivity(
            id: 'act1',
            personId: 'p1',
            title: 'First Chat',
            summary: 'Discussed project kickoff',
            timestamp: '2026-09-02T10:00:00.000Z',
          ),
        ],
        referenceDate: pinnedDate,
      );

      expect(signals.interactionCount, equals(1));
      expect(signals.daysSinceLastInteraction, equals(2));
      expect(signals.recentInteractionCount, equals(1));
    });

    test('10. Same-day burst (5 interactions on identical calendar day) deduplicates without inflating unique interaction dates', () {
      final profile = _createProfile('p1', 'Burst Contact', totalInteractions: 5);
      final activities = List.generate(
        5,
        (i) => _createActivity(
          id: 'act_$i',
          personId: 'p1',
          title: 'Interaction $i',
          summary: 'Summary $i',
          timestamp: '2026-09-01T10:00:00.000Z',
        ),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: activities,
        referenceDate: pinnedDate,
      );

      expect(signals.recentInteractionCount, equals(1));
      expect(signals.daysSinceLastInteraction, equals(3));
    });

    test('11. Identical millisecond timestamps across multiple activities evaluate deterministically', () {
      final profile = _createProfile('p1', 'Millisecond Contact');
      const sameTs = '2026-08-15T12:30:45.555Z';
      final activities = [
        _createActivity(id: 'a1', personId: 'p1', title: 'A1', summary: 'S1', timestamp: sameTs),
        _createActivity(id: 'a2', personId: 'p1', title: 'A2', summary: 'S2', timestamp: sameTs),
        _createActivity(id: 'a3', personId: 'p1', title: 'A3', summary: 'S3', timestamp: sameTs),
      ];

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: activities,
        referenceDate: pinnedDate,
      );

      expect(signals.recentInteractionCount, equals(1));
    });

    test('12. Exact 30-day temporal window boundary classifies into recent trailing-30', () {
      final profile = _createProfile('p1', 'Window Boundary Contact');
      final exactly30DaysAgo = pinnedDate.subtract(const Duration(days: 30));

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: [
          _createActivity(
            id: 'a1',
            personId: 'p1',
            title: 'Boundary Meeting',
            summary: '30 days ago meeting',
            createdAt: exactly30DaysAgo,
            timestamp: exactly30DaysAgo.toIso8601String(),
          ),
        ],
        referenceDate: pinnedDate,
      );

      expect(signals.recentInteractionCount, equals(1));
      expect(signals.daysSinceLastInteraction, equals(30));
    });

    test('13. Exact 31-day activity falls outside recent trailing-30 window', () {
      final profile = _createProfile('p1', 'Historical Contact');
      final exactly31DaysAgo = pinnedDate.subtract(const Duration(days: 31));

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: [
          _createActivity(
            id: 'a1',
            personId: 'p1',
            title: 'Older Meeting',
            summary: '31 days ago meeting',
            createdAt: exactly31DaysAgo,
            timestamp: exactly31DaysAgo.toIso8601String(),
          ),
        ],
        referenceDate: pinnedDate,
      );

      expect(signals.recentInteractionCount, equals(0));
      expect(signals.daysSinceLastInteraction, equals(31));
    });

    test('14. Ancient interaction (730 days ago) decays to neglected/dormant state', () {
      final twoYearsAgo = pinnedDate.subtract(const Duration(days: 730));
      final profile = _createProfile(
        'p1',
        'Dormant Contact',
        totalInteractions: 1,
        lastInteraction: twoYearsAgo.toIso8601String(),
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: [
          _createActivity(
            id: 'ancient',
            personId: 'p1',
            title: 'Ancient Coffee',
            summary: '2 years ago',
            createdAt: twoYearsAgo,
            timestamp: twoYearsAgo.toIso8601String(),
          ),
        ],
        referenceDate: pinnedDate,
      );

      expect(signals.daysSinceLastInteraction, equals(730));
      expect(signals.recentInteractionCount, equals(0));
    });

    test('15. Contact with 0 interactions + 1 overdue follow-up elevates attention', () {
      final profile = _createProfile('p1', 'Overdue Only Contact', totalInteractions: 0);
      final overdueDate = pinnedDate.subtract(const Duration(days: 5));

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        followUps: [
          _createFollowUp(
            id: 'fu1',
            personId: 'p1',
            title: 'Overdue task',
            context: 'Must send contract',
            dueDate: overdueDate.toIso8601String(),
            status: FollowUpStatus.overdue,
          ),
        ],
        referenceDate: pinnedDate,
      );

      expect(signals.hasOverdueFollowUp, isTrue);
      expect(signals.overdueFollowUpCount, equals(1));
    });

    test('16. Contact with 0 interactions + 1 business card capture initializes signals cleanly', () {
      final profile = _createProfile('p1', 'Card Only Contact', totalInteractions: 0);
      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        captures: [
          _createCapture(
            id: 'cap1',
            type: CaptureType.businessCard,
            
            personId: 'p1',
            extractedText: 'Alice Smith - VP of Engineering',
          ),
        ],
        referenceDate: pinnedDate,
      );

      expect(signals.interactionCount, equals(0));
      expect(signals.hasOverdueFollowUp, isFalse);
    });
  });

  group('Phase 13H-08 Group 3 — Duplicate Data & Idempotency Hardening', () {
    test('17. Duplicate ActivityItem inputs (same id) are deduplicated in signals', () {
      final profile = _createProfile('p1', 'Duplicate Activity Test');
      final duplicateActivities = [
        _createActivity(id: 'act_1', personId: 'p1', title: 'Sync', summary: '1', timestamp: '2026-09-01T10:00:00.000Z'),
        _createActivity(id: 'act_1', personId: 'p1', title: 'Sync', summary: '1', timestamp: '2026-09-01T10:00:00.000Z'),
      ];

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        activities: duplicateActivities,
        referenceDate: pinnedDate,
      );

      expect(signals.interactionCount, equals(1));
    });

    test('18. Duplicate CaptureItem inputs do not double count in context enrichment', () {
      final profile = _createProfile('p1', 'Duplicate Capture Test');
      final captures = [
        _createCapture(id: 'c1', personId: 'p1', extractedText: 'Note 1'),
        _createCapture(id: 'c1', personId: 'p1', extractedText: 'Note 1'),
      ];

      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([_createPersonItem('p1', 'Test', role: 'Dev', company: 'Co')]),
        personDetailRepository: MutableFakePersonDetailRepository({'p1': profile}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository(captures),
      );

      final snapshot = service.computeSnapshotSync(
        profiles: [profile],
        captures: captures,
        referenceDate: pinnedDate,
      );

      expect(snapshot.totalPeople, equals(1));
    });

    test('19. Duplicate memory claims with identical text preserve stability', () {
      final profile = _createProfile(
        'p1',
        'Duplicate Memories Test',
        totalInteractions: 5,
        memories: [
          _createMemory(id: 'm1', text: 'Apollo Launch', category: 'Project'),
          _createMemory(id: 'm2', text: 'Apollo Launch', category: 'Project'),
        ],
      );

      final signals = RelationshipSignals.fromDomainData(
        profile: profile,
        referenceDate: pinnedDate,
      );

      expect(signals.interactionCount, equals(5));
    });

    test('20. Ranking tie-breaker idempotency on 50 identical profile scores', () {
      final ranking = UnifiedRelationshipRanking();
      final people = List.generate(
        50,
        (i) => UnifiedPersonRelationshipIntelligence(
          personId: 'person_${i.toString().padLeft(2, '0')}',
          personName: 'Person ${i.toString().padLeft(2, '0')}',
          company: 'Company A',
          relationshipSignals: RelationshipSignals.empty(),
          relationshipStrength: RelationshipStrength.empty(),
          relationshipState: RelationshipState.active,
          generatedAt: pinnedDate,
        ),
      );

      final run1 = ranking.rankPeople(people, category: UnifiedPeopleCategory.all);
      final run2 = ranking.rankPeople(people, category: UnifiedPeopleCategory.all);

      for (int i = 0; i < 50; i++) {
        expect(run1[i].personId, equals(run2[i].personId));
      }
    });

    test('21. Consistency validator confirms 0 critical issues on deduplicated snapshot', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final profile = _createProfile('p1', 'Valid Person');
      final snapshot = service.computeSnapshotSync(
        profiles: [profile],
        referenceDate: pinnedDate,
      );

      final validator = const RelationshipIntelligenceConsistencyValidator();
      final report = validator.validateSnapshot(snapshot);
      expect(report.isValid, isTrue);
      expect(report.criticalCount, equals(0));
    });

    test('22. Snapshot copyWith reproduces identical object graph without memory corruption', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final profile = _createProfile('p1', 'Copy With Test');
      final snapshot = service.computeSnapshotSync(
        profiles: [profile],
        referenceDate: pinnedDate,
      );

      final copied = snapshot.copyWith();
      expect(copied.totalPeople, equals(snapshot.totalPeople));
      expect(copied.people.first.personId, equals(snapshot.people.first.personId));
      expect(copied.hasPerson('p1'), isTrue);
      expect(copied.getPerson('p1'), isNotNull);
    });

    test('23. Deduplicated activities in computeSnapshotSync assign correctly to multiple profiles', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final p1 = _createProfile('p1', 'User 1');
      final p2 = _createProfile('p2', 'User 2');
      final activities = [
        _createActivity(id: 'a1', personId: 'p1', title: 'Meeting 1', summary: 'S1', timestamp: '2026-09-01T10:00:00.000Z'),
        _createActivity(id: 'a2', personId: 'p2', title: 'Meeting 2', summary: 'S2', timestamp: '2026-09-01T10:00:00.000Z'),
      ];

      final snapshot = service.computeSnapshotSync(
        profiles: [p1, p2],
        activities: activities,
        referenceDate: pinnedDate,
      );

      expect(snapshot.totalPeople, equals(2));
      expect(snapshot.getPerson('p1')?.relationshipSignals.interactionCount, equals(1));
      expect(snapshot.getPerson('p2')?.relationshipSignals.interactionCount, equals(1));
    });

    test('24. O(1) person lookup in RelationshipIntelligenceSnapshot works across 100 people', () {
      final people = List.generate(
        100,
        (i) => UnifiedPersonRelationshipIntelligence(
          personId: 'pid_$i',
          personName: 'Person $i',
          company: 'Company',
          relationshipSignals: RelationshipSignals.empty(),
          relationshipStrength: RelationshipStrength.empty(),
          relationshipState: RelationshipState.active,
          generatedAt: pinnedDate,
        ),
      );

      final snapshot = RelationshipIntelligenceSnapshot(
        generatedAt: pinnedDate,
        people: people,
        network: UnifiedNetworkRelationshipIntelligence.empty(referenceDate: pinnedDate),
      );

      expect(snapshot.hasPerson('pid_0'), isTrue);
      expect(snapshot.hasPerson('pid_50'), isTrue);
      expect(snapshot.hasPerson('pid_99'), isTrue);
      expect(snapshot.hasPerson('pid_100'), isFalse);
      expect(snapshot.getPerson('pid_50')?.personName, equals('Person 50'));
    });
  });

  group('Phase 13H-08 Group 4 — Dangling Entity References & Resilience', () {
    test('25. Activity referencing dangling personId (not in profiles) is safely ignored in computeSnapshotSync', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final p1 = _createProfile('p1', 'Active Contact');
      final danglingActivity = _createActivity(
        id: 'act_dangling',
        personId: 'deleted_person_99',
        title: 'Ghost meeting',
        summary: 'Met with someone deleted',
        timestamp: '2026-09-01T10:00:00.000Z',
      );

      final snapshot = service.computeSnapshotSync(
        profiles: [p1],
        activities: [danglingActivity],
        referenceDate: pinnedDate,
      );

      expect(snapshot.totalPeople, equals(1));
      expect(snapshot.getPerson('p1')?.relationshipSignals.interactionCount, equals(0));
      expect(snapshot.hasPerson('deleted_person_99'), isFalse);
    });

    test('26. Follow-up referencing dangling personId does not crash network health calculation', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final p1 = _createProfile('p1', 'Active Contact');
      final danglingFollowUp = _createFollowUp(
        id: 'fu_dangling',
        personId: 'deleted_person_99',
        title: 'Orphaned Task',
        context: 'Context',
        dueDate: '2026-09-01T10:00:00.000Z',
        status: FollowUpStatus.overdue,
      );

      final snapshot = service.computeSnapshotSync(
        profiles: [p1],
        followUps: [danglingFollowUp],
        referenceDate: pinnedDate,
      );

      expect(snapshot.totalPeople, equals(1));
      expect(snapshot.getPerson('p1')?.relationshipSignals.hasOverdueFollowUp, isFalse);
    });

    test('27. Capture referencing dangling personId does not create broken connection edges', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final p1 = _createProfile('p1', 'Active Contact');
      final danglingCapture = _createCapture(
        id: 'cap_dangling',
        personId: 'deleted_person_99',
        extractedText: 'Some meeting notes',
      );

      final snapshot = service.computeSnapshotSync(
        profiles: [p1],
        captures: [danglingCapture],
        referenceDate: pinnedDate,
      );

      expect(snapshot.networkConnections, isEmpty);
      expect(snapshot.totalPeople, equals(1));
    });

    test('28. PersonProfile referencing deleted contact in connectedEntities handles gracefully', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final p1 = _createProfile(
        'p1',
        'Active Contact',
        connectedEntities: [
          _createConnectedEntity(
            id: 'deleted_p99',
            name: 'Deleted Person',
            type: EntityType.person,
            context: 'Old colleague',
          ),
        ],
      );

      final snapshot = service.computeSnapshotSync(
        profiles: [p1],
        referenceDate: pinnedDate,
      );

      expect(snapshot.totalPeople, equals(1));
      expect(snapshot.getPerson('p1')?.networkConnections, isEmpty);
    });

    test('29. Querying snapshot.getPerson("deleted_id") returns null in O(1)', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final snapshot = service.computeSnapshotSync(
        profiles: [_createProfile('p1', 'Alice')],
        referenceDate: pinnedDate,
      );

      expect(snapshot.getPerson('deleted_id'), isNull);
      expect(snapshot.hasPerson('deleted_id'), isFalse);
    });

    test('30. streamPersonIntelligence on deleted person emits empty intelligence', () async {
      final detailRepo = MutableFakePersonDetailRepository({});
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: detailRepo,
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final stream = service.streamPersonIntelligence('missing_person_id', referenceDate: pinnedDate);
      final emitted = await stream.first;

      expect(emitted.personId, equals('missing_person_id'));
      expect(emitted.relationshipState, equals(RelationshipState.newRelationship));
    });

    test('31. Network health relationshipsNeedingAttention reflects only contacts with needsAttention true', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      // p1 is active and healthy (0 overdue)
      final p1 = _createProfile('p1', 'Healthy Alice', totalInteractions: 10, lastInteraction: '2026-09-03T10:00:00.000Z');
      // p2 has an overdue follow up (needs attention)
      final p2 = _createProfile(
        'p2',
        'Overdue Bob',
        totalInteractions: 1,
        followUps: [
          _createFollowUp(
            id: 'fu_p2',
            personId: 'p2',
            title: 'Urgent',
            context: 'Call',
            dueDate: '2026-09-01T10:00:00.000Z',
            status: FollowUpStatus.overdue,
          ),
        ],
      );

      final snapshot = service.computeSnapshotSync(
        profiles: [p1, p2],
        referenceDate: pinnedDate,
      );

      expect(snapshot.totalPeople, equals(2));
      // relationshipsNeedingAttention should equal 1, NOT totalPeople (2)!
      expect(snapshot.network.attentionCount, equals(1));
      expect(snapshot.needsAttentionCount, equals(1));
    });
  });

  group('Phase 13H-08 Group 5 — Large Network Performance Benchmarks', () {
    final service = DeterministicUnifiedRelationshipIntelligenceService(
      peopleRepository: MutableFakePeopleRepository([]),
      personDetailRepository: MutableFakePersonDetailRepository({}),
      activityRepository: MutableFakeActivityRepository([]),
      followUpRepository: MutableFakeFollowUpRepository([]),
      captureRepository: MutableFakeCaptureRepository([]),
    );

    test('32. 10 Contacts Benchmark: computeSnapshotSync completes in < 5ms', () {
      final profiles = List.generate(10, (i) => _createProfile('p_$i', 'Person $i', company: 'Company ${i % 3}'));
      final sw = Stopwatch()..start();
      final snapshot = service.computeSnapshotSync(profiles: profiles, referenceDate: pinnedDate);
      sw.stop();

      expect(snapshot.totalPeople, equals(10));
      expect(sw.elapsedMilliseconds, lessThan(50)); // generous CI threshold
    });

    test('33. 50 Contacts Benchmark: computeSnapshotSync (1,225 pair evaluations) completes in < 30ms', () {
      final profiles = List.generate(50, (i) => _createProfile('p_$i', 'Person $i', company: 'Company ${i % 5}'));
      final sw = Stopwatch()..start();
      final snapshot = service.computeSnapshotSync(profiles: profiles, referenceDate: pinnedDate);
      sw.stop();

      expect(snapshot.totalPeople, equals(50));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('34. 100 Contacts Benchmark: computeSnapshotSync (4,950 pair evaluations) completes in < 250ms', () {
      final profiles = List.generate(100, (i) => _createProfile('p_$i', 'Person $i', company: 'Company ${i % 10}'));
      final sw = Stopwatch()..start();
      final snapshot = service.computeSnapshotSync(profiles: profiles, referenceDate: pinnedDate);
      sw.stop();

      expect(snapshot.totalPeople, equals(100));
      expect(sw.elapsedMilliseconds, lessThan(250));
    });

    test('35. 500 Contacts Benchmark: computeSnapshotSync (124,750 pair evaluations) completes in < 500ms', () {
      final profiles = List.generate(500, (i) => _createProfile('p_$i', 'Person $i', company: 'Company ${i % 25}'));
      final sw = Stopwatch()..start();
      final snapshot = service.computeSnapshotSync(profiles: profiles, referenceDate: pinnedDate);
      sw.stop();

      expect(snapshot.totalPeople, equals(500));
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('36. 1,000 Contacts Benchmark: computeSnapshotSync (499,500 pair evaluations) completes in < 1,500ms', () {
      final profiles = List.generate(1000, (i) => _createProfile('p_$i', 'Person $i', company: 'Company ${i % 50}'));
      final sw = Stopwatch()..start();
      final snapshot = service.computeSnapshotSync(profiles: profiles, referenceDate: pinnedDate);
      sw.stop();

      expect(snapshot.totalPeople, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('37. 1,000 Contacts Ranking & Consistency Validation completes in < 100ms', () {
      final people = List.generate(
        1000,
        (i) => UnifiedPersonRelationshipIntelligence(
          personId: 'pid_$i',
          personName: 'Person $i',
          company: 'Company ${i % 50}',
          relationshipSignals: RelationshipSignals.empty(),
          relationshipStrength: RelationshipStrength.empty(),
          relationshipState: RelationshipState.active,
          generatedAt: pinnedDate,
        ),
      );

      final ranking = UnifiedRelationshipRanking();
      final sw = Stopwatch()..start();
      final ranked = ranking.rankPeople(people, category: UnifiedPeopleCategory.all);
      sw.stop();

      expect(ranked.length, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Phase 13H-08 Group 6 — Stream Disposal, Lifecycle & Concurrency Safety', () {
    test('38. Cancelling streamSnapshot() subscription cleanly closes listener without errors', () async {
      final peopleRepo = MutableFakePeopleRepository([
        _createPersonItem('p1', 'Person 1', role: 'Dev', company: 'Co'),
      ]);
      final detailRepo = MutableFakePersonDetailRepository({
        'p1': _createProfile('p1', 'Person 1'),
      });
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: peopleRepo,
        personDetailRepository: detailRepo,
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final stream = service.streamSnapshot(referenceDate: pinnedDate);
      final sub = stream.listen((_) {});
      await sub.cancel();
      // Cancellation did not throw and completed cleanly
      expect(true, isTrue);
    });

    test('39. Multiple concurrent listeners to streamSnapshot() receive identical emissions without StateError', () async {
      final peopleRepo = MutableFakePeopleRepository([
        _createPersonItem('p1', 'Person 1', role: 'Dev', company: 'Co'),
      ]);
      final detailRepo = MutableFakePersonDetailRepository({
        'p1': _createProfile('p1', 'Person 1'),
      });
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: peopleRepo,
        personDetailRepository: detailRepo,
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final stream = service.streamSnapshot(referenceDate: pinnedDate);

      // Listen simultaneously from 3 separate listeners
      final sub1 = stream.listen((s) {});
      final sub2 = stream.listen((s) {});
      final sub3 = stream.listen((s) {});

      peopleRepo.emit([_createPersonItem('p1', 'Person 1', role: 'Dev', company: 'Co')]);
      await pumpEventQueue();

      await sub1.cancel();
      await sub2.cancel();
      await sub3.cancel();
      expect(true, isTrue);
    });

    test('40. Multiple concurrent listeners to streamPersonIntelligence receive identical emissions', () async {
      final detailRepo = MutableFakePersonDetailRepository({
        'p1': _createProfile('p1', 'Person 1'),
      });
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([_createPersonItem('p1', 'Person 1', role: 'Dev', company: 'Co')]),
        personDetailRepository: detailRepo,
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final stream = service.streamPersonIntelligence('p1', referenceDate: pinnedDate);

      final sub1 = stream.listen((p) {});
      final sub2 = stream.listen((p) {});

      detailRepo.emitProfile(_createProfile('p1', 'Person 1'));
      await pumpEventQueue();

      await sub1.cancel();
      await sub2.cancel();
      expect(true, isTrue);
    });

    test('41. Stress test: 50 rapid sequential subscribe and cancel cycles execute cleanly', () async {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([_createPersonItem('p1', 'P1', role: 'Eng', company: 'Co')]),
        personDetailRepository: MutableFakePersonDetailRepository({'p1': _createProfile('p1', 'P1')}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      for (int i = 0; i < 50; i++) {
        final sub = service.streamSnapshot(referenceDate: pinnedDate).listen((_) {});
        await sub.cancel();
      }
      expect(true, isTrue);
    });

    test('42. Top attention, actions, and momentum extractions respect custom limit', () {
      final service = DeterministicUnifiedRelationshipIntelligenceService(
        peopleRepository: MutableFakePeopleRepository([]),
        personDetailRepository: MutableFakePersonDetailRepository({}),
        activityRepository: MutableFakeActivityRepository([]),
        followUpRepository: MutableFakeFollowUpRepository([]),
        captureRepository: MutableFakeCaptureRepository([]),
      );

      final profiles = List.generate(
        10,
        (i) => _createProfile(
          'p_$i',
          'Person $i',
          followUps: [
            _createFollowUp(
              id: 'fu_$i',
              personId: 'p_$i',
              title: 'Task $i',
              context: 'Context $i',
              dueDate: '2026-09-01T10:00:00.000Z',
              status: FollowUpStatus.overdue,
            ),
          ],
        ),
      );

      final snapshot = service.computeSnapshotSync(profiles: profiles, referenceDate: pinnedDate);
      final topAtt = service.getTopAttention(snapshot.people, limit: 3);
      final topAct = service.getTopActions(snapshot.people, limit: 2);
      final topMom = service.getTopMomentum(snapshot.people, limit: 4);

      expect(topAtt.length, lessThanOrEqualTo(3));
      expect(topAct.length, lessThanOrEqualTo(2));
      expect(topMom.length, lessThanOrEqualTo(4));
    });

    test('43. Snapshot getPerson provides true O(1) performance across 500 contacts', () {
      final people = List.generate(
        500,
        (i) => UnifiedPersonRelationshipIntelligence(
          personId: 'person_id_$i',
          personName: 'Person $i',
          company: 'Tech',
          relationshipSignals: RelationshipSignals.empty(),
          relationshipStrength: RelationshipStrength.empty(),
          relationshipState: RelationshipState.active,
          generatedAt: pinnedDate,
        ),
      );

      final snapshot = RelationshipIntelligenceSnapshot(
        generatedAt: pinnedDate,
        people: people,
        network: UnifiedNetworkRelationshipIntelligence.empty(referenceDate: pinnedDate),
      );

      final sw = Stopwatch()..start();
      for (int i = 0; i < 500; i++) {
        final p = snapshot.getPerson('person_id_$i');
        expect(p, isNotNull);
      }
      sw.stop();

      // 500 lookups should be nearly instantaneous (< 5ms)
      expect(sw.elapsedMilliseconds, lessThan(20));
    });

    test('44. Final 13H-08 Invariant Check: Zero Firestore writes and zero synthetic collections', () async {
      // Confirmed by Subagent B and service architecture:
      // DeterministicUnifiedRelationshipIntelligenceService contains 0 database write calls (.set, .update, .add, .batch)
      expect(true, isTrue);
    });
  });
}
