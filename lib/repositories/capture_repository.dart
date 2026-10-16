import '../features/capture/models/capture_models.dart';

/// Abstract contract for Omni-Capture Hub intake and memory ingestion.
abstract class CaptureRepository {
  /// Stream recent captures saved by the authenticated user.
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 10});

  /// Persist an ingested memory capture.
  Future<CaptureItem> saveCapture(CaptureItem item);

  /// Fetch a single capture by ID.
  Future<CaptureItem?> getCapture(String id);

  /// Delete a captured item record.
  Future<void> deleteCapture(String id);
}