import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../core/errors/data_exceptions.dart';

/// Domain representation of a locally picked media file ready for preview and upload.
class PickedMediaFile {
  final String path;
  final String name;
  final int size;
  final String mimeType;
  final Uint8List? bytes;

  const PickedMediaFile({
    required this.path,
    required this.name,
    required this.size,
    required this.mimeType,
    this.bytes,
  });

  @override
  String toString() => 'PickedMediaFile(name: $name, size: $size, mimeType: $mimeType, path: $path)';
}

/// Abstract contract for device camera, photo gallery, and document selection.
abstract class MediaPickerService {
  /// Captures a new image using the device camera. Returns null if cancelled.
  Future<PickedMediaFile?> pickFromCamera();

  /// Selects an existing image from the device photo gallery. Returns null if cancelled.
  Future<PickedMediaFile?> pickFromGallery();

  /// Opens a document picker (PDF, text, spreadsheet, etc.). Returns null if cancelled.
  /// On platforms where no file picker is available this must return null,
  /// never fabricate a file.
  Future<PickedMediaFile?> pickDocument();
}

/// Production implementation of MediaPickerService utilizing the image_picker package.
/// Document picking uses image_picker's gallery path with any-type selection as a
/// best-effort fallback until a dedicated file_picker is integrated.
class DeviceMediaPickerService implements MediaPickerService {
  final ImagePicker _picker;

  DeviceMediaPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  String _inferMimeType(String path, String? reportedMime) {
    if (reportedMime != null && reportedMime.isNotEmpty) {
      return reportedMime;
    }
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    return 'image/jpeg';
  }

  Future<PickedMediaFile?> _convertXFile(XFile? xFile) async {
    if (xFile == null) return null;
    try {
      final size = await xFile.length();
      final mimeType = _inferMimeType(xFile.path, xFile.mimeType);
      final bytes = await xFile.readAsBytes();
      return PickedMediaFile(
        path: xFile.path,
        name: xFile.name,
        size: size,
        mimeType: mimeType,
        bytes: bytes,
      );
    } catch (e, st) {
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<PickedMediaFile?> pickFromCamera() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      return await _convertXFile(xFile);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<PickedMediaFile?> pickFromGallery() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      return await _convertXFile(xFile);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<PickedMediaFile?> pickDocument() async {
    // image_picker does not support arbitrary document picking.
    // Return null to indicate the capability is unavailable on this platform/build.
    // Integrate a dedicated file picker package to enable real document selection.
    return null;
  }
}

/// Mock implementation of MediaPickerService for deterministic unit & widget testing.
class MockMediaPickerService implements MediaPickerService {
  PickedMediaFile? mockFile;
  PickedMediaFile? mockDocumentFile;
  bool shouldCancel;
  bool shouldThrow;

  MockMediaPickerService({
    this.mockFile,
    this.mockDocumentFile,
    this.shouldCancel = false,
    this.shouldThrow = false,
  });

  static PickedMediaFile createDefaultMockFile({
    String path = '/mock/photos/whiteboard_matrix.jpg',
    String name = 'whiteboard_matrix.jpg',
    int size = 1843200, // ~1.8 MB
    String mimeType = 'image/jpeg',
  }) {
    return PickedMediaFile(
      path: path,
      name: name,
      size: size,
      mimeType: mimeType,
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
    );
  }

  static PickedMediaFile createDefaultMockDocumentFile({
    String path = '/mock/documents/spec_sheet.pdf',
    String name = 'spec_sheet.pdf',
    int size = 524288, // ~512 KB
    String mimeType = 'application/pdf',
  }) {
    return PickedMediaFile(
      path: path,
      name: name,
      size: size,
      mimeType: mimeType,
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]), // PDF magic bytes
    );
  }

  @override
  Future<PickedMediaFile?> pickFromCamera() async {
    if (shouldThrow) throw RecallrDataException.permissionDenied();
    if (shouldCancel) return null;
    return mockFile ?? createDefaultMockFile(name: 'camera_capture.jpg', path: '/mock/photos/camera_capture.jpg');
  }

  @override
  Future<PickedMediaFile?> pickFromGallery() async {
    if (shouldThrow) throw RecallrDataException.permissionDenied();
    if (shouldCancel) return null;
    return mockFile ?? createDefaultMockFile(name: 'gallery_upload.jpg', path: '/mock/photos/gallery_upload.jpg');
  }

  @override
  Future<PickedMediaFile?> pickDocument() async {
    if (shouldThrow) throw RecallrDataException.permissionDenied();
    if (shouldCancel) return null;
    return mockDocumentFile ?? createDefaultMockDocumentFile();
  }
}