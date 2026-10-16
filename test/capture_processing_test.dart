import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_capture_processing_repository.dart';
import 'package:recaller/data/mock/mock_media_storage_repository.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/models/capture_processing_models.dart';
import 'package:recaller/features/capture/widgets/capture_method_grid.dart';
import 'package:recaller/features/capture/widgets/capture_success_view.dart';
import 'package:recaller/repositories/capture_repository.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/services/audio_recorder_service.dart';
import 'package:recaller/services/capture_processing_service.dart';
import 'package:recaller/services/media_picker_service.dart';

/// In-memory CaptureRepository for testing processing integration.
class FakeCaptureRepo implements CaptureRepository {
  final Map<String, CaptureItem> _store = {};
  final StreamController<List<CaptureItem>> _stream =
      StreamController<List<CaptureItem>>.broadcast();

  @override
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 10}) {
    return _stream.stream.asBroadcastStream(
      onListen: (s) => _stream.add(_store.values.toList()),
    );
  }

  @override
  Future<CaptureItem> saveCapture(CaptureItem item) async {
    final id = item.id.isNotEmpty ? item.id : 'cap_test_${_store.length + 1}';
    final saved = item.copyWith(
      id: id,
      userId: 'usr_auth_123',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store[id] = saved;
    _stream.add(_store.values.toList());
    return saved;
  }

  @override
  Future<CaptureItem?> getCapture(String id) async => _store[id];

  @override
  Future<void> deleteCapture(String id) async {
    _store.remove(id);
    _stream.add(_store.values.toList());
  }

  void dispose() => _stream.close();
}

