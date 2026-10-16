/// Aggregate in-memory counters tracking feature execution health across Recallr.
class FeatureHealthMetrics {
  // People domain
  int peopleReads = 0;
  int peopleWrites = 0;
  int peoplePermissionDenied = 0;

  // Capture domain
  int capturesStarted = 0;
  int capturesSaved = 0;
  int mediaUploadsSuccess = 0;
  int mediaUploadsFailed = 0;
  int captureProcessingFailures = 0;

  // OCR domain
  int ocrSuccess = 0;
  int ocrFailed = 0;

  // Entity Resolution domain
  int entityMatched = 0;
  int entityCreated = 0;
  int entityAmbiguous = 0;
  int entityFailed = 0;

  // Relationship Memory domain
  int relationshipEnriched = 0;
  int relationshipFailed = 0;

  // Follow-ups domain
  int followUpsCreated = 0;
  int followUpsCompleted = 0;
  int followUpsFailed = 0;

  // Ask / Gemini AI domain
  int aiQuestions = 0;
  int aiGroundedAnswers = 0;
  int aiEmptyAnswers = 0;
  int geminiSuccess = 0;
  int geminiFallback = 0;
  int geminiTimeout = 0;
  int geminiRateLimited = 0;
  int geminiMalformed = 0;
  int geminiProviderFailures = 0;

  // Auth domain
  int authSignIns = 0;
  int authSignOuts = 0;
  int authFailures = 0;

  Map<String, dynamic> toMap() {
    return {
      'people': {
        'reads': peopleReads,
        'writes': peopleWrites,
        'permissionDenied': peoplePermissionDenied,
      },
      'captures': {
        'started': capturesStarted,
        'saved': capturesSaved,
        'mediaUploadsSuccess': mediaUploadsSuccess,
        'mediaUploadsFailed': mediaUploadsFailed,
        'processingFailures': captureProcessingFailures,
      },
      'ocr': {
        'success': ocrSuccess,
        'failed': ocrFailed,
      },
      'entityResolution': {
        'matched': entityMatched,
        'created': entityCreated,
        'ambiguous': entityAmbiguous,
        'failed': entityFailed,
      },
      'relationshipMemory': {
        'enriched': relationshipEnriched,
        'failed': relationshipFailed,
      },
      'followUps': {
        'created': followUpsCreated,
        'completed': followUpsCompleted,
        'failed': followUpsFailed,
      },
      'ai': {
        'questions': aiQuestions,
        'groundedAnswers': aiGroundedAnswers,
        'emptyAnswers': aiEmptyAnswers,
        'geminiSuccess': geminiSuccess,
        'geminiFallback': geminiFallback,
        'geminiTimeout': geminiTimeout,
        'geminiRateLimited': geminiRateLimited,
        'geminiMalformed': geminiMalformed,
        'geminiProviderFailures': geminiProviderFailures,
      },
      'auth': {
        'signIns': authSignIns,
        'signOuts': authSignOuts,
        'failures': authFailures,
      },
    };
  }

  void reset() {
    peopleReads = 0;
    peopleWrites = 0;
    peoplePermissionDenied = 0;
    capturesStarted = 0;
    capturesSaved = 0;
    mediaUploadsSuccess = 0;
    mediaUploadsFailed = 0;
    captureProcessingFailures = 0;
    ocrSuccess = 0;
    ocrFailed = 0;
    entityMatched = 0;
    entityCreated = 0;
    entityAmbiguous = 0;
    entityFailed = 0;
    relationshipEnriched = 0;
    relationshipFailed = 0;
    followUpsCreated = 0;
    followUpsCompleted = 0;
    followUpsFailed = 0;
    aiQuestions = 0;
    aiGroundedAnswers = 0;
    aiEmptyAnswers = 0;
    geminiSuccess = 0;
    geminiFallback = 0;
    geminiTimeout = 0;
    geminiRateLimited = 0;
    geminiMalformed = 0;
    geminiProviderFailures = 0;
    authSignIns = 0;
    authSignOuts = 0;
    authFailures = 0;
  }
}