import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/repositories/activity_repository.dart';
import 'package:recaller/screens/activity/activity_screen.dart';

/// Fake implementation of ActivityRepository to test real-time streaming, filtering, and CRUD state transitions.
class FakeFirestoreActivityRepository implements ActivityRepository {
  final Map<String, ActivityItem> _store = {};
  final StreamController<List<ActivityItem>> _streamController = StreamController<List<ActivityItem>>.broadcast();
  bool shouldThrowUnauthenticated = false;
  bool shouldThrowError = false;

  FakeFirestoreActivityRepository({List<ActivityItem>? initialData}) {
    if (initialData != null) {
      for (final a in initialData) {
        _store[a.id] = a;
      }
    }
  }

  @override
  Stream<List<ActivityItem>> streamActivities({String? query, ActivityFilter? filter, int limit = 100}) {
    if (shouldThrowUnauthenticated) return Stream.error(RecallrDataException.unauthenticated());
    if (shouldThrowError) return Stream.error(RecallrDataException.networkUnavailable());

    var result = _store.values.toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((a) {
        final matchesTitle = a.title.toLowerCase().contains(q);
        final matchesSummary = a.summary.toLowerCase().contains(q);
        final matchesPerson = a.personName?.toLowerCase().contains(q) ?? false;
        final matchesCompany = a.companyName?.toLowerCase().contains(q) ?? false;
        return matchesTitle || matchesSummary || matchesPerson || matchesCompany;
      }).toList();
    }
    if (filter != null && filter != ActivityFilter.all) {
      result = result.where((a) => filter.matches(a.type)).toList();
    }

