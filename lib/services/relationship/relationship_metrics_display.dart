/// Utility class for human-readable display of relationship metric timestamps.
/// Formats stored DateTime values as relative strings at display time.
/// This keeps the stored data as real timestamps while rendering is human-friendly.
class RelationshipMetricsDisplay {
  RelationshipMetricsDisplay._();

  /// Format a DateTime as a human-readable relative string.
  /// Examples: "Just now", "2 hours ago", "3 days ago", "Oct 15, 2026"
  static String formatRelativeTime(DateTime? dt, {DateTime? referenceDate}) {
    if (dt == null) return 'Unknown';
    final now = referenceDate ?? DateTime.now();
    final diff = now.difference(dt);

    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d days ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w week${w == 1 ? '' : 's'} ago';
    }
    // For older dates, show formatted date
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// Returns the best available display string for lastInteraction.
  /// Prefers the stored `lastInteractionAt` DateTime, falls back to the
  /// legacy string field for backward compatibility with old records.
  static String formatLastInteraction({
    DateTime? lastInteractionAt,
    String? lastInteractionString,
    DateTime? referenceDate,
  }) {
    if (lastInteractionAt != null) {
      return formatRelativeTime(lastInteractionAt, referenceDate: referenceDate);
    }
    // Backward-compatible fallback: use existing string for old records
    if (lastInteractionString != null &&
        lastInteractionString.isNotEmpty &&
        lastInteractionString != 'Never' &&
        lastInteractionString != 'Unknown') {
      return lastInteractionString;
    }
    return 'Never';
  }
}
