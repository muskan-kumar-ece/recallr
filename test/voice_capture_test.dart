import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/data/mock/mock_media_storage_repository.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/widgets/capture_error_view.dart';
import 'package:recaller/features/capture/widgets/capture_method_grid.dart';
import 'package:recaller/features/capture/widgets/capture_success_view.dart';
import 'package:recaller/features/capture/widgets/voice_capture_view.dart';
import 'package:recaller/repositories/capture_repository.dart';
import 'package:recaller/screens/capture/capture_modal.dart';
import 'package:recaller/services/audio_recorder_service.dart';
import 'package:recaller/services/media_picker_service.dart';

/// In-memory implementation of CaptureRepository with controllable failure modes.
class FakeFirestoreCaptureRepository implements CaptureRepository {
  final Map<String, CaptureItem> _store = {};
  final StreamController<List<CaptureItem>> _streamController =
      StreamController<List<CaptureItem>>.broadcast();
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
  group('Phase 13D-02: Audio Recorder Service Tests', () {
    late MockAudioRecorderService recorder;

    setUp(() {
      recorder = MockAudioRecorderService();
    });

    tearDown(() async {
      await recorder.dispose();
    });

    test('1. Permission check returns granted when permitted', () async {
      expect(await recorder.hasPermission(), isTrue);
    });

    test('2. Permission denial throws typed RecallrDataException on recording start', () async {
      recorder.shouldGrantPermission = false;
      expect(() => recorder.startRecording(), throwsA(isA<RecallrDataException>()));
    });

    test('3. Start and stop recording yields RecordedAudioFile with duration', () async {
      await recorder.startRecording();
      expect(recorder.isRecording, isTrue);

      final audioFile = await recorder.stopRecording();
      expect(audioFile, isNotNull);
      expect(audioFile!.name, equals('voice_capture_123.m4a'));
      expect(audioFile.mimeType, equals('audio/m4a'));
      expect(audioFile.duration, equals(const Duration(seconds: 14)));
      expect(recorder.isRecording, isFalse);
    });

    test('4. Cancel recording resets recording state without throwing', () async {
      await recorder.startRecording();
      expect(recorder.isRecording, isTrue);

      await recorder.cancelRecording();
      expect(recorder.isRecording, isFalse);
    });

    test('5. Recorder duration stream emits updates', () async {
      final durations = <Duration>[];
      final sub = recorder.durationStream.listen(durations.add);

      await recorder.startRecording();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(durations, isNotEmpty);
      expect(durations.first, equals(Duration.zero));

      await sub.cancel();
    });

    test('6. Recorder error mapping handles unexpected exceptions', () async {
      recorder.shouldThrowError = true;
      expect(() => recorder.startRecording(), throwsA(isA<RecallrDataException>()));
      expect(() => recorder.stopRecording(), throwsA(isA<RecallrDataException>()));
    });
  });