    return Stream.value(result);
  }

  @override
  Future<ActivityItem?> getActivity(String id) async {
    if (shouldThrowUnauthenticated) throw RecallrDataException.unauthenticated();
    if (shouldThrowError) throw RecallrDataException.networkUnavailable();
    return _store[id];
  }

  @override
  Future<void> addActivity(ActivityItem activity) async {
    final newActivity = activity.copyWith(
      id: activity.id.isNotEmpty ? activity.id : 'act_gen_${_store.length + 1}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store[newActivity.id] = newActivity;
    _streamController.add(_store.values.toList());
  }

  @override
  Future<void> deleteActivity(String id) async {
    _store.remove(id);
    _streamController.add(_store.values.toList());
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('Phase 13C-04: Activity Domain Models & Serialization Tests', () {
    test('1. ActivityItem serializes and deserializes all Firestore fields accurately', () {
      final now = DateTime(2026, 8, 28, 10, 30);
      final activity = ActivityItem(
        id: 'act_101',
        type: ActivityType.encounter,
        period: TimelinePeriod.today,
        timestamp: '10:45 AM',
        title: 'Met with Dr. Priya Sharma',
        summary: 'Met at India AI Summit to discuss quantization for Indic SLMs.',
        personId: 'per_301',
        personName: 'Dr. Priya Sharma',
        personRole: 'Principal Architect',
        companyId: 'comp_msr',
        companyName: 'Microsoft Research India',
        location: 'Bengaluru Convention Center',
        relationshipIndicator: 'New Connection · High Intent',
        followUpStatus: 'Follow-up Due: Tomorrow',
        targetRoute: '/person/per_301',
        actionLabel: 'View Dossier',
        isVerified: true,
        metadata: const {'event': 'India AI Summit 2024', 'badgeScanned': true},
        userId: 'usr_auth_456',
        createdAt: now,
        updatedAt: now,
      );

      final map = activity.toMap();
      expect(map['id'], equals('act_101'));
      expect(map['type'], equals('encounter'));
      expect(map['period'], equals('today'));
      expect(map['personName'], equals('Dr. Priya Sharma'));
      expect(map['companyName'], equals('Microsoft Research India'));
      expect(map['userId'], equals('usr_auth_456'));
      expect(map['isVerified'], isTrue);

      final restored = ActivityItem.fromMap(map, 'act_101');
      expect(restored.id, equals('act_101'));
      expect(restored.type, equals(ActivityType.encounter));
      expect(restored.period, equals(TimelinePeriod.today));
      expect(restored.title, equals(activity.title));
      expect(restored.personName, equals('Dr. Priya Sharma'));
      expect(restored.companyName, equals('Microsoft Research India'));
      expect(restored.userId, equals('usr_auth_456'));
      expect(restored.metadata?['badgeScanned'], isTrue);
    });

    test('2. ActivityItem safely handles missing and optional fields', () {
      final minimalMap = {
        'id': 'act_min',
        'type': 'note',
        'period': 'yesterday',
        'timestamp': 'Yesterday',
        'title': 'Brief reflection on ONNX runtime',
        'summary': 'Quantization benchmarks look promising.',
      };

      final activity = ActivityItem.fromMap(minimalMap);
      expect(activity.id, equals('act_min'));
      expect(activity.type, equals(ActivityType.note));
      expect(activity.period, equals(TimelinePeriod.yesterday));
      expect(activity.title, equals('Brief reflection on ONNX runtime'));
      expect(activity.personName, isNull);
      expect(activity.companyName, isNull);
      expect(activity.isVerified, isTrue);
      expect(activity.targetRoute, equals('/activity'));
    });
  });

  group('Phase 13C-04: Activity Repository Live State & UI Tests', () {
    late FakeFirestoreActivityRepository fakeRepo;
    final testActivity1 = const ActivityItem(
      id: 'act_101',
      type: ActivityType.encounter,
      period: TimelinePeriod.today,
      timestamp: '10:45 AM',
      title: 'Met with Dr. Priya Sharma',
      summary: 'Met at India AI Summit to discuss quantization for Indic SLMs.',
      personId: 'per_301',
      personName: 'Dr. Priya Sharma',
      personRole: 'Principal Architect',
      companyId: 'comp_msr',
      companyName: 'Microsoft Research India',
      targetRoute: '/person/per_301',
      actionLabel: 'View Dossier',
    );

    final testActivity2 = const ActivityItem(
      id: 'act_102',
      type: ActivityType.call,
      period: TimelinePeriod.yesterday,
      timestamp: 'Yesterday · 4:00 PM',
      title: 'Sync with Vivek Raghavan',
      summary: 'Reviewed Indic SLM speech dataset collection progress.',
      personId: 'per_302',
      personName: 'Vivek Raghavan',
      personRole: 'Chief AI Architect',
      companyId: 'comp_sarvam',
      companyName: 'Sarvam AI',
      targetRoute: '/person/per_302',
      actionLabel: 'View Dossier',
    );

    setUp(() {
      fakeRepo = FakeFirestoreActivityRepository(initialData: [testActivity1, testActivity2]);
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    test('3. Repository supports CRUD operations and streaming', () async {
      final initialList = await fakeRepo.streamActivities().first;
      expect(initialList, hasLength(2));

      // Add activity
      const newActivity = ActivityItem(
        id: 'act_103',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: '2:00 PM',
        title: 'Discussion with Arjun Mehta',
        summary: 'Deep dive into seed fund term sheet.',
        targetRoute: '/activity',
        actionLabel: 'View',
      );
      await fakeRepo.addActivity(newActivity);

      var fetched = await fakeRepo.getActivity('act_103');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Discussion with Arjun Mehta'));

      // Delete activity
      await fakeRepo.deleteActivity('act_103');
      fetched = await fakeRepo.getActivity('act_103');
      expect(fetched, isNull);
    });

    test('4. Repository filters by search query and activity category', () async {
      final searchResult = await fakeRepo.streamActivities(query: 'Priya').first;
      expect(searchResult, hasLength(1));
      expect(searchResult.first.id, equals('act_101'));

      final callsResult = await fakeRepo.streamActivities(filter: ActivityFilter.calls).first;
      expect(callsResult, hasLength(1));
      expect(callsResult.first.id, equals('act_102'));
    });

    testWidgets('5. ActivityScreen renders live activities from injected repository', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityScreen(
              repository: fakeRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Met with Dr. Priya Sharma'), findsWidgets);
      expect(find.text('Sync with Vivek Raghavan'), findsWidgets);
      expect(find.textContaining('Microsoft Research India'), findsWidgets);
      expect(find.textContaining('Sarvam AI'), findsWidgets);
    });

    testWidgets('6. ActivityScreen handles repository error gracefully with retry option', (tester) async {
      final errorRepo = FakeFirestoreActivityRepository(initialData: [testActivity1])..shouldThrowError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityScreen(
              repository: errorRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("couldn't load your activity"), findsOneWidget);

      // Fix error and retry
      errorRepo.shouldThrowError = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Met with Dr. Priya Sharma'), findsWidgets);
    });
  });
}