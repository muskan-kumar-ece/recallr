import 'dart:async';
import '../features/capture/models/capture_models.dart';
import '../features/capture/models/capture_processing_models.dart';
import '../features/capture/models/entity_resolution_models.dart';
import '../features/capture/models/ocr_models.dart';
import 'entity_resolution_service.dart';
import 'ocr/ocr_entity_extractor.dart';
import 'ocr/ocr_service.dart';

/// Abstract service contract for multimodal capture processing and entity detection.
abstract class CaptureProcessingService {
  Future<CaptureProcessingResult> processCapture(CaptureItem capture);
  Future<CaptureProcessingResult> processImage(CaptureItem capture);
  Future<CaptureProcessingResult> processVoice(CaptureItem capture);
  Future<CaptureProcessingResult> processDocument(CaptureItem capture);
  Future<CaptureProcessingResult> processNote(CaptureItem capture);
}

/// Deterministic, provider-agnostic production implementation of CaptureProcessingService.
/// Prepares structured metadata, entity graphs, and resolves canonical People identities.
class DeterministicCaptureProcessingService implements CaptureProcessingService {
  final Duration simulatedLatency;
  final OcrService? ocrService;
  final EntityResolutionService? entityResolutionService;

  const DeterministicCaptureProcessingService({
    this.simulatedLatency = const Duration(milliseconds: 50),
    this.ocrService,
    this.entityResolutionService,
  });

  @override
  Future<CaptureProcessingResult> processCapture(CaptureItem capture) async {
    switch (capture.type) {
      case CaptureType.businessCard:
        return _processBusinessCard(capture);
      case CaptureType.photo:
        return processImage(capture);
      case CaptureType.voice:
        return processVoice(capture);
      case CaptureType.document:
        return processDocument(capture);
      case CaptureType.note:
        return processNote(capture);
    }
  }

  Future<CaptureProcessingResult> _processBusinessCard(CaptureItem capture) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    final ocr = ocrService != null
        ? await (() async {
            try {
              return await ocrService!.extractText(
                mediaPath: capture.localFilePath ?? '',
                mimeType: capture.mimeType,
              );
            } catch (_) {
              return OcrResult.empty;
            }
          })()
        : OcrResult.empty;

    final rawOcrText = ocr.isNotEmpty ? ocr.text : null;

    final entities = OcrEntityExtractor.extract(rawOcrText ?? '');

    EntityResolutionResult? resolution;
    if (entityResolutionService != null) {
      try {
        resolution = await entityResolutionService!.resolveAndLink(
          capture: capture,
          entities: entities,
        );
      } catch (_) {}
    }

    final personName = resolution?.resolvedPerson?.name ?? entities.name ?? capture.personName;
    final company = resolution?.resolvedPerson?.company ?? entities.company ?? capture.companyName;
    final role = resolution?.resolvedPerson?.role ?? entities.role ?? capture.personRole;

