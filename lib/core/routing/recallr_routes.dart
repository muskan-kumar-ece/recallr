/// Centralized route constants and deep-link generators for Recallr.
class RecallrRoutes {
  RecallrRoutes._();

  // Core Authentication & Entry
  static const String initial = '/';
  static const String auth = '/auth';

  // Primary App Shell Tabs
  static const String home = '/home';
  static const String people = '/people';
  static const String capture = '/capture';
  static const String ask = '/ask';
  static const String activity = '/activity';

  // Future Deep-Link & Parametric Context Routes (P1/P2 Foundation)
  static const String person = '/person';
  static const String company = '/company';
  static const String event = '/event';
  static const String file = '/file';
  static const String interaction = '/interaction';
  static const String followUp = '/follow-up';
  static const String network = '/network';
  static const String settings = '/settings';
  static const String subscription = '/subscription';

  // Helpers for generating future deep-link paths
  static String personPath(String id) => '/person/$id';
  static String companyPath(String id) => '/company/$id';
  static String eventPath(String id) => '/event/$id';
  static String filePath(String id) => '/file/$id';
  static String interactionPath(String id) => '/interaction/$id';
  static String followUpPath(String id) => '/follow-up/$id';
}