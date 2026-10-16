import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_capture_repository.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/widgets/capture_error_view.dart';
import 'package:recaller/features/capture/widgets/capture_method_grid.dart';
import 'package:recaller/features/capture/widgets/capture_success_view.dart';
import 'package:recaller/repositories/capture_repository.dart';
import 'package:recaller/screens/capture/capture_modal.dart';

/// Fake implementation of CaptureRepository to test streaming, save, error mapping, and user scoping.
class FakeFirestoreCaptureRepository implements CaptureRepository {
  final Map<String, CaptureItem> _store = {};
  final StreamController<List<CaptureItem>> _streamController = StreamController<List<CaptureItem>>.broadcast();
  bool shouldThrowUnauthenticated = false;
  bool shouldThrowError = false;

  FakeFirestoreCaptureRepository({List<CaptureItem>? initialData}) {
    if (initialData != null) {
      for (final item in initialData) {
        _store[item.id] = item;
      }
    }
  }

  @override
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 10}) {
    if (shouldThrowUnauthenticated) return Stream.error(RecallrDataException.unauthenticated());
    if (shouldThrowError) return Stream.error(RecallrDataException.networkUnavailable());

    return _streamController.stream
        .map((list) => list.take(limit).toList())
        .asBroadcastStream(
          onListen: (sub) {
            _streamController.add(_store.values.toList());
          },
        );
  }

  @override
  Future<CaptureItem> saveCapture(CaptureItem item) async {
    if (shouldThrowUnauthenticated) throw RecallrDataException.unauthenticated();
    if (shouldThrowError) throw RecallrDataException.networkUnavailable();

    final id = item.id.isNotEmpty ? item.id : 'cap_gen_${_store.length + 1}';
    final saved = item.copyWith(
      id: id,
      userId: 'usr_auth_123',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store[id] = saved;
    _streamController.add(_store.values.toList());
    return saved;
  }

  @override
  Future<CaptureItem?> getCapture(String id) async {
    if (shouldThrowUnauthenticated) throw RecallrDataException.unauthenticated();
    if (shouldThrowError) throw RecallrDataException.networkUnavailable();
    return _store[id];
  }

  @override
  Future<void> deleteCapture(String id) async {
    if (shouldThrowUnauthenticated) throw RecallrDataException.unauthenticated();
    if (shouldThrowError) throw RecallrDataException.networkUnavailable();
    _store.remove(id);
    _streamController.add(_store.values.toList());
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('Phase 13C-06: Capture Domain Models & Serialization Tests', () {
    test('1. CaptureItem serializes and deserializes all Firestore fields accurately', () {
      const capture = CaptureItem(
        id: 'cap_101',
        type: CaptureType.businessCard,
        title: 'Dr. Priya Sharma — Microsoft Research India',
        description: 'Principal Architect & SLM Lead, Bengaluru.',
        timestamp: 'Just now',
        personId: 'per_301',
        personName: 'Dr. Priya Sharma',
        personRole: 'Principal Architect & SLM Lead',
        companyId: 'comp_msr',
        companyName: 'Microsoft Research India',
        eventName: 'India AI Summit 2024',
        location: 'Bengaluru Convention Center',
        targetRoute: '/person/per_301',
        isVerified: true,
        metadata: {'badge': 'Speaker'},
      );

      final map = capture.toMap();
      expect(map['id'], equals('cap_101'));
      expect(map['type'], equals('businessCard'));
      expect(map['title'], equals('Dr. Priya Sharma — Microsoft Research India'));
      expect(map['personName'], equals('Dr. Priya Sharma'));
      expect(map['companyName'], equals('Microsoft Research India'));
      expect(map['isVerified'], isTrue);

      final restored = CaptureItem.fromMap(map, 'cap_101');
      expect(restored.id, equals('cap_101'));
      expect(restored.type, equals(CaptureType.businessCard));
      expect(restored.title, equals(capture.title));
      expect(restored.personName, equals('Dr. Priya Sharma'));
      expect(restored.metadata?['badge'], equals('Speaker'));
    });

    test('2. CaptureItem safely handles missing and optional fields', () {
      final minimalMap = {
        'id': 'cap_min',
        'type': 'note',
        'title': 'Quick note from talk',
        'description': 'Quantization details',
        'timestamp': 'Yesterday',
        'targetRoute': '/activity',
      };

      final item = CaptureItem.fromMap(minimalMap);
      expect(item.id, equals('cap_min'));
      expect(item.type, equals(CaptureType.note));
      expect(item.title, equals('Quick note from talk'));
      expect(item.personName, isNull);
      expect(item.companyName, isNull);
      expect(item.isVerified, isTrue);
    });
  });

  group('Phase 13C-06: Capture Repository Live State & UI Tests', () {
    late FakeFirestoreCaptureRepository fakeRepo;
    const testCapture = CaptureItem(
      id: 'cap_101',
      type: CaptureType.businessCard,
      title: 'Dr. Priya Sharma — Microsoft Research India',
      description: 'Principal Architect & SLM Lead, Bengaluru.',
      timestamp: 'Just now',
      personId: 'per_301',
      personName: 'Dr. Priya Sharma',
      personRole: 'Principal Architect & SLM Lead',
      companyId: 'comp_msr',
      companyName: 'Microsoft Research India',
      targetRoute: '/person/per_301',
      isVerified: true,
    );

    setUp(() {
      fakeRepo = FakeFirestoreCaptureRepository(initialData: [testCapture]);
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    test('3. Repository saves capture and assigns authoritative userId and timestamps', () async {
      const newCapture = CaptureItem(
        id: '',
        type: CaptureType.voice,
        title: 'Voice memo on Indic SLM fine-tuning',
        description: 'Audio takeaway regarding tokenizers.',
        timestamp: 'Just now',
        targetRoute: '/activity',
      );

      final saved = await fakeRepo.saveCapture(newCapture);
      expect(saved.id, isNotEmpty);
      expect(saved.userId, equals('usr_auth_123'));
      expect(saved.createdAt, isNotNull);
      expect(saved.updatedAt, isNotNull);

      final fetched = await fakeRepo.getCapture(saved.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Voice memo on Indic SLM fine-tuning'));
    });

    test('4. MockCaptureRepository supports saving and live streaming', () async {
      final mockRepo = MockCaptureRepository(initialCaptures: [testCapture]);
      final initialList = await mockRepo.streamRecentCaptures().first;
      expect(initialList, hasLength(1));

      const anotherCapture = CaptureItem(
        id: 'cap_102',
        type: CaptureType.note,
        title: 'Coffee meeting notes',
        description: 'Met Arjun at Indiranagar',
        timestamp: 'Just now',
        targetRoute: '/activity',
      );

      await mockRepo.saveCapture(anotherCapture);
      final item = await mockRepo.getCapture('cap_102');
      expect(item, isNotNull);
      expect(item!.title, equals('Coffee meeting notes'));
    });

    testWidgets('5. CaptureModal renders with injected repository and handles method selection', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Business Card')), findsOneWidget);
      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Voice Memo')), findsOneWidget);
      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Quick Note')), findsOneWidget);
      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Capture Photo')), findsOneWidget);
      expect(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Add Document')), findsOneWidget);
    });

    testWidgets('6. CaptureModal saves capture review and transitions to saved state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Business Card
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Business Card')));
      await tester.pumpAndSettle();

      // Tap Scan & Extract
      await tester.tap(find.text('Scan & Extract'));
      await tester.pumpAndSettle();

      // In Review state, tap Save to Memory
      expect(find.text('Save to Memory'), findsOneWidget);
      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Transitions to saved state
      expect(find.byType(CaptureSuccessView), findsOneWidget);
      expect(find.text('Memory Saved'), findsWidgets);
      expect(find.text('View Memory'), findsOneWidget);
    });

    testWidgets('7. CaptureModal handles repository error gracefully', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final errorRepo = FakeFirestoreCaptureRepository(initialData: [testCapture])..shouldThrowError = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: errorRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Business Card
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Business Card')));
      await tester.pumpAndSettle();

      // Tap Scan & Extract
      await tester.tap(find.text('Scan & Extract'));
      await tester.pumpAndSettle();

      // In Review state, tap Save to Memory
      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Error view appears
      expect(find.byType(CaptureErrorView), findsOneWidget);
    });
  });
}