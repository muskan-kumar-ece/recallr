import '../features/people/models/person_item.dart';

/// Abstract contract for People directory operations.
abstract class PeopleRepository {
  /// Stream of all active people for the authenticated user with optional search & filter.
  Stream<List<PersonItem>> streamPeople({
    String? query,
    PeopleFilterOption? filter,
    int limit = 100,
  });

  /// Stream of recently interacted people.
  Stream<List<PersonItem>> streamRecentlyInteracted({int limit = 5});

  /// Fetch a single person item by ID.
  Future<PersonItem?> getPerson(String id);

  /// Create a new person in the network directory.
  Future<void> addPerson(PersonItem person);

  /// Update an existing person's details.
  Future<void> updatePerson(PersonItem person);

  /// Soft-delete or remove a person from the directory.
  Future<void> deletePerson(String id);

  /// Find a person by normalized email.
  Future<PersonItem?> findPersonByEmail(String normalizedEmail);

  /// Find a person by normalized phone number.
  Future<PersonItem?> findPersonByPhone(String normalizedPhone);

  /// Find candidate people by normalized name.
  Future<List<PersonItem>> findCandidatesByName(String normalizedName);

  /// Find candidates by name and company.
  Future<List<PersonItem>> findCandidatesByNameAndCompany(String normalizedName, String normalizedCompany);

  /// Create a new person from resolved capture entities.
  Future<PersonItem> createPersonFromCapture(PersonItem person);

  /// Enrich/update an existing person with non-destructive updates.
  Future<PersonItem> enrichPerson(String personId, Map<String, dynamic> updates);
}