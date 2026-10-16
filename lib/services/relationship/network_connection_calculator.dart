import 'package:flutter/foundation.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/capture/models/capture_models.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/relationship_intelligence/models/network_connection.dart';
import '../../features/relationship_intelligence/models/relationship_strength.dart';

/// Contract for deterministic network connection discovery and strength scoring.
abstract class NetworkConnectionCalculator {
  List<NetworkConnection> calculateConnections({
    required List<PersonProfile> profiles,
    List<ActivityItem> activities = const [],
    List<CaptureItem> captures = const [],
    Map<String, RelationshipStrength> strengths = const {},
    DateTime? referenceDate,
  });
}

/// Production implementation of deterministic explicit-evidence connection calculator.
@immutable
class DeterministicNetworkConnectionCalculator implements NetworkConnectionCalculator {
  const DeterministicNetworkConnectionCalculator();

  @override
  List<NetworkConnection> calculateConnections({
    required List<PersonProfile> profiles,
    List<ActivityItem> activities = const [],
    List<CaptureItem> captures = const [],
    Map<String, RelationshipStrength> strengths = const {},
    DateTime? referenceDate,
  }) {
    if (profiles.length < 2) return const [];

    final Map<String, _ConnectionBuilder> edgeMap = {};

    // Pre-index profiles by ID and lower-case name for O(1) lookups
    final Map<String, PersonProfile> profileById = {
      for (final p in profiles) p.id: p,
    };
    final Map<String, PersonProfile> profileByNameLower = {
      for (final p in profiles) p.name.trim().toLowerCase(): p,
    };

    // 1. Evidence: Shared Company (Inverted Index: group by company)
    final Map<String, List<PersonProfile>> profilesByCompany = {};
    for (final p in profiles) {
      final comp = p.company.trim().toLowerCase();
      if (comp.isEmpty || comp == 'unknown' || comp == 'n/a' || comp == 'none') continue;
      profilesByCompany.putIfAbsent(comp, () => []).add(p);
    }

    for (final compProfiles in profilesByCompany.values) {
      if (compProfiles.length < 2) continue;
      final compA = compProfiles.first.company.trim().toLowerCase();
      final sharedComp = compProfiles.first.company.trim();
      final evidenceId = 'company_$compA';

      for (int i = 0; i < compProfiles.length; i++) {
        final pA = compProfiles[i];
        for (int j = i + 1; j < compProfiles.length; j++) {
          final pB = compProfiles[j];
          if (pA.id == pB.id) continue;

          final pairKey = _canonicalKey(pA.id, pB.id);
          final builder = edgeMap.putIfAbsent(
            pairKey,
            () => _ConnectionBuilder(
              personAId: pA.id,
              personBId: pB.id,
              personAName: pA.name,
              personBName: pB.name,
            ),
          );
          builder.sharedCompany = sharedComp;
          builder.evidenceIds.add(evidenceId);
          builder.hasSharedCompany = true;
        }
      }
    }

    // 2. Evidence: Shared Project / Connected Entities in Profiles
    // Pre-extract projects and group by project (Inverted Index)
    final Map<String, Set<String>> projectsByPerson = {
      for (final p in profiles) p.id: _extractProjects(p),
    };
    final Map<String, List<PersonProfile>> profilesByProject = {};
    for (final p in profiles) {
      final projs = projectsByPerson[p.id]!;
      for (final proj in projs) {
        profilesByProject.putIfAbsent(proj, () => []).add(p);
      }
    }

    for (final entry in profilesByProject.entries) {
      final proj = entry.key;
      final projProfiles = entry.value;
      if (projProfiles.length < 2) continue;
      final evidenceId = 'project_${_slugify(proj)}';

      for (int i = 0; i < projProfiles.length; i++) {
        final pA = projProfiles[i];
        for (int j = i + 1; j < projProfiles.length; j++) {
          final pB = projProfiles[j];
          if (pA.id == pB.id) continue;

          final pairKey = _canonicalKey(pA.id, pB.id);
          final builder = edgeMap.putIfAbsent(
            pairKey,
            () => _ConnectionBuilder(
              personAId: pA.id,
              personBId: pB.id,
              personAName: pA.name,
              personBName: pB.name,
            ),
          );
          builder.evidenceIds.add(evidenceId);
          builder.sharedContext = proj;
          builder.hasSharedProject = true;
        }
      }
    }

    // Mutual ConnectedEntity person reference
    final Map<String, List<ConnectedEntity>> personRefsByPerson = {};
    for (final p in profiles) {
      final personRefs = p.connectedEntities.where((e) => e.type == EntityType.person).toList();
      if (personRefs.isNotEmpty) {
        personRefsByPerson[p.id] = personRefs;
      }
    }

    for (final entry in personRefsByPerson.entries) {
      final pAId = entry.key;
      final pA = profileById[pAId];
      if (pA == null) continue;

      for (final ref in entry.value) {
        PersonProfile? pB;
        if (ref.id.isNotEmpty && profileById.containsKey(ref.id)) {
          pB = profileById[ref.id];
        } else if (ref.title.trim().isNotEmpty) {
          final candidate = profileByNameLower[ref.title.trim().toLowerCase()];
          if (candidate != null && candidate.id != pAId) {
            pB = candidate;
          }
        }
        if (pB == null || pB.id == pAId) continue;
        final targetB = pB;

        final pairKey = _canonicalKey(pAId, targetB.id);
        final builder = edgeMap.putIfAbsent(
          pairKey,
          () => _ConnectionBuilder(
            personAId: pAId,
            personBId: targetB.id,
            personAName: pA.name,
            personBName: targetB.name,
          ),
        );
        builder.evidenceIds.add('entity_ref_${_canonicalKey(pAId, targetB.id)}');
        builder.hasSharedInteraction = true;
      }
    }

    // 3. Evidence: Shared Activities & Encounters
    for (final act in activities) {
      if (act.personId == null || act.personId!.isEmpty) continue;
      final relatedPersonIds = _extractRelatedPersonIds(act);
      if (relatedPersonIds.isEmpty) continue;

      final pAId = act.personId!;
      final pA = profileById[pAId];
      if (pA == null) continue;

      for (final pBId in relatedPersonIds) {
        if (pAId == pBId) continue;
        final pB = profileById[pBId];
        if (pB == null) continue;

        final pairKey = _canonicalKey(pAId, pBId);
        final builder = edgeMap.putIfAbsent(
          pairKey,
          () => _ConnectionBuilder(
            personAId: pAId,
            personBId: pBId,
            personAName: pA.name,
            personBName: pB.name,
          ),
        );
        builder.evidenceIds.add('act_${act.id}');
        builder.hasSharedInteraction = true;
      }
    }

    // 4. Evidence: Shared Captures
    for (final cap in captures) {
      final capPersonIds = <String>[];
      if (cap.personId != null && cap.personId!.isNotEmpty) capPersonIds.add(cap.personId!);
      if (cap.resolvedPersonId != null && cap.resolvedPersonId!.isNotEmpty && !capPersonIds.contains(cap.resolvedPersonId)) {
        capPersonIds.add(cap.resolvedPersonId!);
      }
      if (cap.metadata != null) {
        final related = cap.metadata!['relatedPersonIds'] ?? cap.metadata!['attendees'];
        if (related is List) {
          for (final r in related) {
            if (r != null && r.toString().isNotEmpty && !capPersonIds.contains(r.toString())) {
              capPersonIds.add(r.toString());
            }
          }
        }
      }
      if (capPersonIds.length < 2) continue;

      for (int i = 0; i < capPersonIds.length; i++) {
        final idA = capPersonIds[i];
        final pA = profileById[idA];
        if (pA == null) continue;

        for (int j = i + 1; j < capPersonIds.length; j++) {
          final idB = capPersonIds[j];
          if (idA == idB) continue;
          final pB = profileById[idB];
          if (pB == null) continue;

          final pairKey = _canonicalKey(idA, idB);
          final builder = edgeMap.putIfAbsent(
            pairKey,
            () => _ConnectionBuilder(
              personAId: idA,
              personBId: idB,
              personAName: pA.name,
              personBName: pB.name,
            ),
          );
          builder.evidenceIds.add('cap_${cap.id}');
          builder.hasSharedCapture = true;
        }
      }
    }

    // Build final List<NetworkConnection> with deterministic scoring
    final List<NetworkConnection> connections = [];

    for (final builder in edgeMap.values) {
      final strA = strengths[builder.personAId]?.score ?? 50.0;
      final strB = strengths[builder.personBId]?.score ?? 50.0;
      final avgStrength = ((strA + strB) / 2.0).clamp(0.0, 100.0);

      final score = _calculateConnectionScore(
        hasCompany: builder.hasSharedCompany,
        hasInteraction: builder.hasSharedInteraction,
        hasProject: builder.hasSharedProject,
        hasCapture: builder.hasSharedCapture,
        evidenceCount: builder.evidenceIds.length,
        averageStrength: avgStrength,
      );

      final connType = _resolveConnectionType(builder);

      connections.add(
        NetworkConnection(
          personAId: builder.personAId,
          personBId: builder.personBId,
          personAName: builder.personAName,
          personBName: builder.personBName,
          connectionType: connType,
          connectionScore: score,
          evidenceCount: builder.evidenceIds.length,
          evidenceIds: builder.evidenceIds.toList(),
          sharedCompany: builder.sharedCompany,
          sharedContext: builder.sharedContext,
          generatedAt: referenceDate,
        ),
      );
    }

    // Deterministic sorting: connectionScore DESC, edgeId ASC
    connections.sort((a, b) {
      final scoreComp = b.connectionScore.compareTo(a.connectionScore);
      if (scoreComp != 0) return scoreComp;
      return a.edgeId.compareTo(b.edgeId);
    });

    return List.unmodifiable(connections);
  }

