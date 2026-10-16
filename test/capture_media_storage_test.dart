import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_media_storage_repository.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/widgets/capture_error_view.dart';
import 'package:recaller/features/capture/widgets/capture_method_grid.dart';
import 'package:recaller/features/capture/widgets/capture_success_view.dart';
import 'package:recaller/features/capture/widgets/photo_doc_capture_view.dart';
import 'package:recaller/repositories/capture_repository.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/services/media_picker_service.dart';

/// Fake implementation of CaptureRepository to test Firestore metadata persistence with media fields.
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
  group('Phase 13D-01: Media Picker Service Tests', () {
    test('1. MockMediaPickerService selects image from camera', () async {
      final picker = MockMediaPickerService();
      final file = await picker.pickFromCamera();

      expect(file, isNotNull);
      expect(file!.name, equals('camera_capture.jpg'));
      expect(file.mimeType, equals('image/jpeg'));
      expect(file.size, greaterThan(0));
    });

    test('2. MockMediaPickerService selects image from gallery', () async {
      final picker = MockMediaPickerService();
      final file = await picker.pickFromGallery();

      expect(file, isNotNull);
      expect(file!.name, equals('gallery_upload.jpg'));
      expect(file.mimeType, equals('image/jpeg'));
    });

    test('3. MockMediaPickerService handles cancellation gracefully', () async {
      final picker = MockMediaPickerService(shouldCancel: true);
      final file = await picker.pickFromCamera();

      expect(file, isNull);
    });

    test('4. MockMediaPickerService maps permission denial to RecallrDataException', () async {
      final picker = MockMediaPickerService(shouldThrow: true);
      expect(() => picker.pickFromCamera(), throwsA(isA<RecallrDataException>()));
    });
  });

  group('Phase 13D-01: Media Storage Repository Tests', () {
    late MockMediaStorageRepository mockStorage;
    late PickedMediaFile sampleFile;

    setUp(() {
      mockStorage = MockMediaStorageRepository();
      sampleFile = PickedMediaFile(
        path: '/tmp/whiteboard.jpg',
        name: 'whiteboard.jpg',
        size: 204800,
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
    });

    test('5. Authenticated upload generates correct storage path and metadata', () async {
      double lastProgress = 0.0;
      final result = await mockStorage.uploadCaptureImage(
        captureId: 'cap_photo_01',
        file: sampleFile,
        onProgress: (p) => lastProgress = p,
      );

      expect(result.storagePath, equals('users/usr_mock_123/captures/cap_photo_01/original.jpg'));
      expect(result.mediaUrl, contains('users%2Fusr_mock_123%2Fcaptures%2Fcap_photo_01%2Foriginal.jpg'));
      expect(result.mimeType, equals('image/jpeg'));
      expect(result.fileSize, equals(204800));
      expect(lastProgress, equals(1.0));
      expect(mockStorage.uploadedFiles.containsKey('cap_photo_01'), isTrue);
    });

    test('6. Unauthenticated storage upload is rejected fail-closed', () async {
      mockStorage.shouldThrowUnauthenticated = true;

      expect(
        () => mockStorage.uploadCaptureImage(captureId: 'cap_02', file: sampleFile),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('7. Storage deletion removes object from storage record', () async {
      await mockStorage.uploadCaptureImage(captureId: 'cap_03', file: sampleFile);
      expect(mockStorage.uploadedFiles.containsKey('cap_03'), isTrue);

      await mockStorage.deleteCaptureMedia(
        captureId: 'cap_03',
        storagePath: 'users/usr_mock_123/captures/cap_03/original.jpg',
      );
      expect(mockStorage.uploadedFiles.containsKey('cap_03'), isFalse);
    });
  });

  group('Phase 13D-01: Canonical CaptureItem Media Extension Tests', () {
    test('8. CaptureItem serializes and deserializes media metadata', () {
      const item = CaptureItem(
        id: 'cap_media_99',
        type: CaptureType.photo,
        title: 'Whiteboard Neural Architecture',
        description: 'Encounter diagram with Sarah Chen.',
        timestamp: 'Just now',
        targetRoute: '/activity',
        mediaUrl: 'https://firebasestorage.googleapis.com/v0/b/bucket/o/photo.jpg',
        storagePath: 'users/usr_1/captures/cap_media_99/original.jpg',
        mimeType: 'image/jpeg',
        fileSize: 1540000,
      );

      final map = item.toMap();
      expect(map['mediaUrl'], equals('https://firebasestorage.googleapis.com/v0/b/bucket/o/photo.jpg'));
      expect(map['storagePath'], equals('users/usr_1/captures/cap_media_99/original.jpg'));
      expect(map['mimeType'], equals('image/jpeg'));
      expect(map['fileSize'], equals(1540000));

      final restored = CaptureItem.fromMap(map, 'cap_media_99');
      expect(restored.mediaUrl, equals(item.mediaUrl));
      expect(restored.storagePath, equals(item.storagePath));
      expect(restored.mimeType, equals('image/jpeg'));
      expect(restored.fileSize, equals(1540000));
    });

    test('9. Existing captures without media fields deserialize with backward compatibility', () {
      final legacyMap = {
        'id': 'cap_legacy',
        'type': 'note',
        'title': 'Legacy Note',
        'description': 'Text note',
        'timestamp': 'Yesterday',
        'targetRoute': '/activity',
      };

      final item = CaptureItem.fromMap(legacyMap);
      expect(item.id, equals('cap_legacy'));
      expect(item.mediaUrl, isNull);
      expect(item.storagePath, isNull);
      expect(item.mimeType, isNull);
      expect(item.fileSize, isNull);
    });

    test('10. CaptureItem copyWith updates media fields correctly', () {
      const item = CaptureItem(
        id: 'cap_cp',
        type: CaptureType.photo,
        title: 'Photo',
        description: 'Desc',
        timestamp: 'Now',
        targetRoute: '/activity',
      );

      final updated = item.copyWith(
        mediaUrl: 'https://media.test/img.png',
        storagePath: 'users/u/captures/c/original.png',
        mimeType: 'image/png',
        fileSize: 4096,
      );

      expect(updated.mediaUrl, equals('https://media.test/img.png'));
      expect(updated.storagePath, equals('users/u/captures/c/original.png'));
      expect(updated.mimeType, equals('image/png'));
      expect(updated.fileSize, equals(4096));
    });
  });

  group('Phase 13D-01: Omni-Capture Hub Media Pipeline UI Integration Tests', () {
    late FakeFirestoreCaptureRepository fakeCaptureRepo;
    late MockMediaStorageRepository mockMediaStorage;
    late MockMediaPickerService mockMediaPicker;

    setUp(() {
      fakeCaptureRepo = FakeFirestoreCaptureRepository();
      mockMediaStorage = MockMediaStorageRepository();
      mockMediaPicker = MockMediaPickerService();
    });

    tearDown(() {
      fakeCaptureRepo.dispose();
    });

    testWidgets('11. PhotoDocCaptureView renders Camera and Gallery buttons for photo type', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeCaptureRepo,
              mediaStorageRepository: mockMediaStorage,
              mediaPickerService: mockMediaPicker,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Capture Photo
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Capture Photo')));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoDocCaptureView), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('12. Camera selection updates preview and persists media upload + Firestore metadata on save', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      CaptureItem? savedItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeCaptureRepo,
              mediaStorageRepository: mockMediaStorage,
              mediaPickerService: mockMediaPicker,
              onSaved: (item) => savedItem = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Photo mode
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Capture Photo')));
      await tester.pumpAndSettle();

      // Tap Camera button
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Tap Process & Review
      await tester.tap(find.text('Process & Review'));
      await tester.pumpAndSettle();

      // In Review, tap Save to Memory
      expect(find.text('Save to Memory'), findsOneWidget);
      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Transition to saved state
      expect(find.byType(CaptureSuccessView), findsOneWidget);
      expect(find.text('Memory Saved'), findsWidgets);

      // Verify media storage upload took place
      expect(mockMediaStorage.uploadedFiles.isNotEmpty, isTrue);
      expect(savedItem, isNotNull);
      expect(savedItem!.mediaUrl, isNotNull);
      expect(savedItem!.storagePath, isNotNull);
    });

    testWidgets('13. Failed media upload transitions to error view and prevents saving', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockMediaStorage.shouldThrowError = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeCaptureRepo,
              mediaStorageRepository: mockMediaStorage,
              mediaPickerService: mockMediaPicker,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Photo mode
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Capture Photo')));
      await tester.pumpAndSettle();

      // Pick from Camera
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Process & Review
      await tester.tap(find.text('Process & Review'));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Should transition to error view
      expect(find.byType(CaptureErrorView), findsOneWidget);
    });
  });
}