import 'dart:async';
import '../../features/cards/models/visiting_card.dart';
import '../../features/categories/models/network_category.dart';
import '../../repositories/library_repository.dart';

/// Empty in-memory library for explicitly configured previews and tests.
class MemoryLibraryRepository implements LibraryRepository {
  final _categories = <String, NetworkCategory>{};
  final _drafts = <String, VisitingCard>{};
  final _public = <String, VisitingCard>{};
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<List<NetworkCategory>> categories() async* {
    yield _categories.values.toList();
    yield* _changes.stream.map((_) => _categories.values.toList());
  }

  @override
  Future<NetworkCategory> saveCategory(NetworkCategory category) async {
    if (_categories.values.any((c) =>
        c.id != category.id &&
        c.name.toLowerCase() == category.name.trim().toLowerCase())) {
      throw StateError('A category with that name already exists.');
    }
    final value = NetworkCategory(
        id: category.id.isEmpty ? '${_categories.length + 1}' : category.id,
        name: category.name.trim(),
        icon: category.icon,
        color: category.color,
        order: category.order);
    _categories[value.id] = value;
    _changes.add(null);
    return value;
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.remove(id);
    _changes.add(null);
  }

  @override
  Stream<List<LibraryEntry>> entries(String collection) => Stream.value([]);
  @override
  Future<void> categorize(
      String collection, String id, List<String> categories) async {}
  @override
  Future<VisitingCard?> getDraft(String id) async => _drafts[id];
  @override
  Future<void> saveDraft(VisitingCard card) async {
    _drafts[card.id] = card;
  }

  @override
  Future<String> publish(VisitingCard card) async {
    _drafts[card.id] = card;
    _public[card.id] = VisitingCard(
        id: card.id,
        fields: card.publicFields,
        visibleFields: card.visibleFields,
        layout: card.layout,
        accent: card.accent,
        published: true,
        version: card.version + 1,
        publicId: card.id);
    return card.id;
  }

  @override
  Future<void> unpublish(String draftId) async {
    _public.remove(draftId);
  }

  @override
  Future<VisitingCard?> getPublicCard(String id) async => _public[id];
  @override
  Future<String> importCard(
          String id, List<String> categories, String note) async =>
      'card_$id';
  @override
  String cardLink(String id) => 'https://example.invalid/card/$id';
}
