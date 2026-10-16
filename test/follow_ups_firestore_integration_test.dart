import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/repositories/follow_up_repository.dart';
import 'package:recaller/screens/follow_ups/follow_ups_screen.dart';

/// Fake implementation of FollowUpRepository to test streaming, stats, completion toggle, and optimistic rollback.
class FakeFirestoreFollowUpRepository implements FollowUpRepository {
  final Map<String, FollowUpItem> _store = {};
  final StreamController<List<FollowUpItem>> _streamController = StreamController<List<FollowUpItem>>.broadcast();
  bool shouldThrowUnauthenticated = false;
  bool shouldThrowError = false;
  bool shouldFailToggle = false;

  FakeFirestoreFollowUpRepository({List<FollowUpItem>? initialData}) {
    if (initialData != null) {
      for (final item in initialData) {
        _store[item.id] = item;
      }
    }
  }

  @override
  Stream<List<FollowUpItem>> streamFollowUps({String? query, FollowUpFilter? filter, int limit = 100}) {
    if (shouldThrowUnauthenticated) return Stream.error(RecallrDataException.unauthenticated());
    if (shouldThrowError) return Stream.error(RecallrDataException.networkUnavailable());

    var result = _store.values.toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((f) {
        final matchesTitle = f.title.toLowerCase().contains(q);
        final matchesContext = f.context.toLowerCase().contains(q);
        final matchesPerson = f.personName?.toLowerCase().contains(q) ?? false;
        final matchesCompany = f.companyName?.toLowerCase().contains(q) ?? false;
        return matchesTitle || matchesContext || matchesPerson || matchesCompany;
      }).toList();
    }

    if (filter != null && filter != FollowUpFilter.all) {
      result = result.where((f) => filter.matches(f)).toList();
    }

