/// Production input sanitizer and data validator for Recallr.
/// Defends against unbounded strings, control characters, null bytes,
/// malformed data, and storage path traversal attacks.
class InputSanitizer {
  InputSanitizer._();

  /// Default allowed image MIME types.
  static const List<String> defaultImageMimes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  /// Default allowed audio MIME types.
  static const List<String> defaultAudioMimes = [
    'audio/m4a',
    'audio/mp4',
    'audio/aac',
    'audio/mpeg',
    'audio/wav',
    'audio/webm',
  ];

  /// Default allowed document MIME types.
  static const List<String> defaultDocMimes = [
    'application/pdf',
  ];

  /// Combined default allowed capture media MIME types.
  static const List<String> defaultAllowedMimes = [
    ...defaultImageMimes,
    ...defaultAudioMimes,
    ...defaultDocMimes,
  ];

  /// Maximum file size: 25 MB (26,214,400 bytes).
  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  /// Sanitizes a search or Q&A query string.
  /// Removes null bytes, control characters, collapses whitespace, and bounds length.
  static String sanitizeQuery(
    String query, {
    int maxLength = 500,
  }) {
    if (query.isEmpty) return '';

    // 1. Remove null bytes
    var cleaned = query.replaceAll('\x00', '');

    // 2. Remove non-printable control characters (< 32, except space), and DEL (127)
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');

    // 3. Normalize multiple whitespace into single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 4. Bound length
    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength).trim();
    }

    return cleaned;
  }

  /// Sanitizes multiline text notes, descriptions, summaries, and transcripts.
  /// Removes null bytes and dangerous control characters while preserving valid newlines and tabs.
  static String sanitizeText(
    String text, {
    int maxLength = 10000,
  }) {
    if (text.isEmpty) return '';

    // 1. Remove null bytes
    var cleaned = text.replaceAll('\x00', '');

    // 2. Remove control characters except standard whitespace: newline (\n = 10), carriage return (\r = 13), tab (\t = 9)
    cleaned = cleaned.replaceAll(RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // 3. Normalize line endings (\r\n -> \n, \r -> \n)
    cleaned = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 4. Trim leading and trailing whitespace
    cleaned = cleaned.trim();

    // 5. Bound length
    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength).trim();
    }

    return cleaned;
  }

  /// Sanitizes person and organization names.
  /// Preserves unicode letters, accents, spaces, hyphens, and apostrophes while removing control characters.
  static String sanitizeName(
    String name, {
    int maxLength = 100,
  }) {
    if (name.isEmpty) return '';

    // 1. Remove null bytes and control chars
    var cleaned = name.replaceAll('\x00', '');
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');

    // 2. Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 3. Bound length
    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength).trim();
    }

    return cleaned;
  }

  /// Validates and normalizes an email address.
  /// Returns lowercase normalized email or null if invalid/empty.
  static String? sanitizeEmail(String? email) {
    if (email == null) return null;

    final cleaned = email.replaceAll('\x00', '').trim().toLowerCase();
    if (cleaned.isEmpty) return null;

    // Standard email regex validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );

    if (!emailRegex.hasMatch(cleaned) || cleaned.length > 254) {
      return null;
    }

    return cleaned;
  }

  /// Validates and normalizes a phone number string.
  /// Preserves '+', digits, dashes, spaces, and parentheses. Returns null if invalid/empty.
  static String? sanitizePhone(String? phone) {
    if (phone == null) return null;

    final cleaned = phone.replaceAll('\x00', '').trim();
    if (cleaned.isEmpty) return null;

    // Filter to phone characters: +, digits, space, -, (, ), .
    final filtered = cleaned.replaceAll(RegExp(r'[^\d+\-\s().]'), '');
    final digitsOnly = filtered.replaceAll(RegExp(r'\D'), '');

    // Must have at least 5 digits to be a plausible phone number and at most 20
    if (digitsOnly.length < 5 || digitsOnly.length > 20) {
      return null;
    }

    return filtered;
  }

  /// Validates whether a given MIME type is in the allowed whitelist.
  static bool isValidMimeType(
    String mimeType,
    List<String> allowedMimes,
  ) {
    if (mimeType.isEmpty) return false;
    final normalized = mimeType.trim().toLowerCase();
    return allowedMimes.any((allowed) => allowed.toLowerCase() == normalized);
  }

  /// Validates file size in bytes against maximum limit.
  static bool isValidFileSize(
    int bytes, {
    int maxBytes = maxFileSizeBytes,
  }) {
    return bytes > 0 && bytes <= maxBytes;
  }

  /// Validates that a Cloud Storage path is strictly scoped to the expected authenticated user
  /// under `users/{expectedUid}/captures/...` and contains no path traversal sequences (`..`, `//`, `\`).
  static bool isValidStoragePath(
    String path,
    String expectedUid,
  ) {
    if (path.isEmpty || expectedUid.isEmpty) return false;

    // Reject null bytes, backslashes, and path traversal
    if (path.contains('\x00') ||
        path.contains('\\') ||
        path.contains('..') ||
        path.contains('//')) {
      return false;
    }

    // Must strictly start with users/{expectedUid}/captures/
    final expectedPrefix = 'users/$expectedUid/captures/';
    if (!path.startsWith(expectedPrefix)) {
      return false;
    }

    // Must have a captureId and fileName
    final suffix = path.substring(expectedPrefix.length);
    final segments = suffix.split('/');
    if (segments.length != 2) {
      return false;
    }

    final captureId = segments[0];
    final fileName = segments[1];

    if (captureId.isEmpty || fileName.isEmpty) {
      return false;
    }

    // Must not contain special characters in IDs or file names
    final validSegmentRegex = RegExp(r'^[a-zA-Z0-9_\-\.]+$');
    return validSegmentRegex.hasMatch(captureId) && validSegmentRegex.hasMatch(fileName);
  }
}