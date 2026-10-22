import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 13F-02: Firebase Security Rules Data Model Alignment Tests', () {
    late String firestoreRules;
    late String storageRules;

    setUpAll(() {
      final firestoreFile = File('firestore.rules').existsSync()
          ? File('firestore.rules')
          : File('c:/workflow/testapp/firestore.rules');
      final storageFile = File('storage.rules').existsSync()
          ? File('storage.rules')
          : File('c:/workflow/testapp/storage.rules');

      firestoreRules = firestoreFile.readAsStringSync();
      storageRules = storageFile.readAsStringSync();
    });

    test('1. Firestore rules match all 7 authoritative user subcollections', () {
      final requiredSubcollections = [
        'match /users/{userId}',
        'match /users/{userId}/people/{personId}',
        'match /users/{userId}/activities/{activityId}',
        'match /users/{userId}/follow_ups/{followUpId}',
        'match /users/{userId}/captures/{captureId}',
        'match /users/{userId}/claims/{claimId}',
        'match /users/{userId}/interactions/{interactionId}',
      ];

      for (final subcoll in requiredSubcollections) {
        expect(
          firestoreRules.contains(subcoll),
          isTrue,
          reason: 'Missing subcollection match in firestore.rules: $subcoll',
        );
      }
    });

    test('2. Firestore rules enforce isImmutableOwnerDoc on all update paths', () {
      expect(firestoreRules.contains('function isImmutableOwnerDoc()'), isTrue);
      expect(firestoreRules.contains('allow update: if isOwner(userId) && isImmutableOwnerDoc();'), isTrue);
    });

    test('3. Firestore rules enforce isValidOwnerDoc on all create paths', () {
      expect(firestoreRules.contains('function isValidOwnerDoc(userId)'), isTrue);
      expect(firestoreRules.contains('allow create: if isOwner(userId) && isValidOwnerDoc(userId);'), isTrue);
    });

    test('4. Storage rules match capture media path structure', () {
      expect(
        storageRules.contains('match /users/{userId}/captures/{captureId}/{fileName}'),
        isTrue,
      );
    });

    test('5. Storage rules enforce MIME type whitelist for images, audio, and documents', () {
      expect(storageRules.contains('image/(jpeg|jpg|png|webp|heic)'), isTrue);
      expect(storageRules.contains('audio/(m4a|mp4|aac|mpeg|wav|webm)'), isTrue);
      expect(storageRules.contains("contentType == 'application/pdf'"), isTrue);
    });

    test('6. Storage rules enforce 25MB boundary constraint', () {
      expect(storageRules.contains('25 * 1024 * 1024'), isTrue);
    });

    test('7. Fail-closed fallback: Root unmapped collections are denied', () {
      expect(firestoreRules.contains('match /{document=**}'), isTrue);
      expect(firestoreRules.contains('allow read, write: if false;'), isTrue);

      expect(storageRules.contains('match /{allPaths=**}'), isTrue);
    });
  });
}