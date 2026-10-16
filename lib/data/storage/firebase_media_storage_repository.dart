import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/errors/data_exceptions.dart';
import '../../core/security/security.dart';
import '../../repositories/media_storage_repository.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/media_picker_service.dart';

/// Production Firebase Storage implementation for Omni-Capture media assets.
/// Media paths are strictly scoped under `users/{uid}/captures/{captureId}/original.{extension}`.
class FirebaseMediaStorageRepository implements MediaStorageRepository {
  final FirebaseStorage? _storageOverride;
  final FirebaseAuth? _authOverride;

  FirebaseMediaStorageRepository({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _storageOverride = storage,
        _authOverride = auth;

  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  String get _uid {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw RecallrDataException.unauthenticated();
      }
      return user.uid;
    } on RecallrDataException {
      rethrow;
    } catch (_) {
      throw RecallrDataException.unauthenticated();
    }
  }

  String _inferExtension(String filename, String mimeType) {
    if (filename.contains('.')) {
      final ext = filename.split('.').last.toLowerCase();
      if (ext.isNotEmpty && ext.length <= 5) return ext;
    }
    if (mimeType == 'image/png') return 'png';
    if (mimeType == 'image/webp') return 'webp';
    if (mimeType == 'image/gif') return 'gif';
    if (mimeType == 'audio/m4a') return 'm4a';
    if (mimeType == 'audio/aac') return 'aac';
    if (mimeType == 'audio/wav') return 'wav';
    if (mimeType == 'audio/mpeg' || mimeType == 'audio/mp3') return 'mp3';
    return mimeType.startsWith('audio/') ? 'm4a' : 'jpg';
  }

  @override
  Future<UploadMediaResult> uploadCaptureImage({
    required String captureId,
    required PickedMediaFile file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uid = _uid;

      if (!InputSanitizer.isValidMimeType(file.mimeType, InputSanitizer.defaultAllowedMimes)) {
        throw RecallrDataException.invalidData('Unsupported media MIME type: ${file.mimeType}');
      }
      if (file.bytes != null && !InputSanitizer.isValidFileSize(file.bytes!.length)) {
        throw RecallrDataException.invalidData('File exceeds maximum upload size (25 MB)');
      }

      final extension = _inferExtension(file.name, file.mimeType);
      final storagePath = 'users/$uid/captures/$captureId/original.$extension';

      if (!InputSanitizer.isValidStoragePath(storagePath, uid)) {
        throw RecallrDataException.invalidData('Invalid or malformed storage path.');
      }

      final storageRef = _storage.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: file.mimeType,
        customMetadata: {
          'captureId': captureId,
          'userId': uid,
          'originalFilename': file.name,
        },
      );

      UploadTask uploadTask;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        uploadTask = storageRef.putData(file.bytes!, metadata);
      } else {
        final localFile = File(file.path);
        if (!await localFile.exists()) {
          throw RecallrDataException.notFound(
            'Local capture media file not found.',
          );
        }
        final fileSize = await localFile.length();
        if (!InputSanitizer.isValidFileSize(fileSize)) {
          throw RecallrDataException.invalidData('File exceeds maximum upload size (25 MB)');
        }
        uploadTask = storageRef.putFile(localFile, metadata);
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0 && onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      final snapshot = await uploadTask;
      final mediaUrl = await snapshot.ref.getDownloadURL();

      return UploadMediaResult(
        mediaUrl: mediaUrl,
        storagePath: storagePath,
        mimeType: file.mimeType,
        fileSize: snapshot.totalBytes > 0 ? snapshot.totalBytes : file.size,
      );
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<UploadMediaResult> uploadCaptureAudio({
    required String captureId,
    required RecordedAudioFile file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uid = _uid;

      if (!InputSanitizer.isValidMimeType(file.mimeType, InputSanitizer.defaultAllowedMimes)) {
        throw RecallrDataException.invalidData('Unsupported audio MIME type: ${file.mimeType}');
      }
      if (file.bytes != null && !InputSanitizer.isValidFileSize(file.bytes!.length)) {
        throw RecallrDataException.invalidData('Audio file exceeds maximum upload size (25 MB)');
      }

      final extension = _inferExtension(file.name, file.mimeType);
      final storagePath = 'users/$uid/captures/$captureId/original.$extension';

      if (!InputSanitizer.isValidStoragePath(storagePath, uid)) {
        throw RecallrDataException.invalidData('Invalid or malformed audio storage path.');
      }

      final storageRef = _storage.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: file.mimeType,
        customMetadata: {
          'captureId': captureId,
          'userId': uid,
          'originalFilename': file.name,
          'durationSeconds': file.duration.inSeconds.toString(),
        },
      );

      UploadTask uploadTask;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        uploadTask = storageRef.putData(file.bytes!, metadata);
      } else {
        final localFile = File(file.path);
        if (!await localFile.exists()) {
          throw RecallrDataException.notFound(
            'Recorded audio file not found on device.',
          );
        }
        final fileSize = await localFile.length();
        if (!InputSanitizer.isValidFileSize(fileSize)) {
          throw RecallrDataException.invalidData('Audio file exceeds maximum upload size (25 MB)');
        }
        uploadTask = storageRef.putFile(localFile, metadata);
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0 && onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      final snapshot = await uploadTask;
      final mediaUrl = await snapshot.ref.getDownloadURL();

      return UploadMediaResult(
        mediaUrl: mediaUrl,
        storagePath: storagePath,
        mimeType: file.mimeType,
        fileSize: snapshot.totalBytes > 0 ? snapshot.totalBytes : file.size,
      );
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> deleteCaptureMedia({
    required String captureId,
    required String storagePath,
  }) async {
    try {
      // Validate that the storage path belongs to the current authenticated user
      final uid = _uid;
      if (!storagePath.startsWith('users/$uid/captures/$captureId/')) {
        throw RecallrDataException.permissionDenied(
          'Unauthorized storage path mutation.',
        );
      }
      final storageRef = _storage.ref().child(storagePath);
      await storageRef.delete();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }
}