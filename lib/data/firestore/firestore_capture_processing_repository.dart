import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/data_exceptions.dart';
import '../../features/capture/models/capture_models.dart';
import '../../features/capture/models/capture_processing_models.dart';
import '../../repositories/capture_processing_repository.dart';
import '../../services/capture_processing_service.dart';

/// Production Firestore implementation of CaptureProcessingRepository.
/// Manages processing state transitions and persists derived intelligence
/// directly to the canonical capture document at `/users/{uid}/captures/{captureId}`.
class FirestoreCaptureProcessingRepository implements CaptureProcessingRepository {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;
  final CaptureProcessingService _processingService;

  FirestoreCaptureProcessingRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    CaptureProcessingService? processingService,
  })  : _firestoreOverride = firestore,
        _authOverride = auth,
        _processingService = processingService ?? const DeterministicCaptureProcessingService();

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  String get _uid {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw RecallrDataException.unauthenticated();
      }
      return user.uid;
    } on RecallrDataException {
      rethrow;
    } catch (_) {
      throw RecallrDataException.unauthenticated();
    }
  }

  DocumentReference<Map<String, dynamic>> _captureDoc(String captureId) {
    final uid = _uid;
    return _firestore.collection('users').doc(uid).collection('captures').doc(captureId);
  }

  @override
  Future<CaptureItem> processCapture(CaptureItem capture) async {
    try {
      final docRef = _captureDoc(capture.id);

      // Transition to processing state
      await docRef.set({
        'processingStatus': CaptureProcessingStatus.processing.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      CaptureProcessingResult result;
      try {
        result = await _processingService.processCapture(capture);
      } catch (e, st) {
        final errorMsg = e is RecallrDataException ? e.message : e.toString();
        await docRef.set({
          'processingStatus': CaptureProcessingStatus.failed.name,
          'processingError': errorMsg,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (e is RecallrDataException) rethrow;
        throw RecallrDataException.fromException(e, st);
      }

      final resPersonId = result.metadata?['resolvedPersonId']?.toString();
      final resStatus = result.metadata?['entityResolutionStatus']?.toString();
      final linkedActId = result.metadata?['linkedActivityId']?.toString();

      // Successful extraction: persist derived fields to capture document
      await docRef.set({
        'processingStatus': CaptureProcessingStatus.completed.name,
        'processedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'extractedText': result.extractedText,
        'summary': result.summary,
        'confidence': result.confidence,
        'processingError': null,
        'resolvedPersonId': resPersonId,
        'entityResolutionStatus': resStatus,
        'entityResolutionConfidence': result.confidence,
        'entityResolutionAt': FieldValue.serverTimestamp(),
        'entityResolutionSource': 'Omni-Capture Intelligence',
        'linkedActivityId': linkedActId,
        'relationshipMemoryStatus': 'completed',
      }, SetOptions(merge: true));

      return capture.copyWith(
        processingStatus: CaptureProcessingStatus.completed,
        processedAt: DateTime.now(),
        extractedText: result.extractedText,
        summary: result.summary,
        confidence: result.confidence,
        processingError: null,
        resolvedPersonId: resPersonId,
        entityResolutionStatus: resStatus,
        entityResolutionConfidence: result.confidence,
        entityResolutionAt: DateTime.now(),
        entityResolutionSource: 'Omni-Capture Intelligence',
        linkedActivityId: linkedActId,
      );
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<CaptureProcessingResult?> getProcessingResult(String captureId) async {
    try {
      final doc = await _captureDoc(captureId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return CaptureProcessingResult.fromFirestore(doc);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Stream<CaptureProcessingResult> streamProcessingResult(String captureId) {
    try {
      return _captureDoc(captureId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          throw RecallrDataException.notFound('Capture record not found.');
        }
        return CaptureProcessingResult.fromFirestore(doc);
      });
    } catch (e, st) {
      if (e is RecallrDataException) {
        return Stream.error(e);
      }
      return Stream.error(RecallrDataException.fromException(e, st));
    }
  }

  @override
  Future<void> updateProcessingStatus(
    String captureId,
    CaptureProcessingStatus status, {
    String? errorMessage,
    CaptureProcessingResult? result,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'processingStatus': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == CaptureProcessingStatus.completed) {
        updateData['processedAt'] = FieldValue.serverTimestamp();
        updateData['processingError'] = null;
        if (result != null) {
          if (result.extractedText != null) updateData['extractedText'] = result.extractedText;
          if (result.summary != null) updateData['summary'] = result.summary;
          if (result.confidence != null) updateData['confidence'] = result.confidence;
        }
      } else if (status == CaptureProcessingStatus.failed) {
        updateData['processingError'] = errorMessage ?? 'Capture processing failed.';
      }

      await _captureDoc(captureId).set(updateData, SetOptions(merge: true));
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<CaptureItem> retryProcessing(String captureId) async {
    try {
      final doc = await _captureDoc(captureId).get();
      if (!doc.exists || doc.data() == null) {
        throw RecallrDataException.notFound('Capture item not found for retry.');
      }
      final item = CaptureItem.fromFirestore(doc);
      return await processCapture(item);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }
}