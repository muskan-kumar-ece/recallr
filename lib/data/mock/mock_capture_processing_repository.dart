import 'dart:async';
import '../../core/errors/data_exceptions.dart';
import '../../features/capture/models/capture_models.dart';
import '../../features/capture/models/capture_processing_models.dart';
import '../../repositories/capture_processing_repository.dart';
import '../../services/capture_processing_service.dart';
import '../../services/mock_capture_processing_service.dart';

/// Mock implementation of CaptureProcessingRepository for unit/widget testing and offline preview.
class MockCaptureProcessingRepository implements CaptureProcessingRepository {
  final Map<String, CaptureProcessingResult> _results = {};
  final Map<String, CaptureItem> _items = {};
  final Map<String, StreamController<CaptureProcessingResult>> _streamControllers = {};
  final CaptureProcessingService _service;

  bool shouldThrowUnauthenticated;
  bool shouldThrowError;
  Duration simulatedDelay;
  String errorMessage;
  int processCalls = 0;
  int retryCalls = 0;

  MockCaptureProcessingRepository({
    CaptureProcessingService? service,
    this.shouldThrowUnauthenticated = false,
    this.shouldThrowError = false,
    this.simulatedDelay = Duration.zero,
    this.errorMessage = 'Simulated processing error',
    List<CaptureItem>? initialItems,
  }) : _service = service ?? MockCaptureProcessingService() {
    if (initialItems != null) {
      for (final item in initialItems) {
        _items[item.id] = item;
        _results[item.id] = CaptureProcessingResult(
          captureId: item.id,
          status: item.processingStatus ?? CaptureProcessingStatus.completed,
          summary: item.summary,
          extractedText: item.extractedText,
          confidence: item.confidence,
        );
      }
    }
  }

  Map<String, CaptureProcessingResult> get results => Map.unmodifiable(_results);

  StreamController<CaptureProcessingResult> _controllerFor(String captureId) {
    return _streamControllers.putIfAbsent(
      captureId,
      () => StreamController<CaptureProcessingResult>.broadcast(),
    );
  }

  @override
  Future<CaptureItem> processCapture(CaptureItem capture) async {
    processCalls++;
    if (shouldThrowUnauthenticated) {
      throw RecallrDataException.unauthenticated();
    }
    if (shouldThrowError) {
      final failResult = CaptureProcessingResult(
        captureId: capture.id,
        status: CaptureProcessingStatus.failed,
        errorMessage: errorMessage,
      );
      _results[capture.id] = failResult;
      _controllerFor(capture.id).add(failResult);
      throw RecallrDataException.networkUnavailable(errorMessage);
    }

    // Set processing status
    final processingResult = CaptureProcessingResult(
      captureId: capture.id,
      status: CaptureProcessingStatus.processing,
    );
    _results[capture.id] = processingResult;
    _controllerFor(capture.id).add(processingResult);

    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    final result = await _service.processCapture(capture);
    _results[capture.id] = result;
    _controllerFor(capture.id).add(result);

    final updated = capture.copyWith(
      processingStatus: result.status,
      processedAt: result.processedAt ?? DateTime.now(),
      extractedText: result.extractedText,
      summary: result.summary,
      confidence: result.confidence,
      processingError: result.errorMessage,
      resolvedPersonId: result.metadata?['resolvedPersonId']?.toString(),
      entityResolutionStatus: result.metadata?['entityResolutionStatus']?.toString(),
      entityResolutionConfidence: result.confidence,
      entityResolutionAt: DateTime.now(),
      entityResolutionSource: 'Mock Capture Intelligence',
      linkedActivityId: result.metadata?['linkedActivityId']?.toString(),
    );
    _items[capture.id] = updated;
    return updated;
  }

  @override
  Future<CaptureProcessingResult?> getProcessingResult(String captureId) async {
    if (shouldThrowUnauthenticated) {
      throw RecallrDataException.unauthenticated();
    }
    if (shouldThrowError) {
      throw RecallrDataException.networkUnavailable(errorMessage);
    }
    return _results[captureId];
  }

  @override
  Stream<CaptureProcessingResult> streamProcessingResult(String captureId) {
    if (shouldThrowUnauthenticated) {
      return Stream.error(RecallrDataException.unauthenticated());
    }
    if (shouldThrowError) {
      return Stream.error(RecallrDataException.networkUnavailable(errorMessage));
    }

    final controller = _controllerFor(captureId);
    final current = _results[captureId];
    if (current != null) {
      Timer.run(() => controller.add(current));
    }
    return controller.stream;
  }

  @override
  Future<void> updateProcessingStatus(
    String captureId,
    CaptureProcessingStatus status, {
    String? errorMessage,
    CaptureProcessingResult? result,
  }) async {
    if (shouldThrowUnauthenticated) {
      throw RecallrDataException.unauthenticated();
    }
    if (shouldThrowError) {
      throw RecallrDataException.networkUnavailable(this.errorMessage);
    }

    final updated = CaptureProcessingResult(
      captureId: captureId,
      status: status,
      processedAt: status == CaptureProcessingStatus.completed ? DateTime.now() : null,
      errorMessage: errorMessage,
      summary: result?.summary,
      extractedText: result?.extractedText,
      confidence: result?.confidence,
    );
    _results[captureId] = updated;
    _controllerFor(captureId).add(updated);
  }

  @override
  Future<CaptureItem> retryProcessing(String captureId) async {
    retryCalls++;
    final item = _items[captureId] ??
        CaptureItem(
          id: captureId,
          type: CaptureType.note,
          title: 'Retry Item',
          description: 'Description',
          timestamp: 'Just now',
          targetRoute: '/activity',
        );
    return processCapture(item);
  }

  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}