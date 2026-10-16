import '../features/capture/models/capture_models.dart';
import '../features/capture/models/capture_processing_models.dart';

/// Abstract contract for processing ingested captures and persisting derived intelligence.
abstract class CaptureProcessingRepository {
  /// Initiates asynchronous processing for a captured item and returns updated CaptureItem.
  Future<CaptureItem> processCapture(CaptureItem capture);

  /// Retrieves the current processing result/metadata for a capture document.
  Future<CaptureProcessingResult?> getProcessingResult(String captureId);

  /// Streams real-time processing result updates for a specific capture.
  Stream<CaptureProcessingResult> streamProcessingResult(String captureId);

  /// Updates the processing status, error, or derived extraction results of a capture.
  Future<void> updateProcessingStatus(
    String captureId,
    CaptureProcessingStatus status, {
    String? errorMessage,
    CaptureProcessingResult? result,
  });

  /// Retries processing for a previously failed capture without creating duplicate records.
  Future<CaptureItem> retryProcessing(String captureId);
}