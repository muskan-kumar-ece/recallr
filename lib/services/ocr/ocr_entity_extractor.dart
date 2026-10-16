import '../../features/capture/models/ocr_models.dart';

/// Deterministic heuristic & pattern-based extractor for structured relationship entities from OCR text.
class OcrEntityExtractor {
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?[0-9]{1,3}[-.\s]?)?\(?[0-9]{2,4}\)?[-.\s]?[0-9]{3,4}[-.\s]?[0-9]{3,4}',
  );

  static final RegExp _websiteRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9-]+\.(?:com|io|org|net|ai|co|dev|tech|app|in|edu|gov)(?:\/[^\s]*)?',
    caseSensitive: false,
  );

  static final List<String> _roleKeywords = [
    'vp', 'vice president', 'director', 'architect', 'engineer', 'founder', 'co-founder',
    'lead', 'head of', 'ceo', 'cto', 'coo', 'cpo', 'cfo', 'ciso', 'manager', 'partner',
    'principal', 'fellow', 'consultant', 'specialist', 'developer', 'scientist', 'designer',
  ];

  static final List<String> _companySuffixes = [
    'inc', 'llc', 'corp', 'corporation', 'ltd', 'limited', 'technologies', 'technology',
    'systems', 'labs', 'ai', 'photonics', 'semiconductor', 'ventures', 'solutions', 'studio',
    'group', 'capital', 'robotics', 'software', 'cloud', 'networks',
  ];

  static final List<String> _locationKeywords = [
    'san francisco', 'palo alto', 'mountain view', 'sunnyvale', 'santa clara', 'san jose',
    'seattle', 'new york', 'boston', 'austin', 'london', 'zurich', 'berlin', 'singapore',
    'tokyo', 'bengaluru', 'hyderabad', 'mumbai', 'delhi', 'ca', 'ny', 'tx', 'wa',
    'street', 'st.', 'avenue', 'ave.', 'blvd', 'suite', 'floor', 'building', 'usa',
  ];

  /// Extracts structured relationship entities from an OcrResult or raw text.
  static OcrExtractedEntities extract(String text) {
    if (text.trim().isEmpty) {
      return const OcrExtractedEntities();
    }

    final rawLines = text.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    String? email = _extractEmail(text);
    String? phone = _extractPhone(text);
    String? website = _extractWebsite(text);
    String? role = _extractRole(rawLines);
    String? company = _extractCompany(rawLines, email: email, website: website);
    String? name = _extractName(rawLines, role: role, company: company, email: email);
    String? location = _extractLocation(rawLines);
    String? date = _extractDate(text);

    // Extract notable non-contact bullet key points
    final keyPoints = <String>[];
    for (final line in rawLines) {
      if (line != name && line != role && line != company && line != location &&
          !line.contains('@') && !line.contains('http') && line.length > 5) {
        keyPoints.add(line);
      }
    }

    return OcrExtractedEntities(
      name: name,
      role: role,
      company: company,
      email: email,
      phone: phone,
      website: website,
      location: location,
      date: date,
      keyPoints: keyPoints,
    );
  }

  static String? _extractEmail(String text) {
    final match = _emailRegex.firstMatch(text);
    return match?.group(0);
  }

  static String? _extractPhone(String text) {
    final match = _phoneRegex.firstMatch(text);
    final phone = match?.group(0);
    if (phone != null && phone.replaceAll(RegExp(r'[^0-9]'), '').length >= 7) {
      return phone.trim();
    }
    return null;
  }

  static String? _extractWebsite(String text) {
    for (final match in _websiteRegex.allMatches(text)) {
      final start = match.start;
      if (start > 0 && text[start - 1] == '@') {
        continue;
      }
      final site = match.group(0);
      if (site != null && !site.contains('@')) {
        return site;
      }
    }
    return null;
  }

  static String? _extractRole(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final kw in _roleKeywords) {
        if (lower.contains(kw) && !lower.contains('@') && line.length < 60) {
          return line.replaceAll(RegExp(r'^(role|title):\s*', caseSensitive: false), '').trim();
        }
      }
    }
    return null;
  }

  static String? _extractCompany(List<String> lines, {String? email, String? website}) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final suffix in _companySuffixes) {
        if (lower.contains(suffix) && !lower.contains('@') && !lower.contains('http') && line.length < 50) {
          return line.replaceAll(RegExp(r'^(company|org):\s*', caseSensitive: false), '').trim();
        }
      }
    }

    // Fallback heuristic: Extract domain organization from email
    if (email != null && email.contains('@')) {
      final domain = email.split('@').last;
      final parts = domain.split('.');
      if (parts.isNotEmpty && parts.first != 'gmail' && parts.first != 'yahoo' && parts.first != 'outlook') {
        final rawComp = parts.first;
        return rawComp[0].toUpperCase() + rawComp.substring(1);
      }
    }

    return null;
  }

  static String? _extractName(List<String> lines, {String? role, String? company, String? email}) {
    for (final line in lines) {
      if (line == role || line == company) continue;
      if (line.contains('@') || line.contains('www') || line.contains('+') || line.contains('http')) continue;

      // Clean prefix if "Name: ..."
      final cleaned = line.replaceAll(RegExp(r'^(name):\s*', caseSensitive: false), '').trim();
      final words = cleaned.split(RegExp(r'\s+'));

      // Typical name format: 2 to 4 capitalized words, no numbers
      if (words.length >= 2 && words.length <= 4 && !cleaned.contains(RegExp(r'[0-9]')) && cleaned.length < 40) {
        final isAllCapitalized = words.every((w) => w.isNotEmpty && w[0] == w[0].toUpperCase());
        if (isAllCapitalized) {
          return cleaned;
        }
      }
    }

    // Fallback from email: "sarah.chen@..." -> "Sarah Chen"
    if (email != null && email.contains('@')) {
      final userPart = email.split('@').first;
      if (userPart.contains('.')) {
        return userPart
            .split('.')
            .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
            .join(' ')
            .trim();
      }
    }

    return null;
  }

  static String? _extractLocation(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final kw in _locationKeywords) {
        if (lower.contains(kw) && !lower.contains('@') && !lower.contains('http') && line.length < 60) {
          return line.replaceAll(RegExp(r'^(location|address):\s*', caseSensitive: false), '').trim();
        }
      }
    }
    return null;
  }

  static String? _extractDate(String text) {
    final dateRegex = RegExp(r'(?:\d{4}-\d{2}-\d{2})|(?:\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}\b)', caseSensitive: false);
    final match = dateRegex.firstMatch(text);
    return match?.group(0);
  }
}