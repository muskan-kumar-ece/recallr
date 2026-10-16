import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/data_exceptions.dart';
import '../../features/people/models/person_item.dart';
import '../../repositories/people_repository.dart';

/// Production Firestore-backed repository for People directory.
/// Queries and mutations are strictly isolated to `users/{uid}/people/{personId}`.
class FirestorePeopleRepository implements PeopleRepository {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirestorePeopleRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestoreOverride = firestore,
        _authOverride = auth;

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

  CollectionReference<Map<String, dynamic>> get _peopleCollection {
    final uid = _uid;
    return _firestore.collection('users').doc(uid).collection('people');
  }

  @override
  Stream<List<PersonItem>> streamPeople({
    String? query,
    PeopleFilterOption? filter,
    int limit = 100,
  }) {
    try {
      Query<Map<String, dynamic>> baseQuery = _peopleCollection;
      if (limit > 0) {
        baseQuery = baseQuery.limit(limit);
      }
      return baseQuery.snapshots().map((snapshot) {
        var people = snapshot.docs.map((doc) => PersonItem.fromFirestore(doc)).toList();

        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim().toLowerCase();
          people = people.where((p) {
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
              people = people.where((p) => p.lastInteraction != null).toList();
              break;
            case PeopleFilterOption.followUpDue:
              people = people.where((p) => p.hasPendingFollowUp).toList();
              break;
            case PeopleFilterOption.aiMl:
              people = people.where((p) => p.capabilities.any((c) =>
                  c.toLowerCase().contains('ai') ||
                  c.toLowerCase().contains('slm') ||
                  c.toLowerCase().contains('neural') ||
                  c.toLowerCase().contains('quantization') ||
                  c.toLowerCase().contains('llm'))).toList();
              break;
            case PeopleFilterOption.founders:
              people = people.where((p) =>
                  p.relationshipType == RelationshipContextType.founder ||
                  p.role.toLowerCase().contains('founder') ||
                  p.role.toLowerCase().contains('ceo') ||
                  p.role.toLowerCase().contains('co-founder')).toList();
              break;
            case PeopleFilterOption.deepTech:
              people = people.where((p) => p.capabilities.any((c) =>
                  c.toLowerCase().contains('risc-v') ||
                  c.toLowerCase().contains('hardware') ||
                  c.toLowerCase().contains('silicon') ||
                  c.toLowerCase().contains('compiler') ||
                  c.toLowerCase().contains('embedded'))).toList();
              break;
          }
        }

        return people;
      });
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Stream<List<PersonItem>> streamRecentlyInteracted({int limit = 5}) {
    try {
      return _peopleCollection
          .orderBy('lastInteractionDate', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => PersonItem.fromFirestore(doc)).toList())
          .handleError((e) {
        // Fallback for cases where composite index is building
        return _peopleCollection.snapshots().map((snapshot) {
          final list = snapshot.docs.map((doc) => PersonItem.fromFirestore(doc)).toList();
          list.sort((a, b) => (b.lastInteractionDate ?? DateTime(2000))
              .compareTo(a.lastInteractionDate ?? DateTime(2000)));
          return list.take(limit).toList();
        });
      });
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<PersonItem?> getPerson(String id) async {
    try {
      final doc = await _peopleCollection.doc(id).get();
      if (!doc.exists) return null;
      return PersonItem.fromFirestore(doc);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> addPerson(PersonItem person) async {
    try {
      final docRef = person.id.isNotEmpty ? _peopleCollection.doc(person.id) : _peopleCollection.doc();
      final map = person.toMap()
        ..['id'] = docRef.id
        ..['userId'] = _uid
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.set(map);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> updatePerson(PersonItem person) async {
    try {
      final map = person.toMap()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _peopleCollection.doc(person.id).update(map);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<void> deletePerson(String id) async {
    try {
      await _peopleCollection.doc(id).delete();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<PersonItem?> findPersonByEmail(String normalizedEmail) async {
    try {
      final clean = normalizedEmail.trim().toLowerCase();
      if (clean.isEmpty) return null;

      // Targeted bounded query by normalized email (limit 1)
      final snapshot = await _peopleCollection.where('email', isEqualTo: clean).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return PersonItem.fromFirestore(snapshot.docs.first);
      }
      // Also try original case if different
      if (normalizedEmail.trim() != clean) {
        final altSnapshot = await _peopleCollection.where('email', isEqualTo: normalizedEmail.trim()).limit(1).get();
        if (altSnapshot.docs.isNotEmpty) {
          return PersonItem.fromFirestore(altSnapshot.docs.first);
        }
      }
      return null;
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<PersonItem?> findPersonByPhone(String normalizedPhone) async {
    try {
      final raw = normalizedPhone.trim();
      final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isEmpty) return null;

      // Targeted bounded query by raw phone (limit 1)
      final snapshot = await _peopleCollection.where('phone', isEqualTo: raw).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return PersonItem.fromFirestore(snapshot.docs.first);
      }
      // Also try cleaned digits
      if (clean != raw) {
        final digitSnapshot = await _peopleCollection.where('phone', isEqualTo: clean).limit(1).get();
        if (digitSnapshot.docs.isNotEmpty) {
          return PersonItem.fromFirestore(digitSnapshot.docs.first);
        }
      }
      return null;
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<List<PersonItem>> findCandidatesByName(String normalizedName) async {
    try {
      final clean = normalizedName.trim();
      if (clean.isEmpty) return [];

      // Targeted bounded query (limit 10)
      final snapshot = await _peopleCollection.where('name', isEqualTo: clean).limit(10).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => PersonItem.fromFirestore(doc)).toList();
      }
      final cleanLower = clean.toLowerCase();
      if (cleanLower != clean) {
        final altSnapshot = await _peopleCollection.where('name', isEqualTo: cleanLower).limit(10).get();
        if (altSnapshot.docs.isNotEmpty) {
          return altSnapshot.docs.map((doc) => PersonItem.fromFirestore(doc)).toList();
        }
      }
      return [];
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<List<PersonItem>> findCandidatesByNameAndCompany(
    String normalizedName,
    String normalizedCompany,
  ) async {
    try {
      final cleanName = normalizedName.trim();
      final cleanComp = normalizedCompany.trim();
      if (cleanName.isEmpty) return [];

      // Targeted bounded query on name and company (limit 10)
      Query<Map<String, dynamic>> q = _peopleCollection.where('name', isEqualTo: cleanName);
      if (cleanComp.isNotEmpty) {
        q = q.where('company', isEqualTo: cleanComp);
      }
      final snapshot = await q.limit(10).get();
      return snapshot.docs.map((doc) => PersonItem.fromFirestore(doc)).toList();
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<PersonItem> createPersonFromCapture(PersonItem person) async {
    try {
      final docRef = person.id.isNotEmpty ? _peopleCollection.doc(person.id) : _peopleCollection.doc();
      final map = person.toMap()
        ..['id'] = docRef.id
        ..['userId'] = _uid
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.set(map);

      final created = person.copyWith(
        id: docRef.id,
        userId: _uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return created;
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }

  @override
  Future<PersonItem> enrichPerson(String personId, Map<String, dynamic> updates) async {
    try {
      final docRef = _peopleCollection.doc(personId);
      final doc = await docRef.get();
      if (!doc.exists) {
        throw RecallrDataException.notFound('Person not found: $personId');
      }

      final existing = PersonItem.fromFirestore(doc);
      final Map<String, dynamic> mergeMap = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existing.role.isEmpty && updates['role'] != null) {
        mergeMap['role'] = updates['role'];
      }
      if (existing.company.isEmpty && updates['company'] != null) {
        mergeMap['company'] = updates['company'];
      }
      if (existing.email == null && updates['email'] != null) {
        mergeMap['email'] = updates['email'];
      }
      if (existing.phone == null && updates['phone'] != null) {
        mergeMap['phone'] = updates['phone'];
      }
      if (existing.locationOrEvent == null && updates['locationOrEvent'] != null) {
        mergeMap['locationOrEvent'] = updates['locationOrEvent'];
      }
      if (updates['lastInteraction'] != null) {
        mergeMap['lastInteraction'] = updates['lastInteraction'];
      }
      if (updates['lastInteractionDate'] != null) {
        mergeMap['lastInteractionDate'] = FieldValue.serverTimestamp();
      }
      mergeMap['interactionCount'] = FieldValue.increment(1);

      await docRef.set(mergeMap, SetOptions(merge: true));

      final updatedDoc = await docRef.get();
      return PersonItem.fromFirestore(updatedDoc);
    } catch (e, st) {
      if (e is RecallrDataException) rethrow;
      throw RecallrDataException.fromException(e, st);
    }
  }
}