  static double _calculateConnectionScore({
    required bool hasCompany,
    required bool hasInteraction,
    required bool hasProject,
    required bool hasCapture,
    required int evidenceCount,
    required double averageStrength,
  }) {
    final compScore = hasCompany ? 1.0 : (hasCapture ? 0.7 : 0.0);
    final interScore = hasInteraction ? 1.0 : 0.0;
    final projScore = hasProject ? 1.0 : 0.0;
    final volScore = (evidenceCount / 3.0).clamp(0.0, 1.0);
    final strScore = (averageStrength / 100.0).clamp(0.0, 1.0);

    final rawScore = (compScore * 0.30 +
            interScore * 0.30 +
            projScore * 0.20 +
            volScore * 0.10 +
            strScore * 0.10) *
        100.0;

    if (rawScore.isNaN || rawScore.isInfinite) return 0.0;
    return rawScore.clamp(0.0, 100.0);
  }

  static NetworkConnectionType _resolveConnectionType(_ConnectionBuilder builder) {
    if (builder.hasSharedCompany) return NetworkConnectionType.sharedCompany;
    if (builder.hasSharedInteraction) return NetworkConnectionType.sharedInteraction;
    if (builder.hasSharedProject) return NetworkConnectionType.sharedProject;
    if (builder.hasSharedCapture) return NetworkConnectionType.sharedCapture;
    return NetworkConnectionType.sharedContext;
  }