    return CaptureProcessingResult(
      captureId: capture.id,
      status: CaptureProcessingStatus.completed,
      processedAt: DateTime.now(),
      title: personName != null && company != null
          ? 'Business Card: $personName · $company'
          : personName != null
              ? 'Business Card: $personName'
              : 'Business Card',
      summary: personName != null
          ? 'Contact card for $personName${role != null ? ' ($role${company != null ? ' at $company' : ''})' : ''}. Ingested into network graph.'
          : 'Business card captured. No contact details extracted.',
      extractedText: rawOcrText,
      detectedPeople: personName != null ? [personName] : const <String>[],
      detectedCompany: company,
      detectedLocation: entities.location ?? capture.location,
      confidence: ocr.isNotEmpty ? (ocr.confidence ?? 0.0) : 0.0,
      metadata: {
        'role': role,
        'email': entities.email,
        'phone': entities.phone,
        'website': entities.website,
        'modality': 'businessCard',
        'ocrProvider': ocr.isNotEmpty ? (ocr.metadata?['provider'] ?? 'ML Kit') : 'none',
        'resolvedPersonId': resolution?.matchedPersonId,
        'entityResolutionStatus': resolution?.status.name,
        'linkedActivityId': resolution?.createdActivityId,
      },
    );
  }

  @override
  Future<CaptureProcessingResult> processImage(CaptureItem capture) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    final ocr = ocrService != null
        ? await (() async {
            try {
              return await ocrService!.extractText(
                mediaPath: capture.localFilePath ?? '',
                mimeType: capture.mimeType,
              );
            } catch (_) {
              return OcrResult.empty;
            }
          })()
        : OcrResult.empty;

    final rawOcrText = ocr.isNotEmpty
        ? ocr.text
        : (capture.description.isNotEmpty ? capture.description : null);

    final entities = OcrEntityExtractor.extract(rawOcrText ?? '');

    EntityResolutionResult? resolution;
    if (entityResolutionService != null) {
      try {
        resolution = await entityResolutionService!.resolveAndLink(
          capture: capture,
          entities: entities,
        );
      } catch (_) {}
    }

    final people = resolution?.resolvedPerson != null
        ? [resolution!.resolvedPerson!.name]
        : (entities.name != null
            ? [entities.name!]
            : (capture.personName != null ? [capture.personName!] : const <String>[]));
    final company = resolution?.resolvedPerson?.company ?? entities.company ?? capture.companyName;

    return CaptureProcessingResult(
      captureId: capture.id,
      status: CaptureProcessingStatus.completed,
      processedAt: DateTime.now(),
      title: capture.title.isNotEmpty ? capture.title : 'Photo',
      summary: rawOcrText != null && rawOcrText.isNotEmpty
          ? (rawOcrText.length > 120 ? '${rawOcrText.substring(0, 120)}...' : rawOcrText)
          : 'Image captured. No text extracted.',
      extractedText: rawOcrText,
      detectedPeople: people,
      detectedCompany: company,
      detectedLocation: entities.location ?? capture.location,
      confidence: ocr.isNotEmpty ? (ocr.confidence ?? 0.0) : 0.0,
      metadata: {
        'imageFormat': capture.mimeType ?? 'image/jpeg',
        'modality': 'photo',
        'ocrProvider': ocr.isNotEmpty ? (ocr.metadata?['provider'] ?? 'ML Kit') : 'none',
        'resolvedPersonId': resolution?.matchedPersonId,
        'entityResolutionStatus': resolution?.status.name,
        'linkedActivityId': resolution?.createdActivityId,
      },
    );
  }

  @override
  Future<CaptureProcessingResult> processVoice(CaptureItem capture) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    final now = DateTime.now();
    final titleText = capture.title.isNotEmpty ? capture.title : 'Voice Memo';
    final durationSecs = capture.durationSeconds;
    final durationNote = durationSecs != null && durationSecs > 0
        ? ' (${durationSecs}s)'
        : '';

    return CaptureProcessingResult(
      captureId: capture.id,
      status: CaptureProcessingStatus.completed,
      processedAt: now,
      title: titleText,
      summary: 'Voice recording saved$durationNote. Transcription unavailable — no STT provider configured.',
      extractedText: null,
      detectedPeople: capture.personName != null ? [capture.personName!] : const <String>[],
      detectedCompany: capture.companyName,
      detectedLocation: capture.location,
      detectedDate: capture.timestamp,
      confidence: 0.0,
      metadata: {
        'transcriptionStatus': 'unavailable',
        'reason': 'No STT provider configured. Integrate a speech-to-text service to enable transcription.',
        'captureType': 'voice',
        'audioMime': capture.mimeType ?? 'audio/m4a',
        if (durationSecs != null) 'audioDurationSeconds': durationSecs,
        'modality': 'voice',
        'processedAt': now.toIso8601String(),
      },
    );
  }

  @override
  Future<CaptureProcessingResult> processDocument(CaptureItem capture) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    final ocr = ocrService != null
        ? await (() async {
            try {
              return await ocrService!.extractText(
                mediaPath: capture.localFilePath ?? '',
                mimeType: capture.mimeType,
              );
            } catch (_) {
              return OcrResult.empty;
            }
          })()
        : OcrResult.empty;

    final rawOcrText = ocr.isNotEmpty ? ocr.text : null;

    final entities = OcrEntityExtractor.extract(rawOcrText ?? '');

    EntityResolutionResult? resolution;
    if (entityResolutionService != null) {
      try {
        resolution = await entityResolutionService!.resolveAndLink(
          capture: capture,
          entities: entities,
        );
      } catch (_) {}
    }

    return CaptureProcessingResult(
      captureId: capture.id,
      status: CaptureProcessingStatus.completed,
      processedAt: DateTime.now(),
      title: capture.title.isNotEmpty ? capture.title : 'Document',
      summary: rawOcrText != null && rawOcrText.isNotEmpty
          ? (rawOcrText.length > 120 ? '${rawOcrText.substring(0, 120)}...' : rawOcrText)
          : 'Document captured. No text extracted.',
      extractedText: rawOcrText,
      detectedPeople: resolution?.resolvedPerson != null
          ? [resolution!.resolvedPerson!.name]
          : (entities.name != null
              ? [entities.name!]
              : (capture.personName != null ? [capture.personName!] : const <String>[])),
      detectedCompany: resolution?.resolvedPerson?.company ?? entities.company ?? capture.companyName,
      detectedLocation: entities.location ?? capture.location,
      confidence: ocr.isNotEmpty ? (ocr.confidence ?? 0.0) : 0.0,
      metadata: {
        'documentType': capture.mimeType ?? 'application/pdf',
        'modality': 'document',
        'ocrProvider': ocr.isNotEmpty ? (ocr.metadata?['provider'] ?? 'ML Kit') : 'none',
        'resolvedPersonId': resolution?.matchedPersonId,
        'entityResolutionStatus': resolution?.status.name,
        'linkedActivityId': resolution?.createdActivityId,
      },
    );
  }

  @override
  Future<CaptureProcessingResult> processNote(CaptureItem capture) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    final text = capture.description.isNotEmpty ? capture.description : capture.title;
    final entities = OcrEntityExtractor.extract(text);

    EntityResolutionResult? resolution;
    if (entityResolutionService != null) {
      try {
        resolution = await entityResolutionService!.resolveAndLink(
          capture: capture,
          entities: entities,
        );
      } catch (_) {}
    }

    final people = resolution?.resolvedPerson != null
        ? [resolution!.resolvedPerson!.name]
        : (capture.personName != null ? [capture.personName!] : <String>[]);

    return CaptureProcessingResult(
      captureId: capture.id,
      status: CaptureProcessingStatus.completed,
      processedAt: DateTime.now(),
      title: capture.title.isNotEmpty ? capture.title : 'Encounter Note',
      summary: text.length > 80 ? '${text.substring(0, 80)}...' : text,
      extractedText: text,
      detectedPeople: people,
      detectedCompany: resolution?.resolvedPerson?.company ?? capture.companyName,
      detectedLocation: capture.location,
      confidence: 0.98,
      metadata: {
        'modality': 'note',
        'resolvedPersonId': resolution?.matchedPersonId,
        'entityResolutionStatus': resolution?.status.name,
        'linkedActivityId': resolution?.createdActivityId,
      },
    );
  }
}