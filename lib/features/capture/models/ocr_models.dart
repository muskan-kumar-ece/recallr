/// Represents a single recognized line of text in an OCR scan.
class OcrTextLine {
  final String text;
  final double? confidence;

  const OcrTextLine({
    required this.text,
    this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'confidence': confidence,
    };
  }

  factory OcrTextLine.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return OcrTextLine(
      text: map['text']?.toString() ?? '',
      confidence: parseDouble(map['confidence']),
    );
  }

  OcrTextLine copyWith({
    String? text,
    double? confidence,
  }) {
    return OcrTextLine(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() => 'OcrTextLine(text: $text, confidence: $confidence)';
}

/// Represents a bounding-box block of recognized text in an OCR scan.
class OcrTextBlock {
  final String text;
  final double? confidence;
  final Map<String, double>? boundingBox;
  final List<OcrTextLine> lines;

  const OcrTextBlock({
    required this.text,
    this.confidence,
    this.boundingBox,
    this.lines = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'confidence': confidence,
      'boundingBox': boundingBox,
      'lines': lines.map((l) => l.toMap()).toList(),
    };
  }

  factory OcrTextBlock.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    Map<String, double>? parseBox(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), (v is num) ? v.toDouble() : 0.0));
      }
      return null;
    }

    final rawLines = map['lines'] as List? ?? const [];
    final parsedLines = rawLines
        .whereType<Map>()
        .map((m) => OcrTextLine.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    return OcrTextBlock(
      text: map['text']?.toString() ?? '',
      confidence: parseDouble(map['confidence']),
      boundingBox: parseBox(map['boundingBox']),
      lines: parsedLines,
    );
  }

  OcrTextBlock copyWith({
    String? text,
    double? confidence,
    Map<String, double>? boundingBox,
    List<OcrTextLine>? lines,
  }) {
    return OcrTextBlock(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      boundingBox: boundingBox ?? this.boundingBox,
      lines: lines ?? this.lines,
    );
  }

  @override
  String toString() => 'OcrTextBlock(text: $text, lines: ${lines.length})';
}

/// Structured canonical result from an OCR extraction pass.
class OcrResult {
  final String text;
  final double? confidence;
  final String? language;
  final List<OcrTextBlock> blocks;
  final List<OcrTextLine> lines;
  final Map<String, dynamic>? metadata;

  const OcrResult({
    required this.text,
    this.confidence,
    this.language,
    this.blocks = const [],
    this.lines = const [],
    this.metadata,
  });

  static const empty = OcrResult(text: '', confidence: 0.0);

