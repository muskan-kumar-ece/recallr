import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/cards/models/visiting_card.dart';
import '../../features/categories/models/network_category.dart';
import '../../repositories/library_repository.dart';

class FirestoreLibraryRepository implements LibraryRepository {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  final FirebaseFunctions? functions;
  FirestoreLibraryRepository({this.firestore, this.auth, this.functions});
  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions => functions ?? FirebaseFunctions.instance;
  String get _uid =>
      (auth ?? FirebaseAuth.instance).currentUser?.uid ??
      (throw StateError('Sign in to save to your network.'));
  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _db.collection('users').doc(_uid).collection(name);

  @override
  Stream<List<NetworkCategory>> categories() =>
      _collection('categories').snapshots().map((s) =>
          s.docs.map((d) => NetworkCategory.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.order != b.order
                ? a.order.compareTo(b.order)
                : a.name.compareTo(b.name)));

  @override
  Future<NetworkCategory> saveCategory(NetworkCategory category) async {
    final result = await _functions
        .httpsCallable('saveNetworkCategory')
        .call({'id': category.id, ...category.toMap()});
    return NetworkCategory.fromMap(
        result.data['id'] as String, category.toMap());
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _functions.httpsCallable('deleteNetworkCategory').call({'id': id});
  }

  @override
  Stream<List<LibraryEntry>> entries(String collection) {
    if (!['people', 'captures', 'follow_ups'].contains(collection)) {
      throw ArgumentError('Unsupported library collection');
    }
    return _collection(collection).snapshots().map((s) => s.docs.map((d) {
          final data = d.data();
          final prefix = collection == 'people'
              ? 'person'
              : collection == 'follow_ups'
                  ? 'follow-up'
                  : 'captures';
          return LibraryEntry(
              id: d.id,
              collection: collection,
              title: (data['name'] ?? data['title'] ?? 'Untitled').toString(),
              route: '/$prefix/${d.id}',
              categoryIds:
                  List<String>.from(data['categoryIds'] as List? ?? []));
        }).toList());
  }

  @override
  Future<void> categorize(
      String collection, String id, List<String> categories) async {
    await _functions
        .httpsCallable('categorizeNetworkItem')
        .call({'collection': collection, 'id': id, 'categoryIds': categories});
  }

  @override
  Future<VisitingCard?> getDraft(String id) async {
    final doc = await _collection('card_drafts').doc(id).get();
    return doc.exists ? VisitingCard.fromMap(doc.id, doc.data()!) : null;
  }

  @override
  Future<void> saveDraft(VisitingCard card) =>
      _collection('card_drafts').doc(card.id).set({
        'fields': card.fields,
        'visibleFields': card.visibleFields.toList(),
        'layout': card.layout,
        'accent': card.accent,
        if (card.sourcePersonId != null) 'sourcePersonId': card.sourcePersonId,
        'updatedAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

  @override
  Future<String> publish(VisitingCard card) async {
    await saveDraft(card);
    final result = await _functions
        .httpsCallable('publishVisitingCard')
        .call({'draftId': card.id});
    return result.data['id'] as String;
  }

  @override
  Future<void> unpublish(String draftId) async {
    await _functions
        .httpsCallable('unpublishVisitingCard')
        .call({'draftId': draftId});
  }

  @override
  Future<VisitingCard?> getPublicCard(String id) async {
    final doc = await _db.collection('public_cards').doc(id).get();
    return doc.exists ? VisitingCard.fromMap(id, doc.data()!) : null;
  }

  @override
  Future<String> importCard(
      String id, List<String> categories, String note) async {
    final result = await _functions
        .httpsCallable('importVisitingCard')
        .call({'cardId': id, 'categoryIds': categories, 'note': note});
    return result.data['personId'] as String;
  }

  @override
  String cardLink(String id) {
    const configured = String.fromEnvironment('PUBLIC_CARD_ORIGIN');
    final origin = configured.isNotEmpty
        ? configured
        : 'https://${_db.app.options.projectId}.web.app';
    return '${origin.replaceAll(RegExp(r'/$'), '')}/card/${Uri.encodeComponent(id)}';
  }
}
