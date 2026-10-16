import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/errors/data_exceptions.dart';
import '../../features/capture/models/ocr_models.dart';
import 'ocr_service.dart';

/// Production on-device OCR implementation leveraging Google ML Kit Text Recognition.
/// Operates locally on the physical mobile device without cloud API keys or external server calls.
class MlKitOcrService implements OcrService {
  final TextRecognizer _recognizer;
  bool _isDisposed = false;

  MlKitOcrService({TextRecognitionScript script = TextRecognitionScript.latin})
      : _recognizer = TextRecognizer(script: script);

  @override
  Future<OcrResult> extractText({
    required String mediaPath,
    String? mimeType,
  }) async {
    if (_isDisposed) {
      throw RecallrDataException.invalidData('OCR service has been disposed.');
    }

    if (mediaPath.trim().isEmpty) {
      return OcrResult.empty;
    }

    final file = File(mediaPath);
    if (!file.existsSync()) {
      // If file does not exist locally (e.g. cloud URL or unretrieved asset), return empty gracefully
      return OcrResult.empty;
    }

    try {
      final inputImage = InputImage.fromFilePath(mediaPath);
      final recognizedText = await _recognizer.processImage(inputImage);

      final blocks = <OcrTextBlock>[];
      final allLines = <OcrTextLine>[];

      for (final block in recognizedText.blocks) {
        final blockLines = <OcrTextLine>[];
        for (final line in block.lines) {
          final ocrLine = OcrTextLine(
            text: line.text,
            confidence: line.confidence,
          );
          blockLines.add(ocrLine);
          allLines.add(ocrLine);
        }

        final rect = block.boundingBox;
        blocks.add(
          OcrTextBlock(
            text: block.text,
            boundingBox: {
              'left': rect.left.toDouble(),
              'top': rect.top.toDouble(),
              'width': rect.width.toDouble(),
              'height': rect.height.toDouble(),
            },
            lines: blockLines,
          ),
        );
      }

      return OcrResult(
        text: recognizedText.text,
        blocks: blocks,
        lines: allLines,
        metadata: {
          'provider': 'Google ML Kit On-Device',
          'blockCount': blocks.length,
          'lineCount': allLines.length,
        },
      );
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _isDisposed = true;
      await _recognizer.close();
    }
  }
}