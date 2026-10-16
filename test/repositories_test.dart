import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/data/data.dart';

void main() {
  group('Phase 13B: Error Architecture & Security Scoping Tests', () {
    test('1. RecallrDataException maps unauthenticated correctly', () {
      final ex = RecallrDataException.unauthenticated();
      expect(ex.type, equals(DataErrorType.unauthenticated));
      expect(ex.message, contains('signed in'));
    });

    test('2. RecallrDataException maps permission denied from exception', () {
      final ex = RecallrDataException.fromException('PERMISSION-DENIED: Missing rules permission');
      expect(ex.type, equals(DataErrorType.permissionDenied));
      expect(ex.message, contains('permission'));
    });

    test('3. RecallrDataException maps network error from exception', () {
      final ex = RecallrDataException.fromException('SocketException: network timeout unavailable');
      expect(ex.type, equals(DataErrorType.networkUnavailable));
    });

    test('4. RecallrDataException maps not found from exception', () {
      final ex = RecallrDataException.notFound('Person', 'per_999');
      expect(ex.type, equals(DataErrorType.notFound));
      expect(ex.message, equals('Person (per_999) not found.'));
    });

    test('5. Firestore repositories throw unauthenticated exception when auth is null', () async {
      // Mock unauthenticated state
      final peopleRepo = FirestorePeopleRepository();
      expect(() => peopleRepo.streamPeople(), throwsA(isA<RecallrDataException>()));

      final detailRepo = FirestorePersonDetailRepository();
      expect(() => detailRepo.getProfile('per_301'), throwsA(isA<RecallrDataException>()));

      final activityRepo = FirestoreActivityRepository();
      expect(() => activityRepo.streamActivities(), throwsA(isA<RecallrDataException>()));

      final followUpRepo = FirestoreFollowUpRepository();
      expect(() => followUpRepo.streamFollowUps(), throwsA(isA<RecallrDataException>()));

      final captureRepo = FirestoreCaptureRepository();
      expect(() => captureRepo.streamRecentCaptures(), throwsA(isA<RecallrDataException>()));
    });
  });

  group('Phase 13B: Canonical Domain Models & Serializers', () {
    test('6. PersonItem serializes to and from Map', () {
      const person = PersonItem(
        id: 'per_301',
        name: 'Priya Sharma',
        role: 'Principal Architect',
        company: 'Microsoft',
        locationOrEvent: 'Hyderabad',
        initials: 'PS',
        capabilities: ['RISC-V', 'Embedded AI'],
        hasPendingFollowUp: true,
        interactionCount: 5,
        relationshipType: RelationshipContextType.collaborator,
      );

      final map = person.toMap();
      expect(map['id'], equals('per_301'));
      expect(map['name'], equals('Priya Sharma'));
      expect(map['relationshipType'], equals('collaborator'));

      final restored = PersonItem.fromMap(map);
      expect(restored.id, equals(person.id));
      expect(restored.name, equals(person.name));
      expect(restored.role, equals(person.role));
      expect(restored.capabilities, equals(person.capabilities));
      expect(restored.relationshipType, equals(RelationshipContextType.collaborator));
    });

    test('7. FollowUpItem canonical model serializes and matches CommitmentType', () {
      const followUp = FollowUpItem(
        id: 'fol_101',
        title: 'Send API specs to Arjun',
        context: 'Follow up from Coffee sync',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        priority: FollowUpPriority.high,
        dueDate: 'Due Today',
        createdDate: 'Yesterday',
        personId: 'per_303',
        personName: 'Arjun Mehta',
        companyName: 'Nexus Venture Partners',
        targetRoute: '/follow-up/fol_101',
        isCompleted: false,
      );

      expect(followUp.isIPromised, isTrue);
      expect(followUp.isTheyPromised, isFalse);

      final map = followUp.toMap();
      expect(map['commitmentType'], equals('iPromised'));
      expect(map['status'], equals('dueToday'));

      final restored = FollowUpItem.fromMap(map);
      expect(restored.id, equals('fol_101'));
      expect(restored.isIPromised, isTrue);
      expect(restored.title, equals(followUp.title));
      expect(restored.personName, equals('Arjun Mehta'));
    });

    test('8. PersonProfile embeds canonical FollowUpItem with CommitmentType', () {
      const profile = PersonProfile(
        id: 'per_301',
        name: 'Priya Sharma',
        role: 'Principal Architect',
        company: 'Microsoft',
        location: 'Hyderabad',
        initials: 'PS',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'High Trust',
        firstMet: 'Hyderabad Tech Summit',
        lastInteraction: 'Yesterday',
        totalInteractions: 3,
        sharedEventsCount: 1,
        aiSummary: 'Leading edge SLM optimization.',
        keyTakeaways: ['Key collaborator'],
        capabilities: ['RISC-V', 'LLVM'],
        timeline: [
          TimelineItem(
            id: 'int_101',
            type: TimelineType.meeting,
            title: '1:1 Sync',
            subtitle: 'Discussed quantization',
            date: 'Yesterday',
            summary: 'Good sync',
          ),
        ],
        memories: [
          MemoryItem(
            id: 'mem_1',
            category: 'Technical',
            text: 'Specializes in SLMs',
            source: 'Summit',
          ),
        ],
        followUps: [
          FollowUpItem(
            id: 'fol_103',
            title: 'Check with Priya about RISC-V',
            commitmentType: CommitmentType.iPromised,
            dueDate: 'Due Tomorrow',
            targetRoute: '/follow-up/fol_103',
          ),
        ],
        connectedEntities: [
          ConnectedEntity(
            id: 'cmp_microsoft',
            type: EntityType.company,
            title: 'Microsoft',
            subtitle: 'Principal Architect',
            targetRoute: '/company/cmp_microsoft',
          ),
        ],
        promptSuggestions: ['What did Priya say about RISC-V?'],
      );

      final map = profile.toMap();
      expect(map['id'], equals('per_301'));
      expect(map['timeline'], hasLength(1));
      expect(map['memories'], hasLength(1));
      expect(map['followUps'], hasLength(1));
      expect(map['connectedEntities'], hasLength(1));

      final restored = PersonProfile.fromMap(map);
      expect(restored.id, equals('per_301'));
      expect(restored.followUps.first.isIPromised, isTrue);
      expect(restored.followUps.first.title, equals('Check with Priya about RISC-V'));
      expect(restored.timeline.first.type, equals(TimelineType.meeting));
      expect(restored.connectedEntities.first.type, equals(EntityType.company));
    });

    test('9. ActivityItem serializes to and from Map', () {
      const activity = ActivityItem(
        id: 'act_101',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: '10:30 AM',
        title: 'Meeting with Priya Sharma',
        summary: 'Reviewed RISC-V benchmark numbers',
        personId: 'per_301',
        personName: 'Priya Sharma',
        companyName: 'Microsoft',
        targetRoute: '/interaction/int_101',
        actionLabel: 'View Meeting',
        isVerified: true,
      );

      final map = activity.toMap();
      expect(map['type'], equals('meeting'));
      expect(map['period'], equals('today'));

      final restored = ActivityItem.fromMap(map);
      expect(restored.id, equals('act_101'));
      expect(restored.type, equals(ActivityType.meeting));
      expect(restored.period, equals(TimelinePeriod.today));
      expect(restored.title, equals(activity.title));
    });

    test('10. CaptureItem and CaptureReviewData serialize to and from Map', () {
      const review = CaptureReviewData(
        title: 'Arjun Mehta Business Card',
        summary: 'Partner at Nexus Venture Partners',
        personName: 'Arjun Mehta',
        companyName: 'Nexus Venture Partners',
        bulletPoints: ['Focuses on AI infrastructure'],
      );

      final reviewMap = review.toMap();
      expect(reviewMap['personName'], equals('Arjun Mehta'));
      final restoredReview = CaptureReviewData.fromMap(reviewMap);
      expect(restoredReview.personName, equals('Arjun Mehta'));

      const capture = CaptureItem(
        id: 'cap_101',
        type: CaptureType.businessCard,
        title: 'Visiting card scan',
        description: 'Scanned at Nexus office',
        timestamp: 'Just now',
        personId: 'per_303',
        personName: 'Arjun Mehta',
        companyName: 'Nexus Venture Partners',
        targetRoute: '/interaction/int_101',
        isVerified: true,
      );

      final captureMap = capture.toMap();
      expect(captureMap['type'], equals('businessCard'));
      final restoredCapture = CaptureItem.fromMap(captureMap);
      expect(restoredCapture.id, equals('cap_101'));
      expect(restoredCapture.type, equals(CaptureType.businessCard));
    });
  });

  group('Phase 13B: Mock Repository Implementations', () {
    test('11. MockPeopleRepository streams and filters people correctly', () async {
      final repo = MockPeopleRepository();
      final all = await repo.streamPeople().first;
      expect(all.isNotEmpty, isTrue);

      final filteredByQuery = await repo.streamPeople(query: 'Priya').first;
      expect(filteredByQuery, hasLength(1));
      expect(filteredByQuery.first.name, equals('Priya Sharma'));

      final founders = await repo.streamPeople(filter: PeopleFilterOption.founders).first;
      expect(founders.any((p) => p.name == 'Vivek Raghavan'), isTrue);

      final recents = await repo.streamRecentlyInteracted().first;
      expect(recents.length, lessThanOrEqualTo(5));
    });

    test('12. MockPeopleRepository supports CRUD operations', () async {
      final repo = MockPeopleRepository(initialPeople: []);
      const newPerson = PersonItem(
        id: 'per_test',
        name: 'Test Engineer',
        role: 'Staff Engineer',
        company: 'Recallr AI',
        initials: 'TE',
      );

      await repo.addPerson(newPerson);
      var fetched = await repo.getPerson('per_test');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Test Engineer'));

      final updated = newPerson.copyWith(role: 'Principal Engineer');
      await repo.updatePerson(updated);
      fetched = await repo.getPerson('per_test');
      expect(fetched!.role, equals('Principal Engineer'));

      await repo.deletePerson('per_test');
      fetched = await repo.getPerson('per_test');
      expect(fetched, isNull);
    });

    test('13. MockPersonDetailRepository saves and retrieves 360 dossiers', () async {
      final repo = MockPersonDetailRepository();
      final profile = await repo.getProfile('per_301');
      expect(profile, isNotNull);
      expect(profile!.name, equals('Priya Sharma'));

      const newTimeline = TimelineItem(
        id: 'int_new',
        type: TimelineType.voiceNote,
        title: 'New Voice Memo',
        subtitle: 'Architecture sync',
        date: 'Today',
        summary: 'Recorded thoughts',
      );
      await repo.addTimelineItem('per_301', newTimeline);
      final updated = await repo.getProfile('per_301');
      expect(updated!.timeline.any((t) => t.id == 'int_new'), isTrue);
    });

    test('14. MockActivityRepository filters and manages activities', () async {
      final repo = MockActivityRepository();
      final activities = await repo.streamActivities().first;
      expect(activities.isNotEmpty, isTrue);

      final meetings = await repo.streamActivities(filter: ActivityFilter.meetings).first;
      expect(meetings.every((a) => a.type == ActivityType.meeting), isTrue);

      const newAct = ActivityItem(
        id: 'act_new',
        type: ActivityType.call,
        period: TimelinePeriod.today,
        timestamp: '11:00 AM',
        title: 'Call with Founder',
        summary: 'Investment discussion',
        targetRoute: '/activity',
        actionLabel: 'View',
      );
      await repo.addActivity(newAct);
      final fetched = await repo.getActivity('act_new');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Call with Founder'));
    });

    test('15. MockFollowUpRepository updates status and computes summary stats', () async {
      final repo = MockFollowUpRepository();
      final followUps = await repo.streamFollowUps().first;
      expect(followUps.isNotEmpty, isTrue);

      final statsBefore = await repo.streamSummaryStats().first;
      expect(statsBefore.totalActive, greaterThan(0));

      final firstItem = followUps.first;
      await repo.toggleComplete(firstItem.id, true);

      final updated = await repo.getFollowUp(firstItem.id);
      expect(updated!.isCompleted, isTrue);
      expect(updated.status, equals(FollowUpStatus.completed));
    });

    test('16. MockCaptureRepository saves and streams recent captures', () async {
      final repo = MockCaptureRepository(initialCaptures: []);
      const capture = CaptureItem(
        id: 'cap_new',
        type: CaptureType.note,
        title: 'Quick note from summit',
        description: 'Met potential advisor',
        timestamp: 'Just now',
        targetRoute: '/activity',
      );

      final saved = await repo.saveCapture(capture);
      expect(saved.id, equals('cap_new'));

      final recents = await repo.streamRecentCaptures().first;
      expect(recents, hasLength(1));
      expect(recents.first.title, equals('Quick note from summit'));
    });
  });
}