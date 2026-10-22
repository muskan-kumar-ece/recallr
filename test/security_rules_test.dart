import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/security/security.dart';

void main() {
  group('Phase 13F-01: Firestore Security Rules Analysis & Invariants', () {
    late String firestoreRulesContent;

    setUpAll(() {
      final file = File('firestore.rules');
      final path = file.existsSync() ? 'firestore.rules' : 'c:/workflow/testapp/firestore.rules';
      final resolved = File(path);
      expect(resolved.existsSync(), isTrue, reason: 'firestore.rules must exist');
      firestoreRulesContent = resolved.readAsStringSync();
    });

    test('1. Syntax & version check: uses rules_version = 2', () {
      expect(firestoreRulesContent, contains("rules_version = '2';"));
      expect(firestoreRulesContent, contains('service cloud.firestore'));
    });

    test('2. Root fail-closed rule: unmapped paths match /{document=**} allow read, write: if false', () {
      expect(firestoreRulesContent, contains('match /{document=**}'));
      expect(firestoreRulesContent, contains('allow read, write: if false;'));
    });

    test('3. Authentication helper: isAuthenticated requires request.auth != null', () {
      expect(firestoreRulesContent, contains('function isAuthenticated()'));
      expect(firestoreRulesContent, contains('request.auth != null'));
    });

    test('4. Tenant isolation helper: isOwner requires request.auth.uid == userId', () {
      expect(firestoreRulesContent, contains('function isOwner(userId)'));
      expect(firestoreRulesContent, contains('request.auth.uid == userId'));
    });

    test('5. Ownership immutability: verifies userId cannot be mutated on update', () {
      expect(firestoreRulesContent, contains('function isImmutableOwnerDoc()'));
      expect(firestoreRulesContent, contains('request.resource.data.userId == resource.data.userId'));
    });

    test('6. User profile collection: /users/{userId} enforces isOwner', () {
      expect(firestoreRulesContent, contains('match /users/{userId}'));
      expect(firestoreRulesContent, contains('allow read: if isOwner(userId);'));
      expect(firestoreRulesContent, contains('allow delete: if isOwner(userId);'));
    });

    test('7. People subcollection: /users/{userId}/people/{personId} is explicitly defined and protected', () {
      expect(firestoreRulesContent, contains('match /users/{userId}/people/{personId}'));
    });

    test('8. Activities subcollection: /users/{userId}/activities/{activityId} is explicitly defined and protected', () {
      expect(firestoreRulesContent, contains('match /users/{userId}/activities/{activityId}'));
    });

    test('9. Follow-ups subcollection: /users/{userId}/follow_ups/{followUpId} is explicitly defined and protected', () {
      expect(firestoreRulesContent, contains('match /users/{userId}/follow_ups/{followUpId}'));
    });

    test('10. Captures subcollection: /users/{userId}/captures/{captureId} is explicitly defined and protected', () {
      expect(firestoreRulesContent, contains('match /users/{userId}/captures/{captureId}'));
    });

    test('11. Claims subcollection: /users/{userId}/claims/{claimId} is explicitly defined and protected', () {
      expect(firestoreRulesContent, contains('match /users/{userId}/claims/{claimId}'));
    });

    test('12. Interactions subcollection: /users/{userId}/interactions/{interactionId} is explicitly defined and protected', () {
      expect(firestoreRulesContent, contains('match /users/{userId}/interactions/{interactionId}'));
    });

    test('13. No open or public rules: forbids allow read, write: if true', () {
      expect(firestoreRulesContent, isNot(contains('allow read: if true;')));
      expect(firestoreRulesContent, isNot(contains('allow write: if true;')));
      expect(firestoreRulesContent, isNot(contains('allow read, write: if true;')));
    });
  });

  group('Phase 13F-01: Firebase Storage Security Rules Analysis & Invariants', () {
    late String storageRulesContent;

    setUpAll(() {
      final file = File('storage.rules');
      final path = file.existsSync() ? 'storage.rules' : 'c:/workflow/testapp/storage.rules';
      final resolved = File(path);
      expect(resolved.existsSync(), isTrue, reason: 'storage.rules must exist');
      storageRulesContent = resolved.readAsStringSync();
    });

    test('14. Storage version check: uses rules_version = 2 and service firebase.storage', () {
      expect(storageRulesContent, contains("rules_version = '2';"));
      expect(storageRulesContent, contains('service firebase.storage'));
    });

    test('15. Storage fail-closed rule: unmapped paths match /{allPaths=**} allow read, write: if false', () {
      expect(storageRulesContent, contains('match /{allPaths=**}'));
      expect(storageRulesContent, contains('allow read, write: if false;'));
    });

    test('16. Storage owner isolation: requires isOwner(userId) on media access', () {
      expect(storageRulesContent, contains('match /users/{userId}/captures/{captureId}/{fileName}'));
      expect(storageRulesContent, contains('allow read, delete: if isOwner(userId);'));
    });

    test('17. Storage MIME type whitelist: restricts to image, audio, and PDF formats', () {
      expect(storageRulesContent, contains('function isAllowedMimeType()'));
      expect(storageRulesContent, contains('image/(jpeg|jpg|png|webp|heic)'));
      expect(storageRulesContent, contains('audio/(m4a|mp4|aac|mpeg|wav|webm)'));
      expect(storageRulesContent, contains('application/pdf'));
    });

    test('18. Storage file size constraint: enforces maximum 25 MB limit', () {
      expect(storageRulesContent, contains('function isWithinSizeLimit()'));
      expect(storageRulesContent, contains('25 * 1024 * 1024'));
    });

    test('19. Storage upload rule: requires isOwner && isAllowedMimeType && isWithinSizeLimit', () {
      expect(
        storageRulesContent,
        contains('allow create, update: if isOwner(userId) && isAllowedMimeType() && isWithinSizeLimit();'),
      );
    });

    test('20. InputSanitizer matches Storage MIME whitelist', () {
      for (final mime in InputSanitizer.defaultImageMimes) {
        expect(InputSanitizer.isValidMimeType(mime, InputSanitizer.defaultAllowedMimes), isTrue);
      }
      for (final mime in InputSanitizer.defaultAudioMimes) {
        expect(InputSanitizer.isValidMimeType(mime, InputSanitizer.defaultAllowedMimes), isTrue);
      }
      for (final mime in InputSanitizer.defaultDocMimes) {
        expect(InputSanitizer.isValidMimeType(mime, InputSanitizer.defaultAllowedMimes), isTrue);
      }
    });

    test('21. InputSanitizer rejects dangerous executable and script MIME types', () {
      expect(InputSanitizer.isValidMimeType('application/x-sh', InputSanitizer.defaultAllowedMimes), isFalse);
      expect(InputSanitizer.isValidMimeType('application/javascript', InputSanitizer.defaultAllowedMimes), isFalse);
      expect(InputSanitizer.isValidMimeType('application/x-msdownload', InputSanitizer.defaultAllowedMimes), isFalse);
      expect(InputSanitizer.isValidMimeType('text/html', InputSanitizer.defaultAllowedMimes), isFalse);
      expect(InputSanitizer.isValidMimeType('application/octet-stream', InputSanitizer.defaultAllowedMimes), isFalse);
    });

    test('22. InputSanitizer enforces 25MB boundary logic', () {
      expect(InputSanitizer.isValidFileSize(1024), isTrue);
      expect(InputSanitizer.isValidFileSize(25 * 1024 * 1024), isTrue); // Exactly 25 MB
      expect(InputSanitizer.isValidFileSize((25 * 1024 * 1024) + 1), isFalse); // 25 MB + 1 byte
      expect(InputSanitizer.isValidFileSize(0), isFalse); // Zero bytes
      expect(InputSanitizer.isValidFileSize(-10), isFalse); // Negative
    });
  });
}