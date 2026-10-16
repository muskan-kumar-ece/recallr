import 'dart:async';
import '../../core/errors/data_exceptions.dart';
import '../../repositories/media_storage_repository.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/media_picker_service.dart';

/// Mock implementation of MediaStorageRepository for deterministic unit/widget tests and offline mode.
class MockMediaStorageRepository implements MediaStorageRepository {
  final Map<String, UploadMediaResult> _uploadedFiles = {};
  bool shouldThrowUnauthenticated;
  bool shouldThrowError;
  Duration simulatedDelay;

  MockMediaStorageRepository({
    this.shouldThrowUnauthenticated = false,
    this.shouldThrowError = false,
    this.simulatedDelay = Duration.zero,
  });

  Map<String, UploadMediaResult> get uploadedFiles => Map.unmodifiable(_uploadedFiles);

  @override
  Future<UploadMediaResult> uploadCaptureImage({
    required String captureId,
    required PickedMediaFile file,
    void Function(double progress)? onProgress,
  }) async {
    if (shouldThrowUnauthenticated) {
      throw RecallrDataException.unauthenticated();
    }
    if (shouldThrowError) {
      throw RecallrDataException.networkUnavailable();
    }

    if (simulatedDelay > Duration.zero) {
      onProgress?.call(0.25);
      await Future<void>.delayed(simulatedDelay ~/ 3);
      onProgress?.call(0.60);
      await Future<void>.delayed(simulatedDelay ~/ 3);
      onProgress?.call(1.0);
      await Future<void>.delayed(simulatedDelay ~/ 3);
    } else {
      onProgress?.call(1.0);
    }

    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final storagePath = 'users/usr_mock_123/captures/$captureId/original.$ext';
    final mediaUrl = 'https://firebasestorage.googleapis.com/v0/b/recallr-b0bcc.firebasestorage.app/o/users%2Fusr_mock_123%2Fcaptures%2F$captureId%2Foriginal.$ext?alt=media';

    final result = UploadMediaResult(
      mediaUrl: mediaUrl,
      storagePath: storagePath,
      mimeType: file.mimeType,
      fileSize: file.size,
    );

    _uploadedFiles[captureId] = result;
    return result;
  }

  @override
  Future<UploadMediaResult> uploadCaptureAudio({
    required String captureId,
    required RecordedAudioFile file,
    void Function(double progress)? onProgress,
  }) async {
    if (shouldThrowUnauthenticated) {
      throw RecallrDataException.unauthenticated();
    }
    if (shouldThrowError) {
      throw RecallrDataException.networkUnavailable();
    }

    if (simulatedDelay > Duration.zero) {
      onProgress?.call(0.25);
      await Future<void>.delayed(simulatedDelay ~/ 3);
      onProgress?.call(0.60);
      await Future<void>.delayed(simulatedDelay ~/ 3);
      onProgress?.call(1.0);
      await Future<void>.delayed(simulatedDelay ~/ 3);
    } else {
      onProgress?.call(1.0);
    }

    final ext = file.name.contains('.') ? file.name.split('.').last : 'm4a';
    final storagePath = 'users/usr_mock_123/captures/$captureId/original.$ext';
    final mediaUrl = 'https://firebasestorage.googleapis.com/v0/b/recallr-b0bcc.firebasestorage.app/o/users%2Fusr_mock_123%2Fcaptures%2F$captureId%2Foriginal.$ext?alt=media';

    final result = UploadMediaResult(
      mediaUrl: mediaUrl,
      storagePath: storagePath,
      mimeType: file.mimeType,
      fileSize: file.size,
    );

    _uploadedFiles[captureId] = result;
    return result;
  }

  @override
  Future<void> deleteCaptureMedia({
    required String captureId,
    required String storagePath,
  }) async {
    if (shouldThrowUnauthenticated) {
      throw RecallrDataException.unauthenticated();
    }
    if (shouldThrowError) {
      throw RecallrDataException.networkUnavailable();
    }
    _uploadedFiles.remove(captureId);
  }

  void clear() {
    _uploadedFiles.clear();
  }
}