import '../features/cards/models/visiting_card.dart';
import '../features/categories/models/network_category.dart';

class LibraryEntry {
  final String id, collection, title, route;
  final List<String> categoryIds;
  const LibraryEntry(
      {required this.id,
      required this.collection,
      required this.title,
      required this.route,
      this.categoryIds = const []});
}

abstract class LibraryRepository {
  Stream<List<NetworkCategory>> categories();
  Future<NetworkCategory> saveCategory(NetworkCategory category);
  Future<void> deleteCategory(String id);
  Stream<List<LibraryEntry>> entries(String collection);
  Future<void> categorize(
      String collection, String id, List<String> categories);
  Future<VisitingCard?> getDraft(String id);
  Future<void> saveDraft(VisitingCard card);
  Future<String> publish(VisitingCard card);
  Future<void> unpublish(String draftId);
  Future<VisitingCard?> getPublicCard(String id);
  Future<String> importCard(String id, List<String> categories, String note);
  String cardLink(String id);
}