  static String _canonicalKey(String idA, String idB) {
    return idA.compareTo(idB) <= 0 ? '${idA}_$idB' : '${idB}_$idA';
  }

  static Set<String> _extractProjects(PersonProfile p) {
    final set = <String>{};
    for (final e in p.connectedEntities) {
      if (e.type == EntityType.event || e.type == EntityType.file) {
        if (e.title.trim().isNotEmpty) set.add(e.title.trim().toLowerCase());
      }
    }
    for (final m in p.memories) {
      if (m.category.toLowerCase().contains('project') && m.text.trim().isNotEmpty) {
        set.add(m.text.trim().toLowerCase());
      }
    }
    return set;
  }

  static List<String> _extractRelatedPersonIds(ActivityItem act) {
    final list = <String>[];
    if (act.metadata != null) {
      final related = act.metadata!['relatedPersonIds'] ?? act.metadata!['attendees'];
      if (related is List) {
        for (final item in related) {
          if (item != null && item.toString().isNotEmpty) {
            list.add(item.toString());
          }
        }
      }
    }
    return list;
  }

  static String _slugify(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

class _ConnectionBuilder {
  final String personAId;
  final String personBId;
  final String personAName;
  final String personBName;
  final Set<String> evidenceIds = {};
  String? sharedCompany;
  String? sharedContext;
  bool hasSharedCompany = false;
  bool hasSharedInteraction = false;
  bool hasSharedProject = false;
  bool hasSharedCapture = false;

  _ConnectionBuilder({
    required this.personAId,
    required this.personBId,
    required this.personAName,
    required this.personBName,
  });
}
