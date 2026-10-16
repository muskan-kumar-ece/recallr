import '../services/audio_recorder_service.dart';
import '../services/media_picker_service.dart';

/// Result metadata from a successful media storage upload.
class UploadMediaResult {
  final String mediaUrl;
  final String storagePath;
  final String mimeType;
  final int fileSize;

  const UploadMediaResult({
    required this.mediaUrl,
    required this.storagePath,
    required this.mimeType,
    required this.fileSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'mediaUrl': mediaUrl,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'fileSize': fileSize,
    };
  }

  @override
  String toString() => 'UploadMediaResult(mediaUrl: $mediaUrl, storagePath: $storagePath, size: $fileSize)';
}

/// Abstract contract for media asset persistence in Cloud Storage.
abstract class MediaStorageRepository {
  /// Uploads a captured image asset to user-scoped storage path:
  /// `users/{uid}/captures/{captureId}/original.{extension}`
  Future<UploadMediaResult> uploadCaptureImage({
    required String captureId,
    required PickedMediaFile file,
    void Function(double progress)? onProgress,
  });

  /// Uploads a recorded audio asset to user-scoped storage path:
  /// `users/{uid}/captures/{captureId}/original.{extension}`
  Future<UploadMediaResult> uploadCaptureAudio({
    required String captureId,
    required RecordedAudioFile file,
    void Function(double progress)? onProgress,
  });

  /// Deletes a capture media asset from cloud storage.
  Future<void> deleteCaptureMedia({
    required String captureId,
    required String storagePath,
  });
}