import 'dart:async';
import '../core/errors/data_exceptions.dart';
import '../features/capture/models/capture_models.dart';
import '../features/capture/models/capture_processing_models.dart';
import 'capture_processing_service.dart';

/// Mock implementation of CaptureProcessingService for testing and offline development.
class MockCaptureProcessingService implements CaptureProcessingService {
  bool shouldFail;
  bool shouldThrowUnauthenticated;
  Duration simulatedDelay;
  String errorMessage;
  int processCalls = 0;

  MockCaptureProcessingService({
    this.shouldFail = false,
    this.shouldThrowUnauthenticated = false,
    this.simulatedDelay = Duration.zero,
    this.errorMessage = 'Simulated capture processing failure.',
  });

  @override
  Future<CaptureProcessingResult> processCapture(CaptureItem capture) async {
    processCalls++;
    if (shouldThrowUnauthenticated) {
      throw RecallrDataException.unauthenticated();
    }
    if (shouldFail) {
      throw RecallrDataException.networkUnavailable(errorMessage);
    }
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    final service = DeterministicCaptureProcessingService(simulatedLatency: Duration.zero);
    return service.processCapture(capture);
  }

  @override
  Future<CaptureProcessingResult> processImage(CaptureItem capture) async {
    return processCapture(capture);
  }

  @override
  Future<CaptureProcessingResult> processVoice(CaptureItem capture) async {
    return processCapture(capture);
  }

  @override
  Future<CaptureProcessingResult> processDocument(CaptureItem capture) async {
    return processCapture(capture);
  }

  @override
  Future<CaptureProcessingResult> processNote(CaptureItem capture) async {
    return processCapture(capture);
  }
}