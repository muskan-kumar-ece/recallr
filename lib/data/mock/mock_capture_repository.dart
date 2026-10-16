import 'dart:async';
import '../../features/capture/models/capture_mock_data.dart';
import '../../features/capture/models/capture_models.dart';
import '../../repositories/capture_repository.dart';

/// Mock implementation of CaptureRepository using in-memory list.
class MockCaptureRepository implements CaptureRepository {
  final List<CaptureItem> _captures;
  final StreamController<List<CaptureItem>> _controller = StreamController<List<CaptureItem>>.broadcast();

  MockCaptureRepository({List<CaptureItem>? initialCaptures})
      : _captures = initialCaptures != null
            ? List.from(initialCaptures)
            : List.from(CaptureMockData.initialRecentCaptures);

  @override
  Stream<List<CaptureItem>> streamRecentCaptures({int limit = 10}) async* {
    yield _captures.take(limit).toList();
    yield* _controller.stream.map((list) => list.take(limit).toList());
  }

  @override
  Future<CaptureItem> saveCapture(CaptureItem item) async {
    final index = _captures.indexWhere((c) => c.id == item.id);
    if (index != -1) {
      _captures[index] = item;
    } else {
      _captures.insert(0, item);
    }
    _controller.add(_captures);
    return item;
  }

  @override
  Future<CaptureItem?> getCapture(String id) async {
    try {
      return _captures.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteCapture(String id) async {
    _captures.removeWhere((c) => c.id == id);
    _controller.add(_captures);
  }
}