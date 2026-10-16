import 'dart:async';
import '../core/errors/data_exceptions.dart';
import '../features/capture/models/capture_models.dart';
import '../features/capture/models/entity_resolution_models.dart';
import '../features/capture/models/ocr_models.dart';
import '../features/people/models/person_item.dart';
import 'entity_resolution_service.dart';

/// Deterministic mock of EntityResolutionService for unit, widget, and CI tests.
class MockEntityResolutionService implements EntityResolutionService {
  bool shouldFail;
  String errorMessage;
  Duration simulatedDelay;
  EntityResolutionResult? forcedResult;
  int resolveCalls = 0;

  MockEntityResolutionService({
    this.shouldFail = false,
    this.errorMessage = 'Simulated entity resolution error',
    this.simulatedDelay = Duration.zero,
    this.forcedResult,
  });

  @override
  Future<EntityResolutionResult> resolveAndLink({
    required CaptureItem capture,
    required OcrExtractedEntities entities,
    bool autoCreatePerson = true,
    bool autoLinkActivity = true,
  }) async {
    resolveCalls++;

    if (shouldFail) {
      throw RecallrDataException.networkUnavailable(errorMessage);
    }

    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (forcedResult != null) {
      return forcedResult!;
    }

    final name = entities.name ?? capture.personName;
    if (name != null && name.toLowerCase().contains('alex johnson')) {
      return EntityResolutionResult(
        matchedPersonId: 'per_alex_j',
        matchType: EntityMatchType.exactEmail,
        status: EntityResolutionStatus.resolvedExisting,
        confidence: 0.98,
        resolvedPerson: PersonItem(
          id: 'per_alex_j',
          name: 'Alex Johnson',
          role: 'Product Manager',
          company: 'Acme Technologies',
          email: 'alex.johnson@acmetech.io',
          phone: '+1 415 555 0199',
          initials: 'AJ',
        ),
        matchedFields: ['email', 'name'],
        extractedFields: entities.toMap(),
        createdActivityId: 'act_cap_${capture.id}',
        resolvedAt: DateTime.now(),
      );
    }

    if (name != null && name.toLowerCase().contains('sarah chen')) {
      return EntityResolutionResult(
        matchedPersonId: 'per_sarah_c',
        matchType: EntityMatchType.strongNameCompany,
        status: EntityResolutionStatus.resolvedExisting,
        confidence: 0.95,
        resolvedPerson: PersonItem(
          id: 'per_sarah_c',
          name: 'Sarah Chen',
          role: 'VP of System Architecture',
          company: 'Mosaic Neuromorphic',
          email: 'sarah.chen@mosaic-neuro.io',
          initials: 'SC',
        ),
        matchedFields: ['name', 'company'],
        extractedFields: entities.toMap(),
        createdActivityId: 'act_cap_${capture.id}',
        resolvedAt: DateTime.now(),
      );
    }

    if (name != null && name.isNotEmpty) {
      return EntityResolutionResult(
        matchedPersonId: 'per_new_${capture.id}',
        matchType: EntityMatchType.none,
        status: EntityResolutionStatus.resolvedNew,
        confidence: 0.90,
        isNewPerson: true,
        resolvedPerson: PersonItem(
          id: 'per_new_${capture.id}',
          name: name,
          role: entities.role ?? capture.personRole ?? 'Collaborator',
          company: entities.company ?? capture.companyName ?? 'Organization',
          email: entities.email,
          phone: entities.phone,
          initials: PersonItem.computeInitials(name),
        ),
        matchedFields: const [],
        extractedFields: entities.toMap(),
        createdActivityId: 'act_cap_${capture.id}',
        resolvedAt: DateTime.now(),
      );
    }

    return EntityResolutionResult(
      matchType: EntityMatchType.none,
      status: EntityResolutionStatus.skipped,
      confidence: 0.0,
      extractedFields: entities.toMap(),
      resolvedAt: DateTime.now(),
    );
  }
}