  bool get isEmpty => text.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'confidence': confidence,
      'language': language,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'lines': lines.map((l) => l.toMap()).toList(),
      'metadata': metadata,
    };
  }

  factory OcrResult.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    final rawBlocks = map['blocks'] as List? ?? const [];
    final parsedBlocks = rawBlocks
        .whereType<Map>()
        .map((m) => OcrTextBlock.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    final rawLines = map['lines'] as List? ?? const [];
    final parsedLines = rawLines
        .whereType<Map>()
        .map((m) => OcrTextLine.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    return OcrResult(
      text: map['text']?.toString() ?? '',
      confidence: parseDouble(map['confidence']),
      language: map['language']?.toString(),
      blocks: parsedBlocks,
      lines: parsedLines,
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  OcrResult copyWith({
    String? text,
    double? confidence,
    String? language,
    List<OcrTextBlock>? blocks,
    List<OcrTextLine>? lines,
    Map<String, dynamic>? metadata,
  }) {
    return OcrResult(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      language: language ?? this.language,
      blocks: blocks ?? this.blocks,
      lines: lines ?? this.lines,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'OcrResult(length: ${text.length}, confidence: $confidence)';
}

/// Structured entities extracted deterministically from OCR text.
class OcrExtractedEntities {
  final String? name;
  final String? role;
  final String? company;
  final String? email;
  final String? phone;
  final String? website;
  final String? location;
  final String? date;
  final List<String> keyPoints;

  // Strict structured business card attributes
  final String? designation;
  final String? address;
  final List<String> brands;
  final List<String> phones;
  final List<String> emails;
  final Map<String, double> confidence;

  const OcrExtractedEntities({
    this.name,
    this.role,
    this.company,
    this.email,
    this.phone,
    this.website,
    this.location,
    this.date,
    this.keyPoints = const [],
    this.designation,
    this.address,
    this.brands = const [],
    this.phones = const [],
    this.emails = const [],
    this.confidence = const {},
  });

  String? get effectiveRole => designation ?? role;
  String? get effectiveLocation => address ?? location;
  double get nameConfidence => confidence['name'] ?? (name != null ? 0.9 : 0.0);

  /// Strict JSON representation matching the required business card OCR contract:
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
  Map<String, dynamic> toJson() {
    final effectivePhones = phones.isNotEmpty
        ? phones
        : (phone != null && phone!.isNotEmpty ? [phone!] : <String>[]);
    final effectiveEmails = emails.isNotEmpty
        ? emails
        : (email != null && email!.isNotEmpty ? [email!] : <String>[]);

    return {
      'name': name,
      'designation': designation ?? role,
      'company': company,
      'brands': brands,
      'phones': effectivePhones,
      'emails': effectiveEmails,
      'website': website,
      'address': address ?? location,
      'confidence': {
        'name': confidence['name'] ?? (name != null ? 0.9 : 0.0),
      },
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'company': company,
      'email': email,
      'phone': phone,
      'website': website,
      'location': location,
      'date': date,
      'keyPoints': keyPoints,
      'designation': designation ?? role,
      'address': address ?? location,
      'brands': brands,
      'phones': phones,
      'emails': emails,
      'confidence': confidence,
    };
  }

  factory OcrExtractedEntities.fromMap(Map<String, dynamic> map) {
    Map<String, double> parseConfidence(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(
              k.toString(),
              (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0),
            ));
      }
      return const {};
    }

    final rawBrands = (map['brands'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final rawPhones = (map['phones'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final rawEmails = (map['emails'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    final singlePhone = map['phone']?.toString() ?? (rawPhones.isNotEmpty ? rawPhones.first : null);
    final singleEmail = map['email']?.toString() ?? (rawEmails.isNotEmpty ? rawEmails.first : null);
    final desig = map['designation']?.toString() ?? map['role']?.toString();
    final addr = map['address']?.toString() ?? map['location']?.toString();

    return OcrExtractedEntities(
      name: map['name']?.toString(),
      role: map['role']?.toString() ?? desig,
      company: map['company']?.toString(),
      email: singleEmail,
      phone: singlePhone,
      website: map['website']?.toString(),
      location: map['location']?.toString() ?? addr,
      date: map['date']?.toString(),
      keyPoints: (map['keyPoints'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      designation: desig,
      address: addr,
      brands: rawBrands,
      phones: rawPhones.isNotEmpty ? rawPhones : (singlePhone != null ? [singlePhone] : const []),
      emails: rawEmails.isNotEmpty ? rawEmails : (singleEmail != null ? [singleEmail] : const []),
      confidence: parseConfidence(map['confidence']),
    );
  }

  OcrExtractedEntities copyWith({
    String? name,
    String? role,
    String? company,
    String? email,
    String? phone,
    String? website,
    String? location,
    String? date,
    List<String>? keyPoints,
    String? designation,
    String? address,
    List<String>? brands,
    List<String>? phones,
    List<String>? emails,
    Map<String, double>? confidence,
  }) {
    return OcrExtractedEntities(
      name: name ?? this.name,
      role: role ?? this.role,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      location: location ?? this.location,
      date: date ?? this.date,
      keyPoints: keyPoints ?? this.keyPoints,
      designation: designation ?? this.designation,
      address: address ?? this.address,
      brands: brands ?? this.brands,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      confidence: confidence ?? this.confidence,
    );
  }
}