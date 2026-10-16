import '../../features/capture/models/ocr_models.dart';

/// Provider-agnostic interface for optical character recognition & text extraction.
abstract class OcrService {
  /// Extracts text and structural bounding metadata from a local image/document file path.
  Future<OcrResult> extractText({
    required String mediaPath,
    String? mimeType,
  });

  /// Releases platform OCR recognizer resources.
  Future<void> dispose();
}