    return Stream.value(result);
  }

  @override
  Future<FollowUpItem?> getFollowUp(String id) async {
    if (shouldThrowUnauthenticated) throw RecallrDataException.unauthenticated();
    if (shouldThrowError) throw RecallrDataException.networkUnavailable();
    return _store[id];
  }

  @override
  Future<void> toggleComplete(String id, bool isCompleted) async {
    if (shouldThrowUnauthenticated) throw RecallrDataException.unauthenticated();
    if (shouldFailToggle || shouldThrowError) throw RecallrDataException.networkUnavailable();

    final existing = _store[id];
    if (existing != null) {
      final updated = existing.copyWith(
        isCompleted: isCompleted,
        status: isCompleted ? FollowUpStatus.completed : FollowUpStatus.dueToday,
        completedAt: isCompleted ? 'Just now' : null,
        clearCompletedAt: !isCompleted,
        updatedAt: DateTime.now(),
      );
      _store[id] = updated;
      _streamController.add(_store.values.toList());
    }
  }

  @override
  Future<void> addFollowUp(FollowUpItem followUp) async {
    final newItem = followUp.copyWith(
      id: followUp.id.isNotEmpty ? followUp.id : 'fol_gen_${_store.length + 1}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store[newItem.id] = newItem;
    _streamController.add(_store.values.toList());
  }

  @override
  Future<void> updateFollowUp(FollowUpItem followUp) async {
    _store[followUp.id] = followUp.copyWith(updatedAt: DateTime.now());
    _streamController.add(_store.values.toList());
  }

  @override
  Future<void> deleteFollowUp(String id) async {
    _store.remove(id);
    _streamController.add(_store.values.toList());
  }

  @override
  Stream<FollowUpSummaryStats> streamSummaryStats() {
    return streamFollowUps().map((list) {
      int today = 0;
      int upcoming = 0;
      int waiting = 0;
      int overdue = 0;
      int completed = 0;

      for (final item in list) {
        if (item.isCompleted || item.status == FollowUpStatus.completed) {
          completed++;
        } else {
          switch (item.status) {
            case FollowUpStatus.dueToday:
              today++;
              break;
            case FollowUpStatus.upcoming:
              upcoming++;
              break;
            case FollowUpStatus.waiting:
              waiting++;
              break;
            case FollowUpStatus.overdue:
              overdue++;
              break;
            case FollowUpStatus.completed:
              break;
          }
        }
      }

      return FollowUpSummaryStats(
        todayCount: today,
        upcomingCount: upcoming,
        waitingCount: waiting,
        overdueCount: overdue,
        completedCount: completed,
      );
    });
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('Phase 13C-05: Follow-up Domain Models & Serialization Tests', () {
    test('1. FollowUpItem serializes and deserializes all Firestore fields accurately', () {
      const followUp = FollowUpItem(
        id: 'fol_101',
        title: 'Send SLM quantization benchmark paper',
        context: 'Discussed 4-bit integer quantization over coffee catch-up.',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        priority: FollowUpPriority.high,
        dueDate: 'Today · 5:00 PM',
        createdDate: 'Yesterday',
        personId: 'per_301',
        personName: 'Dr. Priya Sharma',
        personRole: 'Principal Architect & SLM Lead',
        companyId: 'comp_msr',
        companyName: 'Microsoft Research India',
        sourceInteractionId: 'act_101',
        sourceMemoryTitle: 'Coffee catch-up at Indiranagar',
        sourceMemoryDate: '2 days ago',
        location: 'Bengaluru',
        isVerified: true,
        targetRoute: '/follow-up/fol_101',
        isCompleted: false,
        metadata: {'tag': 'SLM-Benchmark'},
      );

      final map = followUp.toMap();
      expect(map['id'], equals('fol_101'));
      expect(map['commitmentType'], equals('iPromised'));
      expect(map['status'], equals('dueToday'));
      expect(map['personName'], equals('Dr. Priya Sharma'));
      expect(map['companyName'], equals('Microsoft Research India'));
      expect(map['isVerified'], isTrue);

      final restored = FollowUpItem.fromMap(map, 'fol_101');
      expect(restored.id, equals('fol_101'));
      expect(restored.commitmentType, equals(CommitmentType.iPromised));
      expect(restored.isIPromised, isTrue);
      expect(restored.status, equals(FollowUpStatus.dueToday));
      expect(restored.title, equals(followUp.title));
      expect(restored.personName, equals('Dr. Priya Sharma'));
      expect(restored.metadata?['tag'], equals('SLM-Benchmark'));
    });

    test('2. FollowUpItem safely handles missing and optional fields', () {
      final minimalMap = {
        'id': 'fol_min',
        'title': 'Quick follow-up with Arjun',
        'dueDate': 'Tomorrow',
      };

      final item = FollowUpItem.fromMap(minimalMap);
      expect(item.id, equals('fol_min'));
      expect(item.title, equals('Quick follow-up with Arjun'));
      expect(item.commitmentType, equals(CommitmentType.followUp));
      expect(item.status, equals(FollowUpStatus.dueToday));
      expect(item.priority, equals(FollowUpPriority.medium));
      expect(item.personName, isNull);
      expect(item.isVerified, isTrue);
      expect(item.isCompleted, isFalse);
      expect(item.targetRoute, equals('/follow-ups'));
    });
  });

  group('Phase 13C-05: Follow-up Repository Live State & UI Tests', () {
    late FakeFirestoreFollowUpRepository fakeRepo;
    const testFollowUp1 = FollowUpItem(
      id: 'fol_101',
      title: 'Send SLM quantization benchmark paper',
      context: 'Discussed 4-bit integer quantization over coffee catch-up.',
      commitmentType: CommitmentType.iPromised,
      status: FollowUpStatus.dueToday,
      priority: FollowUpPriority.high,
      dueDate: 'Today · 5:00 PM',
      personId: 'per_301',
      personName: 'Dr. Priya Sharma',
      personRole: 'Principal Architect & SLM Lead',
      companyId: 'comp_msr',
      companyName: 'Microsoft Research India',
      targetRoute: '/follow-up/fol_101',
      isCompleted: false,
    );

    const testFollowUp2 = FollowUpItem(
      id: 'fol_102',
      title: 'Review speech synthesis benchmark suite',
      context: 'Vivek to send draft dataset evaluation methodology.',
      commitmentType: CommitmentType.theyPromised,
      status: FollowUpStatus.upcoming,
      priority: FollowUpPriority.medium,
      dueDate: 'Next Week',
      personId: 'per_302',
      personName: 'Vivek Raghavan',
      personRole: 'Chief AI Architect',
      companyId: 'comp_sarvam',
      companyName: 'Sarvam AI',
      targetRoute: '/follow-up/fol_102',
      isCompleted: false,
    );

    setUp(() {
      fakeRepo = FakeFirestoreFollowUpRepository(initialData: [testFollowUp1, testFollowUp2]);
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    test('3. Repository supports CRUD and completion toggling', () async {
      final initialList = await fakeRepo.streamFollowUps().first;
      expect(initialList, hasLength(2));

      // Toggle complete
      await fakeRepo.toggleComplete('fol_101', true);
      var item = await fakeRepo.getFollowUp('fol_101');
      expect(item!.isCompleted, isTrue);
      expect(item.status, equals(FollowUpStatus.completed));
      expect(item.completedAt, equals('Just now'));

      // Toggle uncomplete
      await fakeRepo.toggleComplete('fol_101', false);
      item = await fakeRepo.getFollowUp('fol_101');
      expect(item!.isCompleted, isFalse);
      expect(item.status, equals(FollowUpStatus.dueToday));
      expect(item.completedAt, isNull);
    });

    test('4. Repository calculates summary statistics accurately', () async {
      final stats = await fakeRepo.streamSummaryStats().first;
      expect(stats.todayCount, equals(1));
      expect(stats.upcomingCount, equals(1));
      expect(stats.waitingCount, equals(0));
      expect(stats.overdueCount, equals(0));
      expect(stats.completedCount, equals(0));
      expect(stats.totalActive, equals(2));
    });

    testWidgets('5. FollowUpsScreen renders live follow-ups from injected repository', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpsScreen(
              repository: fakeRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Send SLM quantization benchmark paper'), findsWidgets);
      expect(find.text('Review speech synthesis benchmark suite'), findsWidgets);
      expect(find.textContaining('Dr. Priya Sharma'), findsWidgets);
      expect(find.textContaining('Vivek Raghavan'), findsWidgets);
    });

    testWidgets('6. FollowUpsScreen handles repository error gracefully with retry option', (tester) async {
      final errorRepo = FakeFirestoreFollowUpRepository(initialData: [testFollowUp1])..shouldThrowError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpsScreen(
              repository: errorRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("couldn't load your follow-ups"), findsOneWidget);

      // Fix error and retry
      errorRepo.shouldThrowError = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Send SLM quantization benchmark paper'), findsWidgets);
    });

    testWidgets('7. Optimistic completion toggle rolls back on repository write failure', (tester) async {
      final failRepo = FakeFirestoreFollowUpRepository(initialData: [testFollowUp1])..shouldFailToggle = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpsScreen(
              repository: failRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state has "Complete" button
      expect(find.text('Complete'), findsWidgets);

      // Tap completion button on the first card
      await tester.tap(find.text('Complete').first);
      await tester.pumpAndSettle();

      // Because write failed, it rolls back to uncompleted state
      expect(find.text('Complete'), findsWidgets);
    });
  });
}