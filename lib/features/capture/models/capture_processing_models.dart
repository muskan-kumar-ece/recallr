import 'package:cloud_firestore/cloud_firestore.dart';

/// Processing status lifecycle for an ingested capture item.
enum CaptureProcessingStatus {
  pending,
  processing,
  completed,
  failed;

  static CaptureProcessingStatus fromString(String? val) {
    if (val == null) return CaptureProcessingStatus.pending;
    return CaptureProcessingStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => CaptureProcessingStatus.pending,
    );
  }
}

/// Canonical result model representing structured extraction and intelligence
/// derived from an ingested capture (image, audio, document, or note).
class CaptureProcessingResult {
  final String captureId;
  final CaptureProcessingStatus status;
  final DateTime? processedAt;
  final String? title;
  final String? summary;
  final String? extractedText;
  final List<String>? detectedPeople;
  final String? detectedCompany;
  final String? detectedLocation;
  final String? detectedDate;
  final double? confidence;
  final Map<String, dynamic>? metadata;
  final String? errorMessage;

  const CaptureProcessingResult({
    required this.captureId,
    required this.status,
    this.processedAt,
    this.title,
    this.summary,
    this.extractedText,
    this.detectedPeople,
    this.detectedCompany,
    this.detectedLocation,
    this.detectedDate,
    this.confidence,
    this.metadata,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'captureId': captureId,
      'status': status.name,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'title': title,
      'summary': summary,
      'extractedText': extractedText,
      'detectedPeople': detectedPeople,
      'detectedCompany': detectedCompany,
      'detectedLocation': detectedLocation,
      'detectedDate': detectedDate,
      'confidence': confidence,
      'metadata': metadata,
      'errorMessage': errorMessage,
    };
  }

  factory CaptureProcessingResult.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    List<String>? parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return null;
    }

    return CaptureProcessingResult(
      captureId: docId ?? map['captureId']?.toString() ?? '',
      status: CaptureProcessingStatus.fromString(map['status']?.toString()),
      processedAt: parseDate(map['processedAt']),
      title: map['title']?.toString(),
      summary: map['summary']?.toString(),
      extractedText: map['extractedText']?.toString(),
      detectedPeople: parseStringList(map['detectedPeople']),
      detectedCompany: map['detectedCompany']?.toString(),
      detectedLocation: map['detectedLocation']?.toString(),
      detectedDate: map['detectedDate']?.toString(),
      confidence: parseDouble(map['confidence']),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  factory CaptureProcessingResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CaptureProcessingResult.fromMap(data, doc.id);
  }

  CaptureProcessingResult copyWith({
    String? captureId,
    CaptureProcessingStatus? status,
    DateTime? processedAt,
    String? title,
    String? summary,
    String? extractedText,
    List<String>? detectedPeople,
    String? detectedCompany,
    String? detectedLocation,
    String? detectedDate,
    double? confidence,
    Map<String, dynamic>? metadata,
    String? errorMessage,
  }) {
    return CaptureProcessingResult(
      captureId: captureId ?? this.captureId,
      status: status ?? this.status,
      processedAt: processedAt ?? this.processedAt,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      extractedText: extractedText ?? this.extractedText,
      detectedPeople: detectedPeople ?? this.detectedPeople,
      detectedCompany: detectedCompany ?? this.detectedCompany,
      detectedLocation: detectedLocation ?? this.detectedLocation,
      detectedDate: detectedDate ?? this.detectedDate,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'CaptureProcessingResult(captureId: $captureId, status: ${status.name}, confidence: $confidence)';
}