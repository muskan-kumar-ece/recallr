import 'dart:async';
import '../../features/people/models/people_mock_data.dart';
import '../../features/people/models/person_item.dart';
import '../../repositories/people_repository.dart';

/// Mock implementation of PeopleRepository using deterministic test fixtures.
class MockPeopleRepository implements PeopleRepository {
  final List<PersonItem> _people;
  final StreamController<List<PersonItem>> _controller = StreamController<List<PersonItem>>.broadcast();

  MockPeopleRepository({List<PersonItem>? initialPeople})
      : _people = initialPeople != null ? List.from(initialPeople) : List.from(PeopleMockData.people);

  @override
  Stream<List<PersonItem>> streamPeople({String? query, PeopleFilterOption? filter, int limit = 100}) async* {
    List<PersonItem> filterList(List<PersonItem> source) {
      var result = List<PersonItem>.from(source);
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        result = result.where((p) {
          final matchesName = p.name.toLowerCase().contains(q);
          final matchesRole = p.role.toLowerCase().contains(q);
          final matchesCompany = p.company.toLowerCase().contains(q);
          final matchesCaps = p.capabilities.any((c) => c.toLowerCase().contains(q));
          return matchesName || matchesRole || matchesCompany || matchesCaps;
        }).toList();
      }
      if (filter != null && filter != PeopleFilterOption.all) {
        switch (filter) {
          case PeopleFilterOption.all:
            break;
          case PeopleFilterOption.recentlyInteracted:
            result = result.where((p) => p.lastInteraction != null).toList();
            break;
          case PeopleFilterOption.followUpDue:
            result = result.where((p) => p.hasPendingFollowUp).toList();
            break;
          case PeopleFilterOption.aiMl:
            result = result.where((p) => p.capabilities.any((c) =>
                c.toLowerCase().contains('ai') ||
                c.toLowerCase().contains('slm') ||
                c.toLowerCase().contains('neural') ||
                c.toLowerCase().contains('quantization') ||
                c.toLowerCase().contains('llm'))).toList();
            break;
          case PeopleFilterOption.founders:
            result = result.where((p) =>
                p.relationshipType == RelationshipContextType.founder ||
                p.role.toLowerCase().contains('founder') ||
                p.role.toLowerCase().contains('ceo') ||
                p.role.toLowerCase().contains('co-founder')).toList();
            break;
          case PeopleFilterOption.deepTech:
            result = result.where((p) => p.capabilities.any((c) =>
                c.toLowerCase().contains('risc-v') ||
                c.toLowerCase().contains('hardware') ||
                c.toLowerCase().contains('silicon') ||
                c.toLowerCase().contains('compiler') ||
                c.toLowerCase().contains('embedded'))).toList();
            break;
        }
      }
      if (limit > 0) {
        return result.take(limit).toList();
      }
      return result;
    }

