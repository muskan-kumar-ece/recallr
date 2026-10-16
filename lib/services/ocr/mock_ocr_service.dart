import 'dart:async';
import '../../core/errors/data_exceptions.dart';
import '../../features/capture/models/ocr_models.dart';
import 'ocr_service.dart';

/// Deterministic mock implementation of OcrService for unit, widget, and offline testing.
class MockOcrService implements OcrService {
  bool shouldFail;
  String errorMessage;
  Duration simulatedDelay;
  String? customResultText;
  double customConfidence;
  int extractCalls = 0;

  MockOcrService({
    this.shouldFail = false,
    this.errorMessage = 'Simulated OCR extraction failure.',
    this.simulatedDelay = Duration.zero,
    this.customResultText,
    this.customConfidence = 0.95,
  });

  @override
  Future<OcrResult> extractText({
    required String mediaPath,
    String? mimeType,
  }) async {
    extractCalls++;

    if (shouldFail) {
      throw RecallrDataException.networkUnavailable(errorMessage);
    }

    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (mediaPath.trim().isEmpty) {
      return OcrResult.empty;
    }

    final text = customResultText ?? _generateDeterministicText(mediaPath);
    if (text.trim().isEmpty) {
      return OcrResult.empty;
    }

    final lines = text
        .split('\n')
        .map((l) => OcrTextLine(text: l, confidence: customConfidence))
        .toList();

    final blocks = [
      OcrTextBlock(
        text: text,
        confidence: customConfidence,
        boundingBox: {'left': 0.0, 'top': 0.0, 'width': 300.0, 'height': 200.0},
        lines: lines,
      ),
    ];

    return OcrResult(
      text: text,
      confidence: customConfidence,
      language: 'en',
      blocks: blocks,
      lines: lines,
      metadata: {
        'provider': 'Mock Deterministic OCR',
        'mediaPath': mediaPath,
      },
    );
  }

  String _generateDeterministicText(String path) {
    final lower = path.toLowerCase();
    if (lower.contains('card') || lower.contains('business') || lower.contains('camera')) {
      return 'Arjun Mehta\nPartner\nNexus Venture Partners\narjun.mehta@nexusvp.com\n+91 98450 12345\nBengaluru, India';
    }
    if (lower.contains('doc') || lower.contains('spec') || lower.contains('pdf')) {
      return 'Specification v2.4\n1.2V Core Logic\nElena Rostova\nApex Photonics\nZurich Labs\n2026-08-28';
    }
    if (lower.contains('empty') || lower.contains('blank')) {
      return '';
    }
    return 'Whiteboard Architecture Session\nRISC-V Neuromorphic Core\nSarah Chen\nMosaic Neuromorphic\nSan Francisco\n2026-08-28';
  }

  @override
  Future<void> dispose() async {}
}