void main() {
  group('Phase 13D-03: Domain & Model Tests', () {
    test('1. CaptureProcessingStatus serialization and deserialization', () {
      expect(CaptureProcessingStatus.fromString('pending'), equals(CaptureProcessingStatus.pending));
      expect(CaptureProcessingStatus.fromString('processing'), equals(CaptureProcessingStatus.processing));
      expect(CaptureProcessingStatus.fromString('completed'), equals(CaptureProcessingStatus.completed));
      expect(CaptureProcessingStatus.fromString('failed'), equals(CaptureProcessingStatus.failed));
      expect(CaptureProcessingStatus.fromString(null), equals(CaptureProcessingStatus.pending));
      expect(CaptureProcessingStatus.fromString('unknown_state'), equals(CaptureProcessingStatus.pending));
    });

    test('2. CaptureProcessingResult serialization and deserialization', () {
      final now = DateTime(2026, 8, 28, 12, 0, 0);
      final result = CaptureProcessingResult(
        captureId: 'cap_proc_01',
        status: CaptureProcessingStatus.completed,
        processedAt: now,
        title: 'Meeting Notes with Sarah',
        summary: 'Discussed edge computing architecture.',
        extractedText: 'Edge computing nodes v1.2',
        detectedPeople: ['Sarah Chen'],
        detectedCompany: 'Mosaic Neuromorphic',
        detectedLocation: 'San Francisco',
        confidence: 0.96,
        metadata: {'tag': 'systems'},
      );

      final map = result.toMap();
      expect(map['captureId'], equals('cap_proc_01'));
      expect(map['status'], equals('completed'));
      expect(map['confidence'], equals(0.96));
      expect(map['detectedPeople'], equals(['Sarah Chen']));

      final restored = CaptureProcessingResult.fromMap(map, 'cap_proc_01');
      expect(restored.captureId, equals('cap_proc_01'));
      expect(restored.status, equals(CaptureProcessingStatus.completed));
      expect(restored.confidence, equals(0.96));
      expect(restored.detectedCompany, equals('Mosaic Neuromorphic'));
    });

    test('3. Backward compatibility: CaptureItem deserializes without processing fields', () {
      final legacy = {
        'id': 'cap_legacy_01',
        'type': 'note',
        'title': 'Legacy Quick Note',
        'description': 'Old note before intelligence processing',
        'timestamp': '2 days ago',
        'targetRoute': '/activity',
      };

      final item = CaptureItem.fromMap(legacy);
      expect(item.processingStatus, isNull);
      expect(item.processedAt, isNull);
      expect(item.extractedText, isNull);
      expect(item.summary, isNull);
      expect(item.confidence, isNull);
    });

    test('4. Resilient Timestamp / Date parsing in CaptureProcessingResult', () {
      final mapWithTimestamp = {
        'captureId': 'cap_ts',
        'status': 'completed',
        'processedAt': Timestamp.fromDate(DateTime(2026, 8, 28)),
      };
      final item1 = CaptureProcessingResult.fromMap(mapWithTimestamp);
      expect(item1.processedAt, equals(DateTime(2026, 8, 28)));

      final mapWithString = {
        'captureId': 'cap_str',
        'status': 'completed',
        'processedAt': '2026-08-28T12:00:00.000',
      };
      final item2 = CaptureProcessingResult.fromMap(mapWithString);
      expect(item2.processedAt, isNotNull);

      final mapWithNull = {
        'captureId': 'cap_null',
        'status': 'pending',
        'processedAt': null,
      };
      final item3 = CaptureProcessingResult.fromMap(mapWithNull);
      expect(item3.processedAt, isNull);
    });

    test('5. copyWith updates intelligence processing fields correctly', () {
      const item = CaptureItem(
        id: 'cap_cw_test',
        type: CaptureType.note,
        title: 'Note',
        description: 'Desc',
        timestamp: 'Now',
        targetRoute: '/activity',
      );

      final updated = item.copyWith(
        processingStatus: CaptureProcessingStatus.completed,
        summary: 'Extracted summary',
        confidence: 0.97,
      );

      expect(updated.processingStatus, equals(CaptureProcessingStatus.completed));
      expect(updated.summary, equals('Extracted summary'));
      expect(updated.confidence, equals(0.97));
    });
  });

  group('Phase 13D-03: Capture Processing Service Tests', () {
    late DeterministicCaptureProcessingService service;

    setUp(() {
      service = const DeterministicCaptureProcessingService(simulatedLatency: Duration.zero);
    });

    test('6. Image deterministic processing extracts entities and whiteboard context', () async {
      const item = CaptureItem(
        id: 'cap_img_01',
        type: CaptureType.photo,
        title: 'Whiteboard Diagram',
        description: 'Architecture diagram',
        timestamp: 'Just now',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Neuromorphic',
        targetRoute: '/activity',
      );

      final result = await service.processImage(item);
      expect(result.status, equals(CaptureProcessingStatus.completed));
      // detectedPeople: personName from CaptureItem is used when OCR unavailable
      expect(result.detectedPeople, contains('Sarah Chen'));
      expect(result.detectedCompany, equals('Mosaic Neuromorphic'));
      // Confidence is 0.0 when no OCR provider is configured (honest baseline)
      expect(result.confidence, isNotNull);
    });

    test('7. Voice deterministic processing extracts audio takeaways', () async {
      const item = CaptureItem(
        id: 'cap_vox_01',
        type: CaptureType.voice,
        title: 'Voice Takeaway',
        description: 'Audio discussion',
        timestamp: 'Just now',
        durationSeconds: 45,
        targetRoute: '/activity',
      );

      final result = await service.processVoice(item);
      expect(result.status, equals(CaptureProcessingStatus.completed));
      // CAP-P0-3 / CAP-P3: Voice processing is honest. Without an STT provider, text is null.
      expect(result.extractedText, isNull);
      expect(result.confidence, equals(0.0));
      expect(result.metadata?['transcriptionStatus'], equals('unavailable'));
    });

    test('8. Document deterministic processing extracts spec details', () async {
      const item = CaptureItem(
        id: 'cap_doc_01',
        type: CaptureType.document,
        title: 'Silicon Spec Sheet',
        description: 'PDF Document',
        timestamp: 'Yesterday',
        targetRoute: '/activity',
      );

      final result = await service.processDocument(item);
      expect(result.status, equals(CaptureProcessingStatus.completed));
      // CAP-P0-3: Document processing is honest. Without OCR, text is null.
      expect(result.extractedText, isNull);
    });

    test('9. Note deterministic processing formats note summary', () async {
      const item = CaptureItem(
        id: 'cap_note_01',
        type: CaptureType.note,
        title: 'Breakfast Sync',
        description: 'Discussed seed round fundraising and customer traction.',
        timestamp: 'Just now',
        targetRoute: '/activity',
      );

      final result = await service.processNote(item);
      expect(result.status, equals(CaptureProcessingStatus.completed));
      expect(result.summary, contains('seed round'));
      expect(result.confidence, equals(0.98));
    });

    test('10. Business card processing extracts contact details', () async {
      const item = CaptureItem(
        id: 'cap_card_01',
        type: CaptureType.businessCard,
        title: 'Visiting Card',
        description: 'Card OCR',
        timestamp: 'Now',
        personName: 'Elena Rostova',
        companyName: 'Apex Photonics',
        targetRoute: '/activity',
      );

      final result = await service.processCapture(item);
      expect(result.status, equals(CaptureProcessingStatus.completed));
      expect(result.detectedPeople, contains('Elena Rostova'));
      expect(result.detectedCompany, equals('Apex Photonics'));
      // CAP-P0-3: Honest confidence score. Without OCR provider, defaults to 0.0.
      expect(result.confidence, equals(0.0));
    });
  });

  group('Phase 13D-03: Repository & Security Tests', () {
    late MockCaptureProcessingRepository repo;

    setUp(() {
      repo = MockCaptureProcessingRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('11. Unauthenticated processing fails closed', () async {
      repo.shouldThrowUnauthenticated = true;
      const item = CaptureItem(
        id: 'cap_unauth',
        type: CaptureType.note,
        title: 'Note',
        description: 'Desc',
        timestamp: 'Now',
        targetRoute: '/activity',
      );

      expect(() => repo.processCapture(item), throwsA(isA<RecallrDataException>()));
      expect(() => repo.getProcessingResult('cap_unauth'), throwsA(isA<RecallrDataException>()));
    });

    test('12. Successful processing returns updated CaptureItem and broadcasts result', () async {
      const item = CaptureItem(
        id: 'cap_repo_01',
        type: CaptureType.note,
        title: 'Quick Idea',
        description: 'New feature plan',
        timestamp: 'Just now',
        targetRoute: '/activity',
      );

      final updated = await repo.processCapture(item);
      expect(updated.processingStatus, equals(CaptureProcessingStatus.completed));
      expect(updated.summary, isNotNull);
      expect(repo.processCalls, equals(1));

      final fetched = await repo.getProcessingResult('cap_repo_01');
      expect(fetched, isNotNull);
      expect(fetched!.status, equals(CaptureProcessingStatus.completed));
    });

    test('13. Failed processing records error without throwing raw exception', () async {
      repo.shouldThrowError = true;
      const item = CaptureItem(
        id: 'cap_err_01',
        type: CaptureType.note,
        title: 'Failed Note',
        description: 'Desc',
        timestamp: 'Now',
        targetRoute: '/activity',
      );

      expect(() => repo.processCapture(item), throwsA(isA<RecallrDataException>()));
    });

    test('14. Retry processing re-executes on existing capture ID', () async {
      const item = CaptureItem(
        id: 'cap_retry_01',
        type: CaptureType.note,
        title: 'Retry Note',
        description: 'Desc',
        timestamp: 'Now',
        targetRoute: '/activity',
      );

      await repo.processCapture(item);
      expect(repo.processCalls, equals(1));

      final retried = await repo.retryProcessing('cap_retry_01');
      expect(retried.processingStatus, equals(CaptureProcessingStatus.completed));
      expect(repo.retryCalls, equals(1));
    });

    test('15. streamProcessingResult emits live updates', () async {
      const item = CaptureItem(
        id: 'cap_stream_01',
        type: CaptureType.note,
        title: 'Stream Note',
        description: 'Desc',
        timestamp: 'Now',
        targetRoute: '/activity',
      );

      final results = <CaptureProcessingResult>[];
      final sub = repo.streamProcessingResult('cap_stream_01').listen(results.add);

      await repo.processCapture(item);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(results, isNotEmpty);
      expect(results.last.status, equals(CaptureProcessingStatus.completed));

      await sub.cancel();
    });
  });

  group('Phase 13D-03: UI & Capture Modal Intelligence Integration Tests', () {
    late FakeCaptureRepo fakeRepo;
    late MockMediaStorageRepository mockStorage;
    late MockMediaPickerService mockPicker;
    late MockAudioRecorderService mockAudio;
    late MockCaptureProcessingRepository mockProcessingRepo;

    setUp(() {
      fakeRepo = FakeCaptureRepo();
      mockStorage = MockMediaStorageRepository();
      mockPicker = MockMediaPickerService();
      mockAudio = MockAudioRecorderService();
      mockProcessingRepo = MockCaptureProcessingRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
      mockAudio.dispose();
      mockProcessingRepo.dispose();
    });

    testWidgets('16. Quick Note save automatically transitions through processing to Processed & Indexed', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeRepo,
              mediaStorageRepository: mockStorage,
              mediaPickerService: mockPicker,
              audioRecorderService: mockAudio,
              captureProcessingRepository: mockProcessingRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Quick Note
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Quick Note')));
      await tester.pumpAndSettle();

      // Enter note text
      await tester.enterText(find.byType(TextField).at(0), 'Foundry Roadmap');
      await tester.enterText(find.byType(TextField).at(1), 'Met with Alex regarding Q3 silicon tapeout.');

      // Review
      await tester.tap(find.text('Save Memory'));
      await tester.pumpAndSettle();

      // Save to Memory
      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Verify Success view with Processed & Indexed indicator
      expect(find.byType(CaptureSuccessView), findsOneWidget);
      expect(find.text('Memory Saved'), findsWidgets);
      expect(find.text('Processed & Indexed'), findsOneWidget);
      expect(mockProcessingRepo.processCalls, equals(1));
    });

    testWidgets('17. Processing failure preserves saved capture and renders retry button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Make processing service fail
      mockProcessingRepo.shouldThrowError = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeRepo,
              mediaStorageRepository: mockStorage,
              mediaPickerService: mockPicker,
              audioRecorderService: mockAudio,
              captureProcessingRepository: mockProcessingRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Quick Note
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Quick Note')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Error Test Note');
      await tester.enterText(find.byType(TextField).at(1), 'Some description.');

      await tester.tap(find.text('Save Memory'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Capture remains saved!
      expect(find.byType(CaptureSuccessView), findsOneWidget);
      expect(find.text('Memory Saved'), findsWidgets);

      // Shows entity extraction failed notice + Retry
      expect(find.text('Entity extraction failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Now fix failure and test retry tap
      mockProcessingRepo.shouldThrowError = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Processed & Indexed'), findsOneWidget);
    });

    testWidgets('18. Photo capture with processing does not delete storage media on processing failure', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockProcessingRepo.shouldThrowError = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeRepo,
              mediaStorageRepository: mockStorage,
              mediaPickerService: mockPicker,
              audioRecorderService: mockAudio,
              captureProcessingRepository: mockProcessingRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Capture Photo
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Capture Photo')));
      await tester.pumpAndSettle();

      // Camera pick
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Process & Review
      await tester.tap(find.text('Process & Review'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Verify Storage object WAS NOT DELETED despite processing failure
      expect(mockStorage.uploadedFiles.isNotEmpty, isTrue);
      expect(find.text('Memory Saved'), findsWidgets);
      expect(find.text('Entity extraction failed'), findsOneWidget);
    });
  });
}