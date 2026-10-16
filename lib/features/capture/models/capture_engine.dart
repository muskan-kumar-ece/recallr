import 'capture_mock_data.dart';
import 'capture_models.dart';

/// Simulated asynchronous processing engine for Recallr Omni-Capture Hub.
class CaptureEngine {
  final bool isSimulatedAsync;

  const CaptureEngine({this.isSimulatedAsync = false});

  Future<CaptureReviewData> processCapture(
    CaptureType type, {
    String? customTitle,
    String? customNote,
    String? customPerson,
    String? customCompany,
    String? customEvent,
    String? customLocation,
  }) async {
    if (isSimulatedAsync) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return CaptureMockData.getMockExtraction(
      type,
      customTitle: customTitle,
      customNote: customNote,
      customPerson: customPerson,
      customCompany: customCompany,
      customEvent: customEvent,
      customLocation: customLocation,
    );
  }

  Future<CaptureItem> saveCapture(
    CaptureType type,
    CaptureReviewData data,
  ) async {
    if (isSimulatedAsync) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    final newId = 'cap_${DateTime.now().millisecondsSinceEpoch}';
    return CaptureItem(
      id: newId,
      type: type,
      title: data.title,
      description: data.summary,
      timestamp: 'Just now',
      personId: data.personName != null ? 'per_saved' : null,
      personName: data.personName,
      personRole: data.personRole,
      companyName: data.companyName,
      eventName: data.eventName,
      location: data.location,
      targetRoute: '/captures/$newId',
      isVerified: true,
    );
  }

  List<CaptureItem> getRecentCaptures() {
    return List.from(CaptureMockData.initialRecentCaptures);
  }
}