    yield filterList(_people);
    yield* _controller.stream.map(filterList);
  }

  @override
  Stream<List<PersonItem>> streamRecentlyInteracted({int limit = 5}) async* {
    List<PersonItem> filterRecent(List<PersonItem> source) =>
        source.where((p) => p.lastInteraction != null).take(limit).toList();

    yield filterRecent(_people);
    yield* _controller.stream.map(filterRecent);
  }

  @override
  Future<PersonItem?> getPerson(String id) async {
    try {
      return _people.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addPerson(PersonItem person) async {
    _people.insert(0, person);
    _controller.add(_people);
  }

  @override
  Future<void> updatePerson(PersonItem person) async {
    final index = _people.indexWhere((p) => p.id == person.id);
    if (index != -1) {
      _people[index] = person;
      _controller.add(_people);
    }
  }

  @override
  Future<void> deletePerson(String id) async {
    _people.removeWhere((p) => p.id == id);
    _controller.add(_people);
  }

  @override
  Future<PersonItem?> findPersonByEmail(String normalizedEmail) async {
    final clean = normalizedEmail.trim().toLowerCase();
    if (clean.isEmpty) return null;
    try {
      return _people.firstWhere(
        (p) => p.email != null && p.email!.trim().toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PersonItem?> findPersonByPhone(String normalizedPhone) async {
    final clean = normalizedPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;
    try {
      return _people.firstWhere(
        (p) => p.phone != null && p.phone!.replaceAll(RegExp(r'[^0-9]'), '') == clean,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PersonItem>> findCandidatesByName(String normalizedName) async {
    final clean = normalizedName.trim().toLowerCase();
    if (clean.isEmpty) return [];
    return _people.where((p) => p.name.trim().toLowerCase() == clean).toList();
  }

  @override
  Future<List<PersonItem>> findCandidatesByNameAndCompany(
    String normalizedName,
    String normalizedCompany,
  ) async {
    final cleanName = normalizedName.trim().toLowerCase();
    final cleanComp = normalizedCompany.trim().toLowerCase();
    if (cleanName.isEmpty) return [];
    return _people.where((p) {
      final matchesName = p.name.trim().toLowerCase() == cleanName;
      final matchesComp = cleanComp.isEmpty || p.company.trim().toLowerCase().contains(cleanComp);
      return matchesName && matchesComp;
    }).toList();
  }

  @override
  Future<PersonItem> createPersonFromCapture(PersonItem person) async {
    final id = person.id.isNotEmpty ? person.id : 'per_res_${_people.length + 1}';
    final created = PersonItem(
      id: id,
      name: person.name,
      role: person.role,
      company: person.company,
      email: person.email,
      phone: person.phone,
      locationOrEvent: person.locationOrEvent,
      contextSnippet: person.contextSnippet ?? 'Created via Omni-Capture identity resolution.',
      lastInteraction: person.lastInteraction ?? 'Just now · Captured Memory',
      lastInteractionDate: person.lastInteractionDate ?? DateTime.now(),
      initials: person.initials.isNotEmpty ? person.initials : PersonItem.computeInitials(person.name),
      capabilities: person.capabilities,
      relationshipType: person.relationshipType ?? RelationshipContextType.collaborator,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _people.insert(0, created);
    return created;
  }

  @override
  Future<PersonItem> enrichPerson(String personId, Map<String, dynamic> updates) async {
    final index = _people.indexWhere((p) => p.id == personId);
    if (index == -1) {
      throw Exception('Person not found for enrichment: $personId');
    }
    final existing = _people[index];

    final updated = PersonItem(
      id: existing.id,
      name: updates['name']?.toString() ?? existing.name,
      role: (existing.role.isEmpty && updates['role'] != null) ? updates['role'].toString() : existing.role,
      company: (existing.company.isEmpty && updates['company'] != null) ? updates['company'].toString() : existing.company,
      email: existing.email ?? updates['email']?.toString(),
      phone: existing.phone ?? updates['phone']?.toString(),
      locationOrEvent: existing.locationOrEvent ?? updates['locationOrEvent']?.toString(),
      contextSnippet: updates['contextSnippet']?.toString() ?? existing.contextSnippet,
      lastInteraction: updates['lastInteraction']?.toString() ?? existing.lastInteraction,
      lastInteractionDate: updates['lastInteractionDate'] is DateTime ? updates['lastInteractionDate'] as DateTime : existing.lastInteractionDate,
      initials: existing.initials,
      capabilities: updates['capabilities'] is List<String>
          ? {...existing.capabilities, ...updates['capabilities'] as List<String>}.toList()
          : existing.capabilities,
      pendingFollowUp: existing.pendingFollowUp,
      hasPendingFollowUp: existing.hasPendingFollowUp,
      interactionCount: existing.interactionCount + 1,
      relationshipType: existing.relationshipType,
      avatarUrl: existing.avatarUrl,
      userId: existing.userId,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    _people[index] = updated;
    return updated;
  }
}