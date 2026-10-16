import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../core/errors/data_exceptions.dart';

/// Domain model representing a recorded audio file.
class RecordedAudioFile {
  final String path;
  final String name;
  final int size;
  final String mimeType;
  final Duration duration;
  final Uint8List? bytes;

  const RecordedAudioFile({
    required this.path,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.duration,
    this.bytes,
  });

  @override
  String toString() =>
      'RecordedAudioFile(name: $name, size: $size bytes, duration: $duration, mimeType: $mimeType)';
}

/// Abstract contract for device audio recording.
abstract class AudioRecorderService {
  Future<bool> hasPermission();
  Future<void> startRecording({String? customPath});
  Future<RecordedAudioFile?> stopRecording();
  Future<void> cancelRecording();
  Stream<Duration> get durationStream;
  bool get isRecording;
  Future<void> dispose();
}

/// Production implementation of AudioRecorderService using package:record.
class DeviceAudioRecorderService implements AudioRecorderService {
  final AudioRecorder _recorder;
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  bool _isRecording = false;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;
  DateTime? _startTime;
  String? _currentRecordingPath;

  DeviceAudioRecorderService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  @override
  bool get isRecording => _isRecording;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e, st) {
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> startRecording({String? customPath}) async {
    try {
      final permitted = await hasPermission();
      if (!permitted) {
        throw RecallrDataException.permissionDenied(
          'Microphone permission was denied.',
        );
      }

      if (_isRecording) {
        await cancelRecording();
      }

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      final path = customPath;
      if (path != null && path.isNotEmpty) {
        await _recorder.start(config, path: path);
        _currentRecordingPath = path;
      } else {
        // Platform-managed temp storage
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final generatedPath = '${tempDir.path}/voice_capture_$timestamp.m4a';
        await _recorder.start(config, path: generatedPath);
        _currentRecordingPath = generatedPath;
      }

      _isRecording = true;
      _elapsed = Duration.zero;
      _startTime = DateTime.now();
      _durationController.add(_elapsed);

      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isRecording) {
          _elapsed = DateTime.now().difference(_startTime ?? DateTime.now());
          _durationController.add(_elapsed);
        }
      });
    } catch (e, st) {
      _cleanupState();
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<RecordedAudioFile?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      _durationTimer?.cancel();
      final path = await _recorder.stop();
      final actualPath = path ?? _currentRecordingPath;
      final finalDuration = _elapsed;
      _cleanupState();

      if (actualPath == null || actualPath.isEmpty) {
        return null;
      }

      final file = File(actualPath);
      if (!await file.exists()) {
        throw RecallrDataException.notFound(
          'Recorded audio file not found on device.',
        );
      }

      final fileSize = await file.length();
      final fileName = actualPath.split(Platform.pathSeparator).last;

      return RecordedAudioFile(
        path: actualPath,
        name: fileName,
        size: fileSize,
        mimeType: 'audio/m4a',
        duration: finalDuration,
      );
    } catch (e, st) {
      _cleanupState();
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      _durationTimer?.cancel();
      final path = await _recorder.stop();
      final actualPath = path ?? _currentRecordingPath;
      _cleanupState();

      if (actualPath != null && actualPath.isNotEmpty) {
        final file = File(actualPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      _cleanupState();
      // Silently finish cancellation
    }
  }

  void _cleanupState() {
    _isRecording = false;
    _durationTimer?.cancel();
    _durationTimer = null;
    _currentRecordingPath = null;
    _startTime = null;
    _elapsed = Duration.zero;
  }

  @override
  Future<void> dispose() async {
    _cleanupState();
    await _recorder.dispose();
    await _durationController.close();
  }
}

/// Deterministic mock implementation of AudioRecorderService for tests and offline preview.
class MockAudioRecorderService implements AudioRecorderService {
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  bool shouldGrantPermission;
  bool shouldThrowError;
  Duration simulatedDuration;
  bool _isRecording = false;
  Timer? _timer;
  int _seconds = 0;

  MockAudioRecorderService({
    this.shouldGrantPermission = true,
    this.shouldThrowError = false,
    this.simulatedDuration = const Duration(seconds: 14),
  });

  @override
  bool get isRecording => _isRecording;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Future<bool> hasPermission() async {
    if (shouldThrowError) {
      throw RecallrDataException.networkUnavailable();
    }
    return shouldGrantPermission;
  }

  @override
  Future<void> startRecording({String? customPath}) async {
    if (shouldThrowError) {
      throw RecallrDataException.networkUnavailable();
    }
    if (!shouldGrantPermission) {
      throw RecallrDataException.permissionDenied(
        'Microphone permission was denied.',
      );
    }

    _isRecording = true;
    _seconds = 0;
    _durationController.add(Duration.zero);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isRecording) {
        _seconds++;
        _durationController.add(Duration(seconds: _seconds));
      }
    });
  }

  @override
  Future<RecordedAudioFile?> stopRecording() async {
    if (shouldThrowError) {
      throw RecallrDataException.networkUnavailable();
    }
    if (!_isRecording) return null;

    _timer?.cancel();
    _isRecording = false;

    final duration = _seconds > 0 ? Duration(seconds: _seconds) : simulatedDuration;
    final bytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

    return RecordedAudioFile(
      path: '/mock/voice_capture_123.m4a',
      name: 'voice_capture_123.m4a',
      size: 154000,
      mimeType: 'audio/m4a',
      duration: duration,
      bytes: bytes,
    );
  }

  @override
  Future<void> cancelRecording() async {
    _timer?.cancel();
    _isRecording = false;
    _seconds = 0;
  }

  @override
  Future<void> dispose() async {
    await cancelRecording();
    await _durationController.close();
  }
}