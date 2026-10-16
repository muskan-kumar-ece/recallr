import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/core/release/release_candidate_config.dart';
import 'package:recaller/core/security/environment_config.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';

void main() {
  group('Phase 13F-04: Release Candidate Validation & Invariant Tests', () {
    test('1. ReleaseCandidateConfig.audit confirms production readiness with valid config', () {
      final config = EnvironmentConfig.production(
        geminiApiKey: 'AIzaSyValidProductionApiKey12345',
      );

      final audit = ReleaseCandidateConfig.audit(config: config);
      expect(audit.isProductionReady, isTrue);
      expect(audit.validationErrors.isEmpty, isTrue);
      expect(audit.featureReadiness['Authentication'], isTrue);
      expect(audit.featureReadiness['Firestore_People'], isTrue);
      expect(audit.featureReadiness['Grounded_AI_Synthesis'], isTrue);
    });

    test('2. ReleaseCandidateConfig.audit catches production safety violations', () {
      // Configuration with emulator enabled in production
      final invalidConfig = EnvironmentConfig(
        environment: AppEnvironment.production,
        firebaseProjectId: 'recaller-prod',
        enableAppCheck: true,
        appCheckProviderType: AppCheckProviderType.playIntegrity,
        useEmulators: true, // Violation
      );

      final audit = ReleaseCandidateConfig.audit(config: invalidConfig);
      expect(audit.isProductionReady, isFalse);
      expect(audit.validationErrors, isNotEmpty);
      expect(audit.validationErrors.first, contains('Firebase Emulators are strictly forbidden in production'));
    });

    test('3. Backward compatibility: CaptureItem deserializes with missing optional fields', () {
      final legacyJson = <String, dynamic>{
        'id': 'cap_legacy_001',
        'type': 'note',
        'title': 'Legacy Note Title',
        'rawContent': 'Discussed enterprise AI deployment roadmap',
        'createdAt': '2026-08-01T10:00:00.000Z',
      };

      final capture = CaptureItem.fromMap(legacyJson);
      expect(capture.id, equals('cap_legacy_001'));
      expect(capture.type, equals(CaptureType.note));
      expect(capture.mediaUrl, isNull);
      expect(capture.durationSeconds, isNull);
      expect(capture.confidence, isNull);
      expect(capture.processingStatus, isNull);
    });

    test('4. Backward compatibility: PersonItem deserializes with minimal required fields', () {
      final legacyPersonJson = <String, dynamic>{
        'id': 'person_legacy_001',
        'name': 'Marcus Vance',
        'role': 'VP Engineering',
        'company': 'Apex Systems',
      };

      final person = PersonItem.fromMap(legacyPersonJson);
      expect(person.id, equals('person_legacy_001'));
      expect(person.name, equals('Marcus Vance'));
      expect(person.hasPendingFollowUp, isFalse);
      expect(person.email, isNull);
      expect(person.phone, isNull);
    });

    test('5. Backward compatibility: PersonProfile deserializes with missing nested arrays', () {
      final legacyProfileJson = <String, dynamic>{
        'id': 'person_legacy_002',
        'name': 'Elena Rostova',
        'role': 'Product Architect',
        'company': 'Nova Labs',
      };

      final profile = PersonProfile.fromMap(legacyProfileJson);
      expect(profile.id, equals('person_legacy_002'));
      expect(profile.name, equals('Elena Rostova'));
      expect(profile.timeline, isEmpty);
      expect(profile.memories, isEmpty);
      expect(profile.followUps, isEmpty);
      expect(profile.connectedEntities, isEmpty);
    });

    test('6. Fail-closed security exception types have structured error categorization', () {
      final unauthException = RecallrDataException.unauthenticated('No authenticated user session');
      expect(unauthException.type, equals(DataErrorType.unauthenticated));
      expect(unauthException.message, contains('No authenticated user session'));

      final permDeniedException = RecallrDataException.permissionDenied('Tenant boundary violation');
      expect(permDeniedException.type, equals(DataErrorType.permissionDenied));
      expect(permDeniedException.message, contains('Tenant boundary violation'));

      final notFoundException = RecallrDataException.notFound('Resource does not exist');
      expect(notFoundException.type, equals(DataErrorType.notFound));
      expect(notFoundException.message, contains('Resource does not exist'));
    });

    test('7. Release Candidate metadata displays consistent semantic versioning', () {
      expect(ReleaseCandidateConfig.version, equals('1.0.0'));
      expect(ReleaseCandidateConfig.buildNumber, equals('1'));
      expect(ReleaseCandidateConfig.releaseChannel, equals('rc1'));
      expect(ReleaseCandidateConfig.releaseName, equals('Recallr 1.0.0-rc1'));
    });
  });
}