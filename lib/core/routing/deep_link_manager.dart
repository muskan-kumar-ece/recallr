/// Central manager for preserving and restoring deep-links across the authentication boundary.
class DeepLinkManager {
  static final DeepLinkManager _instance = DeepLinkManager._internal();
  factory DeepLinkManager() => _instance;
  DeepLinkManager._internal();

  String? _pendingPath;

  /// Returns the current pending deep-link path without consuming it.
  String? get pendingPath => _pendingPath;

  /// Captures an intended deep-link path when an unauthenticated user attempts access.
  void setPendingPath(String? path) {
    if (path != null && path.isNotEmpty && path != '/' && path != '/auth' && path != '/home') {
      _pendingPath = path;
    }
  }

  /// Consumes and clears the pending deep-link path for post-auth restoration.
  String? consumePendingPath() {
    final path = _pendingPath;
    _pendingPath = null;
    return path;
  }

  /// Explicitly clears any pending deep-link path without consuming.
  void clearPendingPath() {
    _pendingPath = null;
  }
}