  group('Phase 13D-02: Media Storage Audio Upload & Security Tests', () {
    late MockMediaStorageRepository mockStorage;
    late RecordedAudioFile sampleAudio;

    setUp(() {
      mockStorage = MockMediaStorageRepository();
      sampleAudio = const RecordedAudioFile(
        path: '/tmp/memo_01.m4a',
        name: 'memo_01.m4a',
        size: 154000,
        mimeType: 'audio/m4a',
        duration: Duration(seconds: 42),
      );
    });

    test('7. Authenticated audio upload produces correct storage path and metadata', () async {
      double lastProgress = 0.0;
      final result = await mockStorage.uploadCaptureAudio(
        captureId: 'cap_voice_01',
        file: sampleAudio,
        onProgress: (p) => lastProgress = p,
      );

      expect(result.storagePath, equals('users/usr_mock_123/captures/cap_voice_01/original.m4a'));
      expect(result.mediaUrl, contains('users%2Fusr_mock_123%2Fcaptures%2Fcap_voice_01%2Foriginal.m4a'));
      expect(result.mimeType, equals('audio/m4a'));
      expect(result.fileSize, equals(154000));
      expect(lastProgress, equals(1.0));
      expect(mockStorage.uploadedFiles.containsKey('cap_voice_01'), isTrue);
    });

    test('8. Unauthenticated audio upload is rejected fail-closed', () async {
      mockStorage.shouldThrowUnauthenticated = true;

      expect(
        () => mockStorage.uploadCaptureAudio(captureId: 'cap_voice_02', file: sampleAudio),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('9. Storage failure maps to RecallrDataException', () async {
      mockStorage.shouldThrowError = true;

      expect(
        () => mockStorage.uploadCaptureAudio(captureId: 'cap_voice_03', file: sampleAudio),
        throwsA(isA<RecallrDataException>()),
      );
    });

    test('10. Deletion cleans up uploaded audio asset', () async {
      await mockStorage.uploadCaptureAudio(captureId: 'cap_voice_04', file: sampleAudio);
      expect(mockStorage.uploadedFiles.containsKey('cap_voice_04'), isTrue);

      await mockStorage.deleteCaptureMedia(
        captureId: 'cap_voice_04',
        storagePath: 'users/usr_mock_123/captures/cap_voice_04/original.m4a',
      );
      expect(mockStorage.uploadedFiles.containsKey('cap_voice_04'), isFalse);
    });
  });

  group('Phase 13D-02: Canonical CaptureItem Audio Metadata Tests', () {
    test('11. CaptureItem serializes and deserializes audio duration and media fields', () {
      const item = CaptureItem(
        id: 'cap_audio_101',
        type: CaptureType.voice,
        title: 'Dinner Takeaway with Alex',
        description: 'Discussed edge neuromorphic chip designs.',
        timestamp: 'Just now',
        targetRoute: '/activity',
        mediaUrl: 'https://firebasestorage.googleapis.com/v0/b/bucket/o/audio.m4a',
        storagePath: 'users/usr_1/captures/cap_audio_101/original.m4a',
        mimeType: 'audio/m4a',
        fileSize: 245000,
        durationSeconds: 78,
      );

      final map = item.toMap();
      expect(map['mediaUrl'], equals('https://firebasestorage.googleapis.com/v0/b/bucket/o/audio.m4a'));
      expect(map['storagePath'], equals('users/usr_1/captures/cap_audio_101/original.m4a'));
      expect(map['mimeType'], equals('audio/m4a'));
      expect(map['fileSize'], equals(245000));
      expect(map['durationSeconds'], equals(78));

      final restored = CaptureItem.fromMap(map, 'cap_audio_101');
      expect(restored.durationSeconds, equals(78));
      expect(restored.mediaUrl, equals(item.mediaUrl));
      expect(restored.fileSize, equals(245000));
    });

    test('12. Existing captures without duration deserialize with backward compatibility', () {
      final legacyMap = {
        'id': 'cap_legacy_v',
        'type': 'voice',
        'title': 'Legacy Voice',
        'description': 'Audio memo',
        'timestamp': 'Yesterday',
        'targetRoute': '/activity',
      };

      final item = CaptureItem.fromMap(legacyMap);
      expect(item.durationSeconds, isNull);
      expect(item.mediaUrl, isNull);
      expect(item.storagePath, isNull);
    });

    test('13. copyWith updates durationSeconds correctly', () {
      const item = CaptureItem(
        id: 'cap_cw',
        type: CaptureType.voice,
        title: 'Voice',
        description: 'Desc',
        timestamp: 'Now',
        targetRoute: '/activity',
      );

      final updated = item.copyWith(durationSeconds: 120);
      expect(updated.durationSeconds, equals(120));
    });
  });

  group('Phase 13D-02: Omni-Capture Voice Pipeline UI Integration Tests', () {
    late FakeFirestoreCaptureRepository fakeCaptureRepo;
    late MockMediaStorageRepository mockMediaStorage;
    late MockMediaPickerService mockMediaPicker;
    late MockAudioRecorderService mockAudioRecorder;

    setUp(() {
      fakeCaptureRepo = FakeFirestoreCaptureRepository();
      mockMediaStorage = MockMediaStorageRepository();
      mockMediaPicker = MockMediaPickerService();
      mockAudioRecorder = MockAudioRecorderService();
    });

    tearDown(() {
      fakeCaptureRepo.dispose();
      mockAudioRecorder.dispose();
    });

    testWidgets('14. VoiceCaptureView renders mic trigger and toggles recording state', (tester) async {
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
              audioRecorderService: mockAudioRecorder,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Voice Memo
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Voice Memo')));
      await tester.pumpAndSettle();

      expect(find.byType(VoiceCaptureView), findsOneWidget);
      expect(find.text('Start Recording'), findsOneWidget);

      // Tap Start Recording
      await tester.tap(find.text('Start Recording'));
      await tester.pump();

      expect(find.text('Finish & Process'), findsOneWidget);
      expect(mockAudioRecorder.isRecording, isTrue);

      await mockAudioRecorder.stopRecording();
    });

    testWidgets('15. Complete voice recording save pipeline uploads audio and saves Firestore metadata', (tester) async {
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
              audioRecorderService: mockAudioRecorder,
              onSaved: (item) => savedItem = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Voice Memo
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Voice Memo')));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.text('Start Recording'));
      await tester.pumpAndSettle();

      // Finish & Process
      await tester.tap(find.text('Finish & Process'));
      await tester.pumpAndSettle();

      // In Review state
      expect(find.text('Save to Memory'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Verify saved state
      expect(find.byType(CaptureSuccessView), findsOneWidget);
      expect(find.text('Memory Saved'), findsWidgets);

      // Verify audio storage upload
      expect(mockMediaStorage.uploadedFiles.isNotEmpty, isTrue);
      expect(savedItem, isNotNull);
      expect(savedItem!.mediaUrl, isNotNull);
      expect(savedItem!.storagePath, contains('.m4a'));
      expect(savedItem!.durationSeconds, isNotNull);
    });

    testWidgets('16. Permission denial surfaces error view and prevents recording', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockAudioRecorder.shouldGrantPermission = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeCaptureRepo,
              mediaStorageRepository: mockMediaStorage,
              mediaPickerService: mockMediaPicker,
              audioRecorderService: mockAudioRecorder,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Voice Memo
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Voice Memo')));
      await tester.pumpAndSettle();

      // Try starting recording
      await tester.tap(find.text('Start Recording'));
      await tester.pumpAndSettle();

      // Should transition to error view
      expect(find.byType(CaptureErrorView), findsOneWidget);
      expect(find.text('Recallr needs microphone access to record voice memos. Please allow microphone access in your device settings.'), findsOneWidget);
    });

    testWidgets('17. Partial failure: Storage upload succeeds but Firestore save failure cleans up storage object', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Firestore will fail
      fakeCaptureRepo.shouldThrowError = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: RecallrTheme.darkTheme,
          home: Scaffold(
            body: CaptureModal(
              repository: fakeCaptureRepo,
              mediaStorageRepository: mockMediaStorage,
              mediaPickerService: mockMediaPicker,
              audioRecorderService: mockAudioRecorder,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Voice Memo
      await tester.tap(find.descendant(of: find.byType(CaptureMethodGrid), matching: find.text('Voice Memo')));
      await tester.pumpAndSettle();

      // Record & Finish
      await tester.tap(find.text('Start Recording'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish & Process'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save to Memory'));
      await tester.pumpAndSettle();

      // Should transition to error view
      expect(find.byType(CaptureErrorView), findsOneWidget);

      // Cleanup was triggered, so uploadedFiles should be empty
      expect(mockMediaStorage.uploadedFiles.isEmpty, isTrue);
    });
  });
}