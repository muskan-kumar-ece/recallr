import '../../features/capture/models/ocr_models.dart';

/// Deterministic heuristic & pattern-based extractor for structured relationship entities from OCR text.
class OcrEntityExtractor {
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?[0-9]{1,4}[-.\s]?)?(?:\(?[0-9]{2,5}\)?[-.\s]?)?[0-9]{3,5}[-.\s]?[0-9]{3,5}',
  );

  static final RegExp _websiteRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9-]+\.(?:com|io|org|net|ai|co|dev|tech|app|in|edu|gov)(?:\/[^\s]*)?',
    caseSensitive: false,
  );

  static final RegExp _pinCodeRegex = RegExp(r'\b\d{6}\b');

  static final List<String> _roleKeywords = [
    'vp', 'vice president', 'director', 'managing director', 'architect', 'engineer',
    'founder', 'co-founder', 'lead', 'head of', 'ceo', 'cto', 'coo', 'cpo', 'cfo',
    'ciso', 'manager', 'partner', 'principal', 'fellow', 'consultant', 'specialist',
    'developer', 'scientist', 'designer', 'proprietor', 'president', 'executive',
  ];

  static final List<String> _companySuffixes = [
    'inc', 'llc', 'corp', 'corporation', 'ltd', 'limited', 'technologies', 'technology',
    'systems', 'labs', 'ai', 'photonics', 'semiconductor', 'ventures', 'solutions', 'studio',
    'group', 'capital', 'robotics', 'software', 'cloud', 'networks', 'enterprises',
    'industries', 'electricals', 'associates', 'agency', 'distributors', 'traders',
  ];

  /// Configurable and extensible constant list of known product brands.
  static const List<String> knownBrands = [
    'WAGO', 'HAVELLS', 'SCHNEIDER', 'SIEMENS', 'L&T', 'ABB', 'LEGRAND',
    'PHILIPS', 'POLYCAB', 'FINOLEX', 'ANCHOR', 'CROMPTON', 'HONEYWELL',
    'BOSCH', 'PANASONIC', 'MITSUBISHI', 'ROCKWELL', 'EATON', 'OMRON',
    'RR KABEL', 'ORIENT', 'V-GUARD', 'BAJAJ', 'KEI', 'HIKVISION',
  ];

  static final List<String> _addressKeywords = [
    'nagar', 'road', 'rd', 'street', 'st', 'estate', 'plot', 'industrial',
    'floor', 'opp', 'near', 'pune', 'hyderabad', 'sector', 'phase', 'lane',
    'marg', 'colony', 'layout', 'bhavan', 'complex', 'tower', 'chambers',
    'park', 'gidc', 'midc', 'zone', 'block', 'avenue', 'ave', 'blvd',
    'behind', 'beside', 'dist', 'district', 'city', 'mumbai', 'delhi',
    'bengaluru', 'bangalore', 'chennai', 'kolkata', 'ahmedabad', 'gurugram',
    'gurgaon', 'noida', 'building', 'bldg', 'flat', 'shop', 'unit', 'cross',
    'main', 'san francisco', 'palo alto', 'mountain view', 'sunnyvale',
    'santa clara', 'san jose', 'seattle', 'new york', 'boston', 'austin',
    'london', 'zurich', 'berlin', 'singapore', 'tokyo', 'suite', 'usa',
  ];

  static final List<String> _genericEmailPrefixes = [
    'info', 'sales', 'support', 'contact', 'admin', 'office', 'service',
    'help', 'team', 'enquiry', 'billing', 'mail', 'care', 'general',
  ];

  /// Checks if a candidate person name is likely invalid (e.g. an address line,
  /// company line, or noise misclassified as a name).
  static bool isLikelyInvalidName(String? name) {
    if (name == null) return true;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return true;

    // Reject if it contains digits
    if (trimmed.contains(RegExp(r'\d'))) return true;

    // Reject if it contains web / email tokens
    if (trimmed.contains('@') ||
        trimmed.contains(RegExp(r'https?:\/\/', caseSensitive: false)) ||
        RegExp(r'\bwww\b', caseSensitive: false).hasMatch(trimmed) ||
        trimmed.contains(RegExp(r'\.(com|in|org|net|io|co|ai)\b', caseSensitive: false))) {
      return true;
    }

    // Reject if it contains parentheses, brackets, or invalid punctuation
    if (trimmed.contains('(') ||
        trimmed.contains(')') ||
        trimmed.contains('[') ||
        trimmed.contains(']') ||
        trimmed.contains('{') ||
        trimmed.contains('}') ||
        trimmed.endsWith(',') ||
        trimmed.endsWith(';') ||
        trimmed.contains('|') ||
        trimmed.contains('*')) {
      return true;
    }

    final lower = trimmed.toLowerCase();

    // Reject if it contains company suffixes
    for (final suffix in _companySuffixes) {
      if (RegExp(r'\b' + RegExp.escape(suffix) + r'\b', caseSensitive: false).hasMatch(lower)) {
        return true;
      }
    }

    // Reject if it contains strong physical address words
    final strongAddressWords = [
      'industrial', 'estate', 'road', 'rd', 'street', 'st', 'plot',
      'floor', 'sector', 'phase', 'gidc', 'midc', 'complex', 'bldg',
      'building', 'flat', 'shop', 'avenue', 'blvd', 'layout', 'colony',
    ];
    for (final word in strongAddressWords) {
      if (RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false).hasMatch(lower)) {
        return true;
      }
    }

    // If it contains "nagar" without an explicit person honorific
    if (RegExp(r'\bnagar\b', caseSensitive: false).hasMatch(lower)) {
      final words = trimmed.split(RegExp(r'\s+'));
      if (words.length == 1 || words.first.toLowerCase() == 'nagar') {
        return true;
      }
    }

    // Check PIN code
    if (_pinCodeRegex.hasMatch(trimmed)) return true;

    // Word count check: typical person name is 2-4 words
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length > 5) return true;

    return false;
  }

  /// Extracts structured relationship entities from OCR text conforming to the strict contract:
  /// {
  ///   "name": string | null,
  ///   "designation": string | null,
  ///   "company": string | null,
  ///   "brands": string[],
  ///   "phones": string[],
  ///   "emails": string[],
  ///   "website": string | null,
  ///   "address": string | null,
  ///   "confidence": { "name": 0-1 }
  /// }
  static OcrExtractedEntities extract(String text) {
    if (text.trim().isEmpty) {
      return const OcrExtractedEntities(confidence: {'name': 0.0});
    }

    final rawLines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => !_isNoiseLine(l))
        .toList();

    // 1. Extract contact mediums
    final emails = _extractAllEmails(text);
    final primaryEmail = emails.isNotEmpty ? emails.first : null;
    final phones = _extractAllPhones(text);
    final primaryPhone = phones.isNotEmpty ? phones.first : null;
    final website = _extractWebsite(text);

    // 2. Extract brands (known list + dynamic ALL-CAPS brand candidates)
    final brands = _extractBrands(rawLines, text);

    // 3. Extract designation & company (supports compound lines)
    final roleAndCompany = _extractRoleAndCompany(rawLines, email: primaryEmail, website: website, brands: brands);
    final designation = roleAndCompany.role;
    final company = roleAndCompany.company;

    // 4. Extract address / location lines
    final address = _extractAddress(rawLines, brands: brands, company: company, designation: designation);

    // 5. Extract person's name with strict address/brand rejection rules & email cross-check
    final nameExtraction = _extractNameWithConfidence(
      rawLines,
      designation: designation,
      company: company,
      email: primaryEmail,
      brands: brands,
      address: address,
    );

    final extractedName = nameExtraction.name;
    final nameConfidence = nameExtraction.confidence;
    final date = _extractDate(text);

    // Extract notable non-contact bullet key points
    final keyPoints = <String>[];
    for (final line in rawLines) {
      if (line != extractedName &&
          line != designation &&
          line != company &&
          line != address &&
          !brands.contains(line.toUpperCase()) &&
          !line.contains('@') &&
          !line.contains('http') &&
          !_isPhoneLine(line) &&
          line.length > 5) {
        keyPoints.add(line);
      }
    }

    return OcrExtractedEntities(
      name: extractedName,
      role: designation,
      company: company,
      email: primaryEmail,
      phone: primaryPhone,
      website: website,
      location: address,
      date: date,
      keyPoints: keyPoints,
      designation: designation,
      address: address,
      brands: brands,
      phones: phones,
      emails: emails,
      confidence: {'name': nameConfidence},
    );
  }

  static bool _isNoiseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed.length == 1) return true; // single stray character: •, a, -, etc.

    // Non-alphanumeric noise lines: e.g. "• • •", "---", "***", "||"
    if (trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').isEmpty) return true;

    // Lone web prefix or fragment: "www", "http", "https", "com"
    if (RegExp(r'^(www|http|https|com|org|net)$', caseSensitive: false).hasMatch(trimmed)) return true;

    return false;
  }

  static List<String> _extractAllEmails(String text) {
    final results = <String>[];
    for (final match in _emailRegex.allMatches(text)) {
      final email = match.group(0);
      if (email != null && !results.contains(email)) {
        results.add(email);
      }
    }
    // Sort so personal emails (not starting with info, sales, support) appear before generic emails
    results.sort((a, b) {
      final aPrefix = a.split('@').first.toLowerCase();
      final bPrefix = b.split('@').first.toLowerCase();
      final aGeneric = _genericEmailPrefixes.contains(aPrefix);
      final bGeneric = _genericEmailPrefixes.contains(bPrefix);
      if (!aGeneric && bGeneric) return -1;
      if (aGeneric && !bGeneric) return 1;
      return 0;
    });
    return results;
  }

  static List<String> _extractAllPhones(String text) {
    final results = <String>[];
    final lines = text.split(RegExp(r'\r?\n'));

    // 1. First scan lines for explicit phone labels: M:, Ph:, Tel:, Mobile:, Cell:
    final labelRegex = RegExp(
      r'^(?:m|mob|mobile|cell|ph|phone|tel|telephone|fax)[:.]?\s*(.*)$',
      caseSensitive: false,
    );
    for (final line in lines) {
      final trimmed = line.trim();
      final match = labelRegex.firstMatch(trimmed);
      if (match != null) {
        final candidate = match.group(1)?.trim() ?? '';
        final digitsOnly = candidate.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.length >= 7 && digitsOnly.length <= 15) {
          if (!results.contains(candidate)) {
            results.add(candidate);
          }
        }
      }
    }

    // 2. Scan full text with phone regex for any additional numbers
    for (final match in _phoneRegex.allMatches(text)) {
      final raw = match.group(0);
      if (raw != null) {
        final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.length >= 7 && digitsOnly.length <= 15) {
          final trimmed = raw.trim();
          if (!_pinCodeRegex.hasMatch(trimmed) &&
              !results.any((p) => p.replaceAll(RegExp(r'[^0-9]'), '') == digitsOnly)) {
            results.add(trimmed);
          }
        }
      }
    }
    return results;
  }

  static bool _isPhoneLine(String line) {
    final lower = line.toLowerCase().trim();
    final isExplicitPhonePrefix = RegExp(
      r'^(?:m|mob|mobile|cell|ph|phone|tel|telephone|fax)[:.]?\s*',
      caseSensitive: false,
    ).hasMatch(lower);

    // If it contains non-prefix letters (e.g. "Shop 14, Gandhi Road, Hyderabad"), it's not a phone line
    final cleanLetters = lower
        .replaceAll(RegExp(r'^(tel|phone|mobile|cell|m|ph|fax|telephone|mob)[:.]?\s*'), '')
        .replaceAll(RegExp(r'[^a-z]'), '');

    if (!isExplicitPhonePrefix && cleanLetters.length > 3) {
      return false;
    }

    final digitsOnly = line.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length >= 7 && digitsOnly.length <= 15;
  }

  static String? _extractWebsite(String text) {
    for (final match in _websiteRegex.allMatches(text)) {
      final start = match.start;
      if (start > 0 && text[start - 1] == '@') continue;
      final site = match.group(0);
      if (site != null && !site.contains('@')) {
        return site;
      }
    }
    return null;
  }

  static List<String> _extractBrands(List<String> lines, String fullText) {
    final detectedBrands = <String>{};

    // 1. Scan dealer / distributor / brand headers
    final brandHeaderRegex = RegExp(
      r'(?:dealers?\s+in|authorised\s+dealers?|authorized\s+dealers?|distributors?\s+(?:of|for)|stockists?|brands?|products?):\s*(.*)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = brandHeaderRegex.firstMatch(line);
      if (match != null) {
        final content = match.group(1) ?? '';
        final tokens = content.split(RegExp(r'[,|;/•]+')).map((t) => t.trim()).where((t) => t.isNotEmpty);
        for (final token in tokens) {
          detectedBrands.add(token.toUpperCase());
        }
      }
    }

    // 2. Scan known brands list with whole-word matching
    for (final brand in knownBrands) {
      final pattern = RegExp(r'\b' + RegExp.escape(brand) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(fullText)) {
        detectedBrands.add(brand);
      }
    }

    // 3. Dynamic brand detection: short ALL-CAPS single-word lines
    for (final line in lines) {
      final trimmed = line.trim();
      if (RegExp(r'^[A-Z&]{2,15}$').hasMatch(trimmed)) {
        final lower = trimmed.toLowerCase();
        final isRole = _roleKeywords.any((r) => RegExp(r'\b' + RegExp.escape(r) + r'\b', caseSensitive: false).hasMatch(lower));
        final isAddress = _addressKeywords.any((a) => RegExp(r'\b' + RegExp.escape(a) + r'\b', caseSensitive: false).hasMatch(lower));
        final isCompanySuffix = _companySuffixes.any((s) => RegExp(r'\b' + RegExp.escape(s) + r'\b', caseSensitive: false).hasMatch(lower));
        final isCommonAbbr = RegExp(
          r'^(?:mr|mrs|ms|dr|prof|ph|tel|mob|cell|fax|pin|po|usa|uk|uae|ind|in|no|off|st)$',
          caseSensitive: false,
        ).hasMatch(lower);

        if (!isRole && !isAddress && !isCompanySuffix && !isCommonAbbr) {
          detectedBrands.add(trimmed);
        }
      }
    }

    return detectedBrands.toList()..sort();
  }

  static _RoleAndCompanyResult _extractRoleAndCompany(
    List<String> lines, {
    String? email,
    String? website,
    List<String> brands = const [],
  }) {
    String? foundRole;
    String? foundCompany;

    // 1. Check for compound lines (e.g. "Director, Bandhan Industries Ltd" or "Software Engineer at Acme Corp")
    final compoundSeparator = RegExp(r'\s*[-–—|@]\s*|,\s+|\s+at\s+', caseSensitive: false);

    for (final line in lines) {
      if (brands.any((b) => RegExp(r'\b' + RegExp.escape(b) + r'\b', caseSensitive: false).hasMatch(line))) continue;
      if (line.contains('@') || line.contains('http') || _isPhoneLine(line)) continue;

      if (compoundSeparator.hasMatch(line)) {
        final parts = line.split(compoundSeparator).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        if (parts.length >= 2) {
          final first = parts[0];
          final second = parts[1];

          final firstIsRole = _roleKeywords.any((kw) => RegExp(r'\b' + RegExp.escape(kw) + r'\b', caseSensitive: false).hasMatch(first.toLowerCase()));
          final secondIsRole = _roleKeywords.any((kw) => RegExp(r'\b' + RegExp.escape(kw) + r'\b', caseSensitive: false).hasMatch(second.toLowerCase()));

          if (firstIsRole && !secondIsRole) {
            foundRole ??= first.replaceAll(RegExp(r'^(role|title|designation):\s*', caseSensitive: false), '').trim();
            foundCompany ??= _formatCompanyTitle(second.replaceAll(RegExp(r'^(company|org):\s*', caseSensitive: false), '').trim());
          } else if (secondIsRole && !firstIsRole) {
            foundRole ??= second.replaceAll(RegExp(r'^(role|title|designation):\s*', caseSensitive: false), '').trim();
            foundCompany ??= _formatCompanyTitle(first.replaceAll(RegExp(r'^(company|org):\s*', caseSensitive: false), '').trim());
          }
        }
      }
    }

    // 2. Separate Role extraction
    if (foundRole == null) {
      for (final line in lines) {
        if (brands.any((b) => RegExp(r'\b' + RegExp.escape(b) + r'\b', caseSensitive: false).hasMatch(line))) continue;
        if (line.contains('@') || line.contains('http') || _isPhoneLine(line)) continue;

        for (final kw in _roleKeywords) {
          final kwPattern = RegExp(r'\b' + RegExp.escape(kw) + r'\b', caseSensitive: false);
          if (kwPattern.hasMatch(line) && line.length < 60) {
            foundRole = line.replaceAll(RegExp(r'^(role|title|designation):\s*', caseSensitive: false), '').trim();
            break;
          }
        }
        if (foundRole != null) break;
      }
    }

    // 3. Separate Company extraction
    if (foundCompany == null) {
      for (final line in lines) {
        if (line == foundRole) continue;
        if (brands.any((b) => RegExp(r'\b' + RegExp.escape(b) + r'\b', caseSensitive: false).hasMatch(line))) continue;
        if (line.contains('@') || line.contains('http') || _isPhoneLine(line)) continue;

        for (final suffix in _companySuffixes) {
          final suffixPattern = RegExp(r'\b' + RegExp.escape(suffix) + r'\b', caseSensitive: false);
          if (suffixPattern.hasMatch(line) && line.length < 50) {
            final raw = line.replaceAll(RegExp(r'^(company|org):\s*', caseSensitive: false), '').trim();
            foundCompany = _formatCompanyTitle(raw);
            break;
          }
        }
        if (foundCompany != null) break;
      }

      // Fallback heuristic: Extract domain organization from email
      if (foundCompany == null && email != null && email.contains('@')) {
        final domain = email.split('@').last;
        final parts = domain.split('.');
        if (parts.isNotEmpty && parts.first != 'gmail' && parts.first != 'yahoo' && parts.first != 'outlook') {
          final rawComp = parts.first;
          foundCompany = rawComp[0].toUpperCase() + rawComp.substring(1);
        }
      }
    }

    return _RoleAndCompanyResult(foundRole, foundCompany);
  }

  static String _formatCompanyTitle(String raw) {
    if (raw == raw.toUpperCase() && raw.length > 3) {
      return raw.split(RegExp(r'\s+')).map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');
    }
    return raw;
  }

  static String? _extractAddress(
    List<String> lines, {
    List<String> brands = const [],
    String? company,
    String? designation,
  }) {
    final addressParts = <String>[];

    for (final line in lines) {
      if (line == company || line == designation) continue;
      if (brands.any((b) => RegExp(r'\b' + RegExp.escape(b) + r'\b', caseSensitive: false).hasMatch(line) && line.length < b.length + 5)) continue;
      if (line.contains('@') || line.contains('http') || _isPhoneLine(line)) continue;

      final lower = line.toLowerCase();
      final hasAddressKw = _addressKeywords.any((kw) {
        final pattern = RegExp(r'\b' + RegExp.escape(kw) + r'\b', caseSensitive: false);
        return pattern.hasMatch(lower);
      });
      final hasPinCode = _pinCodeRegex.hasMatch(line);

      if (hasAddressKw || hasPinCode) {
        final cleaned = line.replaceAll(RegExp(r'^(location|address):\s*', caseSensitive: false), '').trim();
        if (cleaned.isNotEmpty && !addressParts.contains(cleaned)) {
          addressParts.add(cleaned);
        }
      }
    }

    if (addressParts.isEmpty) return null;
    return addressParts.join(', ');
  }

  static _NameExtractionResult _extractNameWithConfidence(
    List<String> lines, {
    String? designation,
    String? company,
    String? email,
    List<String> brands = const [],
    String? address,
  }) {
    String? candidateFromText;

    for (final line in lines) {
      if (designation != null && line.toLowerCase().trim() == designation.toLowerCase().trim()) continue;
      if (company != null && line.toLowerCase().trim() == company.toLowerCase().trim()) continue;
      if (line.contains('@') ||
          RegExp(r'\bwww\b', caseSensitive: false).hasMatch(line) ||
          line.contains('+') ||
          RegExp(r'https?:\/\/', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      if (_isPhoneLine(line)) continue;

      // Reject lines matching brands using whole-word matching
      if (brands.any((b) => RegExp(r'\b' + RegExp.escape(b) + r'\b', caseSensitive: false).hasMatch(line))) continue;

      // Reject lines containing digits or web terms
      if (line.contains(RegExp(r'[0-9]')) ||
          line.contains(RegExp(r'\.(com|org|net|in|io|co|ai|app|dev)\b', caseSensitive: false))) {
        continue;
      }

      // Reject lines containing company suffixes (Industries, Distributors, Systems, etc.)
      final lower = line.toLowerCase();
      final isCompanyLine = _companySuffixes.any((suffix) {
        final pattern = RegExp(r'\b' + RegExp.escape(suffix) + r'\b', caseSensitive: false);
        return pattern.hasMatch(lower);
      });
      if (isCompanyLine) continue;

      // Reject lines with parentheses, brackets, or invalid name punctuation
      if (line.contains('(') || line.contains(')') || line.contains('[') || line.contains(']') || line.contains('{') || line.contains('}')) {
        continue;
      }

      // Check if person honorific is present (e.g. "Mr. ANIL NAGAR" or "Dr. Sarah Chen")
      final hasPersonHonorific = RegExp(r'^(dr|mr|mrs|ms|prof)\.?\s+', caseSensitive: false).hasMatch(line);

      if (!hasPersonHonorific) {
        // Reject candidate containing address/area words (Nagar, Road, Estate, Plot, Industrial, Pune, etc.)
        final hasAddressKw = _addressKeywords.any((kw) {
          final pattern = RegExp(r'\b' + RegExp.escape(kw) + r'\b', caseSensitive: false);
          return pattern.hasMatch(lower);
        });
        if (hasAddressKw) continue;
      } else {
        // If honorific IS present, only reject if it contains strong physical address words
        final strongPhysicalAddress = [
          'road', 'rd', 'street', 'st', 'estate', 'plot', 'industrial',
          'floor', 'sector', 'phase', 'gidc', 'midc', 'complex', 'building', 'bldg',
        ];
        final hasStrongAddress = strongPhysicalAddress.any((w) {
          return RegExp(r'\b' + RegExp.escape(w) + r'\b', caseSensitive: false).hasMatch(lower);
        });
        if (hasStrongAddress) continue;
      }

      // Clean prefix if "Name: ..."
      var cleaned = line.replaceAll(RegExp(r'^(name):\s*', caseSensitive: false), '').trim();

      // Strip honorifics e.g. "Dr. Sarah Chen" -> "Sarah Chen"
      cleaned = cleaned.replaceAll(RegExp(r'^(dr|mr|mrs|ms|prof)\.?\s+', caseSensitive: false), '').trim();

      final words = cleaned.split(RegExp(r'\s+'));

      // Typical name format: 2 to 4 words, purely alphabetic, all capitalized
      if (words.length >= 2 && words.length <= 4 && cleaned.length >= 3 && cleaned.length < 40) {
        final isAllCapitalized = words.every((w) {
          if (w.isEmpty) return false;
          return w[0] == w[0].toUpperCase() && RegExp(r'^[a-zA-Z.]+$').hasMatch(w);
        });

        if (isAllCapitalized) {
          // If the line was in ALL CAPS (e.g. "ANIL NAGAR"), convert it to Title Case ("Anil Nagar")
          if (cleaned == cleaned.toUpperCase()) {
            candidateFromText = words.map((w) {
              if (w.isEmpty) return '';
              if (w.length == 1) return w.toUpperCase();
              return w[0].toUpperCase() + w.substring(1).toLowerCase();
            }).join(' ');
          } else {
            candidateFromText = cleaned;
          }
          break;
        }
      }
    }

    // Cross-check candidate with email
    if (email != null && email.contains('@')) {
      final localPart = email.split('@').first.toLowerCase();
      final isGenericEmail = _genericEmailPrefixes.contains(localPart);

      if (candidateFromText != null) {
        // Compare candidate name against email local part
        final candidateClean = candidateFromText.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        final localClean = localPart.replaceAll(RegExp(r'[^a-z]'), '');

        final hasSimilarity = _hasNameSimilarity(candidateClean, localClean);
        if (hasSimilarity) {
          return _NameExtractionResult(candidateFromText, 0.95);
        } else {
          // Candidate name does not match email at all (e.g., Nagar vs aniln).
          // Fall back to deriving candidate from email if non-generic.
          if (!isGenericEmail) {
            final derived = _deriveNameFromEmailLocalPart(localPart);
            if (derived != null) {
              return _NameExtractionResult(derived, 0.60);
            }
          }
          // If cannot derive from email, return candidate with low confidence
          return _NameExtractionResult(candidateFromText, 0.50);
        }
      } else {
        // No candidate found in text. Attempt to derive from email.
        if (!isGenericEmail) {
          final derived = _deriveNameFromEmailLocalPart(localPart);
          if (derived != null) {
            return _NameExtractionResult(derived, 0.60);
          }
        }
        return const _NameExtractionResult(null, 0.0);
      }
    }

    // No email present
    if (candidateFromText != null) {
      return _NameExtractionResult(candidateFromText, 0.75);
    }

    return const _NameExtractionResult(null, 0.0);
  }

  static bool _hasNameSimilarity(String candidateClean, String localClean) {
    if (candidateClean.isEmpty || localClean.isEmpty) return false;
    if (candidateClean == localClean) return true;
    if (candidateClean.startsWith(localClean) || localClean.startsWith(candidateClean)) return true;

    // Substring match of at least 3 characters
    if (localClean.length >= 3) {
      for (int i = 0; i <= localClean.length - 3; i++) {
        final sub = localClean.substring(i, i + 3);
        if (candidateClean.contains(sub)) return true;
      }
    }

    return false;
  }

  static String? _deriveNameFromEmailLocalPart(String localPart) {
    // 1. Dotted or underscored names: "sarah.chen" -> "Sarah Chen"
    if (localPart.contains('.') || localPart.contains('_') || localPart.contains('-')) {
      final tokens = localPart.split(RegExp(r'[._-]')).where((t) => t.isNotEmpty).toList();
      if (tokens.isNotEmpty) {
        return tokens.map((t) => t[0].toUpperCase() + t.substring(1).toLowerCase()).join(' ');
      }
    }

    // 2. Pattern: first name + initial (e.g., "aniln" -> "Anil N")
    if (localPart.length >= 4 && RegExp(r'^[a-z]+$').hasMatch(localPart)) {
      final namePart = localPart.substring(0, localPart.length - 1);
      final initial = localPart.substring(localPart.length - 1).toUpperCase();
      final capitalizedFirst = namePart[0].toUpperCase() + namePart.substring(1).toLowerCase();
      return '$capitalizedFirst $initial';
    }

    // 3. Single word name: "rajesh" -> "Rajesh"
    if (localPart.length >= 3 && RegExp(r'^[a-z]+$').hasMatch(localPart)) {
      return localPart[0].toUpperCase() + localPart.substring(1).toLowerCase();
    }

    return null;
  }

  static String? _extractDate(String text) {
    final dateRegex = RegExp(
      r'(?:\d{4}-\d{2}-\d{2})|(?:\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}\b)',
      caseSensitive: false,
    );
    final match = dateRegex.firstMatch(text);
    return match?.group(0);
  }
}

class _RoleAndCompanyResult {
  final String? role;
  final String? company;

  const _RoleAndCompanyResult(this.role, this.company);
}

class _NameExtractionResult {
  final String? name;
  final double confidence;

  const _NameExtractionResult(this.name, this.confidence);
}
