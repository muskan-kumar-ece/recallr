import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/services/capture_processing_service.dart';
import 'package:recaller/services/ai/ai_answer_service.dart';
import 'package:recaller/features/ask/models/ai_answer_models.dart';

void main() {
  group('Phase 13H-08.2: Hardening Regressions', () {
    test('1. No synthetic data in capture processing (CAP-P2, CAP-P3)', () async {
      final service = DeterministicCaptureProcessingService(simulatedLatency: Duration.zero);
      
      final voiceResult = await service.processVoice(
        const CaptureItem(
          id: 'v1', 
          type: CaptureType.voice, 
          title: 'Voice Memo', 
          description: '', 
          timestamp: 'now',
          targetRoute: '/captures/v1',
        )
      );
      
      expect(voiceResult.extractedText, isNull);
      expect(voiceResult.metadata?['transcriptionStatus'], equals('unavailable'));
      expect(voiceResult.summary, contains('Transcription unavailable'));
      expect(voiceResult.detectedPeople, isEmpty);

      final docResult = await service.processDocument(
        const CaptureItem(
          id: 'd1', 
          type: CaptureType.document, 
          title: 'Doc', 
          description: '', 
          timestamp: 'now',
          targetRoute: '/captures/d1',
        )
      );
      
      expect(docResult.extractedText, isNull);
      expect(docResult.detectedPeople, isEmpty);
      expect(docResult.detectedCompany, isNull);
    });

    test('2. AI Answer service fallback is clean', () async {
      final aiService = MockAiAnswerService();
      final answer = await aiService.answer(
        const AiAnswerRequest(query: 'Who did I meet?'),
      );
      
      expect(answer.status, equals(AiAnswerStatus.empty));
      expect(answer.answer, contains('No memory context available'));
      expect(answer.mentionedPeople, isEmpty);
      expect(answer.mentionedCompanies, isEmpty);
    });
  });
}
