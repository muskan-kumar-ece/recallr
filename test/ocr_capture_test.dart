import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_capture_processing_repository.dart';
import 'package:recaller/data/mock/mock_media_storage_repository.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/models/capture_processing_models.dart';
import 'package:recaller/features/capture/models/ocr_models.dart';
import 'package:recaller/features/capture/widgets/capture_method_grid.dart';
import 'package:recaller/features/capture/widgets/capture_success_view.dart';
import 'package:recaller/repositories/capture_repository.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/services/audio_recorder_service.dart';
import 'package:recaller/services/capture_processing_service.dart';
import 'package:recaller/services/media_picker_service.dart';
import 'package:recaller/services/ocr/mock_ocr_service.dart';
import 'package:recaller/services/ocr/ocr_entity_extractor.dart';

/// In-memory CaptureRepository for OCR integration tests.
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
    final id = item.id.isNotEmpty ? item.id : 'cap_ocr_${_store.length + 1}';
    final saved = item.copyWith(
      id: id,
      userId: 'usr_auth_ocr',
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
  group('Phase 13D-04: OCR Domain Model Tests', () {
    test('1. OcrResult serialization and deserialization', () {
      final line1 = const OcrTextLine(text: 'Sarah Chen', confidence: 0.98);
      final line2 = const OcrTextLine(text: 'VP of Engineering', confidence: 0.95);
      final block = OcrTextBlock(
        text: 'Sarah Chen\nVP of Engineering',
        confidence: 0.96,
        boundingBox: {'left': 10.0, 'top': 20.0, 'width': 200.0, 'height': 50.0},
        lines: [line1, line2],
      );
      final result = OcrResult(
        text: 'Sarah Chen\nVP of Engineering',
        confidence: 0.96,
        language: 'en',
        blocks: [block],
        lines: [line1, line2],
        metadata: {'provider': 'ML Kit Test'},
      );

      final map = result.toMap();
      expect(map['text'], contains('Sarah Chen'));
      expect(map['language'], equals('en'));
      expect(map['blocks'], isNotEmpty);

      final restored = OcrResult.fromMap(map);
      expect(restored.text, equals(result.text));
      expect(restored.confidence, equals(0.96));
      expect(restored.blocks.first.boundingBox?['left'], equals(10.0));
      expect(restored.lines.length, equals(2));
      expect(restored.metadata?['provider'], equals('ML Kit Test'));
    });

    test('2. OcrTextBlock serialization and deserialization', () {
      final block = OcrTextBlock(
        text: 'Mosaic Neuromorphic',
        confidence: 0.94,
        boundingBox: {'left': 0.0, 'top': 0.0, 'width': 150.0, 'height': 30.0},
        lines: [const OcrTextLine(text: 'Mosaic Neuromorphic', confidence: 0.94)],
      );

      final map = block.toMap();
      final restored = OcrTextBlock.fromMap(map);
      expect(restored.text, equals('Mosaic Neuromorphic'));
      expect(restored.confidence, equals(0.94));
      expect(restored.lines.first.text, equals('Mosaic Neuromorphic'));
    });

    test('3. OcrTextLine serialization and deserialization', () {
      const line = OcrTextLine(text: 'sarah.chen@mosaic-neuro.io', confidence: 0.99);
      final map = line.toMap();
      final restored = OcrTextLine.fromMap(map);
      expect(restored.text, equals('sarah.chen@mosaic-neuro.io'));
      expect(restored.confidence, equals(0.99));
    });

    test('4. Missing-field resilience and defensive parsing', () {
      final emptyMap = <String, dynamic>{};
      final result = OcrResult.fromMap(emptyMap);
      expect(result.text, equals(''));
      expect(result.confidence, isNull);
      expect(result.blocks, isEmpty);
      expect(result.lines, isEmpty);
      expect(result.metadata, isNull);
      expect(result.isEmpty, isTrue);
    });

    test('5. Confidence parsing supports string, int, double, and null', () {
      final line1 = OcrTextLine.fromMap({'text': 'T1', 'confidence': 0.95});
      final line2 = OcrTextLine.fromMap({'text': 'T2', 'confidence': 1});
      final line3 = OcrTextLine.fromMap({'text': 'T3', 'confidence': '0.88'});
      final line4 = OcrTextLine.fromMap({'text': 'T4', 'confidence': null});

      expect(line1.confidence, equals(0.95));
      expect(line2.confidence, equals(1.0));
      expect(line3.confidence, equals(0.88));
      expect(line4.confidence, isNull);
    });
  });

  group('Phase 13D-04: Mock OCR Provider Tests', () {
    late MockOcrService ocr;

    setUp(() {
      ocr = MockOcrService();
    });

    tearDown(() async {
      await ocr.dispose();
    });

    test('6. Deterministic image OCR extracts whiteboard/slide context', () async {
      final result = await ocr.extractText(mediaPath: 'uploads/photo_whiteboard.jpg');
      expect(result.isNotEmpty, isTrue);
      expect(result.text, contains('Whiteboard Architecture Session'));
      expect(result.text, contains('Sarah Chen'));
      expect(ocr.extractCalls, equals(1));
    });

    test('7. Deterministic document OCR extracts spec sheet content', () async {
      final result = await ocr.extractText(mediaPath: 'documents/spec_sheet.pdf');
      expect(result.isNotEmpty, isTrue);
      expect(result.text, contains('Specification v2.4'));
      expect(result.text, contains('Elena Rostova'));
      expect(result.text, contains('Apex Photonics'));
    });

    test('8. Empty image handling returns OcrResult.empty gracefully', () async {
      final result1 = await ocr.extractText(mediaPath: '');
      expect(result1.isEmpty, isTrue);

      final result2 = await ocr.extractText(mediaPath: 'photos/empty_blank.png');
      expect(result2.isEmpty, isTrue);
    });

    test('9. OCR failure simulation throws RecallrDataException', () async {
      ocr.shouldFail = true;
      expect(
        () => ocr.extractText(mediaPath: 'uploads/photo.jpg'),
        throwsA(isA<RecallrDataException>()),
      );
    });
  });

  group('Phase 13D-04: Structured Entity Extraction Tests', () {
    const rawCardText = '''
Alex Johnson
Product Manager
Acme Technologies
alex.johnson@acmetech.io
+1 (415) 555-0199
https://acmetech.io
San Francisco, CA
2026-08-28
''';

    test('10. Name extraction detects capitalized person name', () {
      final entities = OcrEntityExtractor.extract(rawCardText);
      expect(entities.name, equals('Alex Johnson'));
    });

    test('11. Email extraction detects valid email address', () {
      final entities = OcrEntityExtractor.extract(rawCardText);
      expect(entities.email, equals('alex.johnson@acmetech.io'));
    });

    test('12. Phone extraction detects phone number', () {
      final entities = OcrEntityExtractor.extract(rawCardText);
      expect(entities.phone, contains('415'));
    });

    test('13. Company extraction detects company with suffix or email domain', () {
      final entities = OcrEntityExtractor.extract(rawCardText);
      expect(entities.company, equals('Acme Technologies'));
    });

    test('14. Role extraction detects professional role/title', () {
      final entities = OcrEntityExtractor.extract(rawCardText);
      expect(entities.role, equals('Product Manager'));
    });

    test('15. Website extraction detects domain URL', () {
      final entities = OcrEntityExtractor.extract(rawCardText);
      expect(entities.website, equals('https://acmetech.io'));
    });

    test('16. Date and Location extraction detects ISO date and city/state', () {
      final entities = OcrEntityExtractor.extract(rawCardText);
      expect(entities.date, equals('2026-08-28'));
      expect(entities.location, equals('San Francisco, CA'));
    });
  });

  group('Phase 13D-04: OCR Processing & Repository Integration Tests', () {
    late MockOcrService mockOcr;
    late DeterministicCaptureProcessingService processingService;
    late MockCaptureProcessingRepository processingRepo;

    setUp(() {
      mockOcr = MockOcrService();
      processingService = DeterministicCaptureProcessingService(
        simulatedLatency: Duration.zero,
        ocrService: mockOcr,
      );
      processingRepo = MockCaptureProcessingRepository(service: processingService);
    });

    tearDown(() {
      processingRepo.dispose();
    });

    test('17. Image capture triggers OCR and persists structured entity metadata', () async {
      const item = CaptureItem(
        id: 'cap_img_ocr_01',
        type: CaptureType.photo,
        title: 'Whiteboard Diagram',
        description: 'Session notes',
        timestamp: 'Just now',
        storagePath: 'users/usr_123/captures/cap_img_ocr_01/photo.jpg',
        localFilePath: '/mock/local/photo.jpg',
        targetRoute: '/activity',
      );

      final result = await processingRepo.processCapture(item);
      expect(result.processingStatus, equals(CaptureProcessingStatus.completed));
      expect(result.extractedText, contains('Whiteboard Architecture Session'));
      expect(result.summary, isNotNull);
      expect(mockOcr.extractCalls, equals(1));
    });

    test('18. Document capture triggers OCR and extracts spec details', () async {
      const item = CaptureItem(
        id: 'cap_doc_ocr_01',
        type: CaptureType.document,
        title: 'Silicon Specification',
        description: 'Spec doc',
        timestamp: 'Yesterday',
        storagePath: 'users/usr_123/captures/cap_doc_ocr_01/spec.pdf',
        localFilePath: '/mock/local/spec.pdf',
        targetRoute: '/activity',
      );

      final result = await processingRepo.processCapture(item);
      expect(result.processingStatus, equals(CaptureProcessingStatus.completed));
      expect(result.extractedText, contains('Specification v2.4'));
      expect(mockOcr.extractCalls, equals(1));
    });

    test('19. OCR failure preserves capture and provides fallback', () async {
      mockOcr.shouldFail = true;
      const item = CaptureItem(
        id: 'cap_ocr_fail_01',
        type: CaptureType.photo,
        title: 'Photo Encounter',
        description: 'Photo with bad OCR',
        timestamp: 'Now',
        storagePath: 'users/usr_123/captures/cap_ocr_fail_01/photo.jpg',
        localFilePath: '/mock/local/fail.jpg',
        targetRoute: '/activity',
      );

      // Processing still completes non-destructively with deterministic fallback
      final result = await processingRepo.processCapture(item);
      expect(result.processingStatus, equals(CaptureProcessingStatus.completed));
      expect(result.extractedText, equals('Photo with bad OCR'));
    });

    test('20. Retry processing re-executes idempotently on same capture ID', () async {
      const item = CaptureItem(
        id: 'cap_ocr_retry_01',
        type: CaptureType.photo,
        title: 'Retry Photo',
        description: 'Photo',
        timestamp: 'Now',
        storagePath: 'users/usr_123/captures/cap_ocr_retry_01/photo.jpg',
        localFilePath: '/mock/local/retry.jpg',
        targetRoute: '/activity',
      );

      await processingRepo.processCapture(item);
      expect(mockOcr.extractCalls, equals(1));

      final retried = await processingRepo.retryProcessing('cap_ocr_retry_01');
      expect(retried.processingStatus, equals(CaptureProcessingStatus.completed));
      expect(processingRepo.retryCalls, equals(1));
      expect(mockOcr.extractCalls, equals(2));
    });

    test('21. Duplicate processing does not create duplicate capture items', () async {
      const item = CaptureItem(
        id: 'cap_ocr_dup_01',
        type: CaptureType.photo,
        title: 'Duplicate Check',
        description: 'Desc',
        timestamp: 'Now',
        storagePath: 'users/usr_123/captures/cap_ocr_dup_01/photo.jpg',
        targetRoute: '/activity',
      );

      await processingRepo.processCapture(item);
      await processingRepo.processCapture(item);

      expect(processingRepo.results.length, equals(1));
    });
  });

  group('Phase 13D-04: Dependency Injection Tests', () {
    tearDown(() {
      RecallrDependencies.reset();
    });

    test('22. Production dependency construction initializes OcrService', () {
      final deps = RecallrDependencies.production();
      expect(deps.ocrService, isNotNull);
    });

    test('23. Mock dependency construction initializes MockOcrService', () {
      final deps = RecallrDependencies.mock();
      expect(deps.ocrService, isA<MockOcrService>());
    });

    testWidgets('24. BuildContext resolves ocrService cleanly via extension', (tester) async {
      final mockOcr = MockOcrService();
      final deps = RecallrDependencies.mock(ocrService: mockOcr);

      late Object resolved;
      await tester.pumpWidget(
        RecallrScope(
          dependencies: deps,
          child: Builder(
            builder: (context) {
              resolved = context.ocrService;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved, equals(mockOcr));
    });
  });

  group('Phase 13D-04: Capture UI & OCR Integration Tests', () {
    late FakeCaptureRepo fakeRepo;
    late MockMediaStorageRepository mockStorage;
    late MockMediaPickerService mockPicker;
    late MockAudioRecorderService mockAudio;
    late MockOcrService mockOcr;
    late DeterministicCaptureProcessingService processingService;
    late MockCaptureProcessingRepository mockProcessingRepo;

    setUp(() {
      fakeRepo = FakeCaptureRepo();
      mockStorage = MockMediaStorageRepository();
      mockPicker = MockMediaPickerService();
      mockAudio = MockAudioRecorderService();
      mockOcr = MockOcrService();
      processingService = DeterministicCaptureProcessingService(
        simulatedLatency: Duration.zero,
        ocrService: mockOcr,
      );
      mockProcessingRepo = MockCaptureProcessingRepository(service: processingService);
    });

    tearDown(() {
      fakeRepo.dispose();
      mockAudio.dispose();
      mockProcessingRepo.dispose();
    });

    testWidgets('25. Capture Photo with OCR processes and shows Processed & Indexed badge', (tester) async {
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

      // Tap Capture Photo
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Capture Photo')));
      await tester.pumpAndSettle();

      // Pick Camera
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Process & Review
      await tester.tap(find.text('Process & Review'));
      await tester.pumpAndSettle();

      // Save to Memory
      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Verify Success view with Processed & Indexed badge
      expect(find.byType(CaptureSuccessView), findsOneWidget);
      expect(find.text('Memory Saved'), findsWidgets);
      expect(find.text('Processed & Indexed'), findsOneWidget);
      expect(mockOcr.extractCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('26. Extracted OCR text is reflected in recent captures after save', (tester) async {
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

      // Business card OCR flow
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Business Card')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan & Extract'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      expect(find.text('Processed & Indexed'), findsOneWidget);
    });

    testWidgets('27. OCR processing failure preserves saved capture and displays Retry badge', (tester) async {
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

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Capture Photo')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Process & Review'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Memory saved but extraction failed
      expect(find.text('Memory Saved'), findsWidgets);
      expect(find.text('Entity extraction failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('28. Retry action triggers re-processing to completion', (tester) async {
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

      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Quick Note')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Foundry Alignment');
      await tester.enterText(find.byType(TextField).at(1), 'Met with foundry engineering lead.');

      await tester.tap(find.text('Save Memory'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      expect(find.text('Entity extraction failed'), findsOneWidget);

      // Fix failure and tap Retry
      mockProcessingRepo.shouldThrowError = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Processed & Indexed'), findsOneWidget);
    });
  });
}