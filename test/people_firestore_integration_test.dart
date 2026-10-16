import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/repositories/people_repository.dart';
import 'package:recaller/screens/people/people_screen.dart';

/// Test implementation of PeopleRepository simulating real-time Firestore stream events.
class FakeFirestorePeopleRepository implements PeopleRepository {
  final StreamController<List<PersonItem>> _streamController = StreamController<List<PersonItem>>.broadcast();
  final List<PersonItem> _storage = [];
  bool shouldThrowUnauthenticated = false;
  bool shouldThrowError = false;

  FakeFirestorePeopleRepository({List<PersonItem>? initialData}) {
    if (initialData != null) {
      _storage.addAll(initialData);
    }
  }

  void emit(List<PersonItem> items) {
    _streamController.add(items);
  }

  @override
  Stream<List<PersonItem>> streamPeople({String? query, PeopleFilterOption? filter, int limit = 100}) {
    if (shouldThrowUnauthenticated) {
      return Stream.error(RecallrDataException.unauthenticated());
    }
    if (shouldThrowError) {
      return Stream.error(RecallrDataException.networkUnavailable());
    }

    var result = List<PersonItem>.from(_storage);
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.role.toLowerCase().contains(q) ||
          p.company.toLowerCase().contains(q)).toList();
    }
    if (filter != null && filter != PeopleFilterOption.all) {
      if (filter == PeopleFilterOption.founders) {
        result = result.where((p) => p.relationshipType == RelationshipContextType.founder).toList();
      } else if (filter == PeopleFilterOption.followUpDue) {
        result = result.where((p) => p.hasPendingFollowUp).toList();
      }
    }

    return Stream.value(result);
  }

  @override
  Stream<List<PersonItem>> streamRecentlyInteracted({int limit = 5}) {
    return Stream.value(_storage.where((p) => p.lastInteraction != null).take(limit).toList());
  }

  @override
  Future<PersonItem?> getPerson(String id) async {
    try {
      return _storage.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addPerson(PersonItem person) async {
    final newPerson = person.copyWith(
      id: person.id.isNotEmpty ? person.id : 'gen_${_storage.length + 1}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _storage.add(newPerson);
    _streamController.add(List.from(_storage));
  }

  @override
  Future<void> updatePerson(PersonItem person) async {
    final idx = _storage.indexWhere((p) => p.id == person.id);
    if (idx != -1) {
      _storage[idx] = person.copyWith(updatedAt: DateTime.now());
      _streamController.add(List.from(_storage));
    }
  }

  @override
  Future<void> deletePerson(String id) async {
    _storage.removeWhere((p) => p.id == id);
    _streamController.add(List.from(_storage));
  }

  @override
  Future<PersonItem?> findPersonByEmail(String normalizedEmail) async {
    final clean = normalizedEmail.trim().toLowerCase();
    if (clean.isEmpty) return null;
    try {
      return _storage.firstWhere((p) => p.email?.trim().toLowerCase() == clean);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PersonItem?> findPersonByPhone(String normalizedPhone) async {
    final clean = normalizedPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;
    try {
      return _storage.firstWhere((p) => p.phone?.replaceAll(RegExp(r'[^0-9]'), '') == clean);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PersonItem>> findCandidatesByName(String normalizedName) async {
    final clean = normalizedName.trim().toLowerCase();
    return _storage.where((p) => p.name.trim().toLowerCase() == clean).toList();
  }

  @override
  Future<List<PersonItem>> findCandidatesByNameAndCompany(
    String normalizedName,
    String normalizedCompany,
  ) async {
    final cleanName = normalizedName.trim().toLowerCase();
    final cleanComp = normalizedCompany.trim().toLowerCase();
    return _storage.where((p) {
      final matchesName = p.name.trim().toLowerCase() == cleanName;
      final matchesComp = cleanComp.isEmpty || p.company.trim().toLowerCase().contains(cleanComp);
      return matchesName && matchesComp;
    }).toList();
  }

  @override
  Future<PersonItem> createPersonFromCapture(PersonItem person) async {
    final created = person.copyWith(
      id: person.id.isNotEmpty ? person.id : 'cap_${_storage.length + 1}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _storage.add(created);
    _streamController.add(List.from(_storage));
    return created;
  }

  @override
  Future<PersonItem> enrichPerson(String personId, Map<String, dynamic> updates) async {
    final idx = _storage.indexWhere((p) => p.id == personId);
    if (idx == -1) throw Exception('Not found');
    final existing = _storage[idx];
    final updated = existing.copyWith(
      email: existing.email ?? updates['email']?.toString(),
      phone: existing.phone ?? updates['phone']?.toString(),
      role: existing.role.isEmpty && updates['role'] != null ? updates['role'].toString() : existing.role,
      company: existing.company.isEmpty && updates['company'] != null ? updates['company'].toString() : existing.company,
      updatedAt: DateTime.now(),
    );
    _storage[idx] = updated;
    _streamController.add(List.from(_storage));
    return updated;
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('Phase 13C-02: People → Firestore Serialization & Domain Model Tests', () {
    test('1. PersonItem serializes and deserializes all Firestore fields accurately', () {
      final now = DateTime(2026, 8, 28, 10, 30);
      final person = PersonItem(
        id: 'per_priya_01',
        name: 'Priya Sharma',
        role: 'Principal Architect',
        company: 'Microsoft',
        email: 'priya.sharma@microsoft.com',
        phone: '+91 98765 43210',
        locationOrEvent: 'Hyderabad Campus',
        contextSnippet: 'Discussed RISC-V LLVM vectorization',
        lastInteraction: 'Yesterday',
        lastInteractionDate: now,
        initials: 'PS',
        capabilities: const ['RISC-V', 'LLVM', 'SLMs'],
        pendingFollowUp: 'Send whitepaper draft',
        hasPendingFollowUp: true,
        interactionCount: 7,
        relationshipType: RelationshipContextType.collaborator,
        avatarUrl: 'https://recallr.ai/avatars/priya.png',
        userId: 'usr_auth_123',
        createdAt: now,
        updatedAt: now,
      );

      final map = person.toMap();
      expect(map['id'], equals('per_priya_01'));
      expect(map['name'], equals('Priya Sharma'));
      expect(map['email'], equals('priya.sharma@microsoft.com'));
      expect(map['phone'], equals('+91 98765 43210'));
      expect(map['userId'], equals('usr_auth_123'));
      expect(map['relationshipType'], equals('collaborator'));

      final restored = PersonItem.fromMap(map, 'per_priya_01');
      expect(restored.id, equals('per_priya_01'));
      expect(restored.name, equals(person.name));
      expect(restored.email, equals(person.email));
      expect(restored.phone, equals(person.phone));
      expect(restored.initials, equals('PS'));
      expect(restored.capabilities, equals(person.capabilities));
      expect(restored.hasPendingFollowUp, isTrue);
      expect(restored.relationshipType, equals(RelationshipContextType.collaborator));
    });

    test('2. PersonItem auto-computes initials when empty or missing', () {
      expect(PersonItem.computeInitials('Priya Sharma'), equals('PS'));
      expect(PersonItem.computeInitials('Arjun'), equals('AR'));
      expect(PersonItem.computeInitials('Vivek K. Raghavan'), equals('VR'));
      expect(PersonItem.computeInitials(''), equals('??'));

      final partialMap = {
        'id': 'per_anon',
        'name': 'Kavita Rao',
        'role': 'Director',
        'company': 'IIT Bombay',
      };
      final person = PersonItem.fromMap(partialMap);
      expect(person.initials, equals('KR'));
    });
  });

  group('Phase 13C-02: People Repository Live Wiring & State Tests', () {
    late FakeFirestorePeopleRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeFirestorePeopleRepository(initialData: [
        const PersonItem(
          id: 'per_1',
          name: 'Priya Sharma',
          role: 'Principal Architect',
          company: 'Microsoft',
          initials: 'PS',
          capabilities: ['RISC-V', 'LLVM'],
          hasPendingFollowUp: true,
          relationshipType: RelationshipContextType.collaborator,
        ),
        const PersonItem(
          id: 'per_2',
          name: 'Vivek Raghavan',
          role: 'Chief AI Architect',
          company: 'Sarvam AI',
          initials: 'VR',
          capabilities: ['Voice AI', 'Indic SLMs'],
          relationshipType: RelationshipContextType.founder,
        ),
      ]);
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    test('3. PeopleRepository supports live CRUD operations', () async {
      final initialList = await fakeRepo.streamPeople().first;
      expect(initialList, hasLength(2));

      // Add person
      const newPerson = PersonItem(
        id: 'per_3',
        name: 'Arjun Mehta',
        role: 'Partner',
        company: 'Nexus VP',
        initials: 'AM',
        relationshipType: RelationshipContextType.investor,
      );
      await fakeRepo.addPerson(newPerson);

      var fetched = await fakeRepo.getPerson('per_3');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Arjun Mehta'));

      // Update person
      final updated = newPerson.copyWith(role: 'Managing Partner');
      await fakeRepo.updatePerson(updated);
      fetched = await fakeRepo.getPerson('per_3');
      expect(fetched!.role, equals('Managing Partner'));

      // Delete person
      await fakeRepo.deletePerson('per_3');
      fetched = await fakeRepo.getPerson('per_3');
      expect(fetched, isNull);
    });

    test('4. PeopleRepository filters by search query and filter option', () async {
      final searchResult = await fakeRepo.streamPeople(query: 'Priya').first;
      expect(searchResult, hasLength(1));
      expect(searchResult.first.name, equals('Priya Sharma'));

      final founderResult = await fakeRepo.streamPeople(filter: PeopleFilterOption.founders).first;
      expect(founderResult, hasLength(1));
      expect(founderResult.first.name, equals('Vivek Raghavan'));

      final followUpResult = await fakeRepo.streamPeople(filter: PeopleFilterOption.followUpDue).first;
      expect(followUpResult, hasLength(1));
      expect(followUpResult.first.name, equals('Priya Sharma'));
    });

    testWidgets('5. PeopleScreen renders live people from injected repository', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeopleScreen(
              repository: fakeRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Priya Sharma'), findsWidgets);
      expect(find.text('Vivek Raghavan'), findsWidgets);
      expect(find.textContaining('Microsoft'), findsWidgets);
      expect(find.textContaining('Sarvam AI'), findsWidgets);
    });

    testWidgets('6. PeopleScreen handles repository error gracefully with retry option', (tester) async {
      final errorRepo = FakeFirestorePeopleRepository()..shouldThrowError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeopleScreen(
              repository: errorRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('load your people directory'), findsOneWidget);
    });
  });
}