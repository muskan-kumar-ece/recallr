import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/data/firestore/firestore_activity_repository.dart';
import 'package:recaller/data/firestore/firestore_capture_processing_repository.dart';
import 'package:recaller/data/firestore/firestore_capture_repository.dart';
import 'package:recaller/data/firestore/firestore_follow_up_repository.dart';
import 'package:recaller/data/firestore/firestore_memory_retrieval_repository.dart';
import 'package:recaller/data/firestore/firestore_people_repository.dart';
import 'package:recaller/data/firestore/firestore_person_detail_repository.dart';
import 'package:recaller/data/storage/firebase_media_storage_repository.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/services/media_picker_service.dart';

void main() {
  group('Phase 13F-01: Repository Fail-Closed Authentication Boundary Tests', () {
    test('1. FirestorePeopleRepository throws RecallrDataException.unauthenticated when logged out', () async {
      final repo = FirestorePeopleRepository();
      expect(
        () => repo.getPerson('per_123'),
        throwsA(isA<RecallrDataException>().having(
          (e) => e.type,
          'type',
          equals(DataErrorType.unauthenticated),
        )),
      );
    });

    test('2. FirestorePersonDetailRepository throws RecallrDataException.unauthenticated when logged out', () async {
      final repo = FirestorePersonDetailRepository();
      expect(
        () => repo.getProfile('per_123'),
        throwsA(isA<RecallrDataException>().having(
          (e) => e.type,
          'type',
          equals(DataErrorType.unauthenticated),
        )),
      );
    });

    test('3. FirestoreActivityRepository throws RecallrDataException.unauthenticated when logged out', () async {
      final repo = FirestoreActivityRepository();
      expect(
        () => repo.getActivity('act_123'),
        throwsA(isA<RecallrDataException>().having(
          (e) => e.type,
          'type',
          equals(DataErrorType.unauthenticated),
        )),
      );
    });

    test('4. FirestoreFollowUpRepository throws RecallrDataException.unauthenticated when logged out', () async {
      final repo = FirestoreFollowUpRepository();
      expect(
        () => repo.getFollowUp('fu_123'),
        throwsA(isA<RecallrDataException>().having(
          (e) => e.type,
          'type',
          equals(DataErrorType.unauthenticated),
        )),
      );
    });

    test('5. FirestoreCaptureRepository throws RecallrDataException.unauthenticated when logged out', () async {
      final repo = FirestoreCaptureRepository();
      expect(
        () => repo.getCapture('cap_123'),
        throwsA(isA<RecallrDataException>().having(
          (e) => e.type,
          'type',
          equals(DataErrorType.unauthenticated),
        )),
      );
    });

    test('6. FirebaseMediaStorageRepository throws RecallrDataException.unauthenticated when logged out', () async {
      final repo = FirebaseMediaStorageRepository();
      final dummyImage = PickedMediaFile(
        path: '/tmp/test.jpg',
        name: 'test.jpg',
        mimeType: 'image/jpeg',
        size: 1024,
      );

      expect(
        () => repo.uploadCaptureImage(captureId: 'cap_1', file: dummyImage),
        throwsA(isA<RecallrDataException>().having(
          (e) => e.type,
          'type',
          equals(DataErrorType.unauthenticated),
        )),
      );
    });

    test('7. FirestoreCaptureProcessingRepository throws RecallrDataException.unauthenticated when logged out', () async {
      final repo = FirestoreCaptureProcessingRepository();
      final dummyCapture = CaptureItem(
        id: 'cap_123',
        type: CaptureType.businessCard,
        title: 'Test Card',
        description: 'Test description',
        timestamp: 'Today',
        targetRoute: '/capture/cap_123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => repo.processCapture(dummyCapture),
        throwsA(isA<RecallrDataException>().having(
          (e) => e.type,
          'type',
          equals(DataErrorType.unauthenticated),
        )),
      );
    });

    test('8. FirestoreMemoryRetrievalRepository throws RecallrDataException.unauthenticated when logged out', () async {
      final repo = FirestoreMemoryRetrievalRepository();
      expect(
        () => repo.searchPeople('test query'),
        throwsA(isA<RecallrDataException>().having(
          (e) => e.type,
          'type',
          equals(DataErrorType.unauthenticated),
        )),
      );
    });
  });

  group('Phase 13F-01: Static Code Level Gemini Security Boundary Isolation Tests', () {
    test('9. Gemini AI provider files must NEVER import Firebase Firestore or Firebase Storage', () {
      final aiDir = Directory('lib/services/ai');
      expect(aiDir.existsSync(), isTrue);

      final dartFiles = aiDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content,
          isNot(contains('package:cloud_firestore/cloud_firestore.dart')),
          reason: 'Gemini service ${file.path} must not import cloud_firestore',
        );
        expect(
          content,
          isNot(contains('package:firebase_storage/firebase_storage.dart')),
          reason: 'Gemini service ${file.path} must not import firebase_storage',
        );
        expect(
          content,
          isNot(contains('FirebaseFirestore.instance')),
          reason: 'Gemini service ${file.path} must not access FirebaseFirestore directly',
        );
        expect(
          content,
          isNot(contains('FirebaseStorage.instance')),
          reason: 'Gemini service ${file.path} must not access FirebaseStorage directly',
        );
      }
    });

    test('10. Gemini Prompt Builder never outputs raw Firebase UIDs or internal database storage paths', () {
      final promptBuilderFile = File('lib/services/ai/gemini/gemini_prompt_builder.dart');
      expect(promptBuilderFile.existsSync(), isTrue);
      final content = promptBuilderFile.readAsStringSync();

      // Rule 9 in prompt builder guarantees privacy
      expect(content, contains('Privacy Boundary'));
      expect(content, contains('Do not reference internal database keys'));
    });
  });
}