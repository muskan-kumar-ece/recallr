import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import 'capture_processing_models.dart';

/// Supported multi-modal capture methods in Recallr Omni-Capture Hub.
enum CaptureType {
  businessCard,
  voice,
  note,
  photo,
  document;

  String get label {
    switch (this) {
      case CaptureType.businessCard:
        return 'Business Card';
      case CaptureType.voice:
        return 'Voice Memo';
      case CaptureType.note:
        return 'Quick Note';
      case CaptureType.photo:
        return 'Capture Photo';
      case CaptureType.document:
        return 'Add Document';
    }
  }

  String get description {
    switch (this) {
      case CaptureType.businessCard:
        return 'Scan visiting card with instant OCR extraction';
      case CaptureType.voice:
        return 'Record conversation takeaway or audio note';
      case CaptureType.note:
        return 'Type fast professional encounter notes';
      case CaptureType.photo:
        return 'Snap whiteboard, slide, or diagram';
      case CaptureType.document:
        return 'Upload PDF, spec sheet, or pitch deck';
    }
  }

  IconData get icon {
    switch (this) {
      case CaptureType.businessCard:
        return Icons.badge_outlined;
      case CaptureType.voice:
        return Icons.mic_none_rounded;
      case CaptureType.note:
        return Icons.edit_note_rounded;
      case CaptureType.photo:
        return Icons.camera_alt_outlined;
      case CaptureType.document:
        return Icons.attach_file_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CaptureType.businessCard:
        return RecallrColors.warmAmberGold;
      case CaptureType.voice:
        return RecallrColors.aiElectricViolet;
      case CaptureType.note:
        return RecallrColors.aiCyanHighlight;
      case CaptureType.photo:
        return RecallrColors.aiCyanHighlight;
      case CaptureType.document:
        return RecallrColors.warmAmberGold;
    }
  }
}

/// State machine for Omni-Capture interactive modal flows.
enum CaptureState {
  idle,
  capturing,
  recording,
  processing,
  review,
  saving,
  saved,
  error,
}

/// Review payload representing the structured memory ready to be saved.
class CaptureReviewData {
  final String title;
  final String summary;
  final String? personName;
  final String? personRole;
  final String? companyName;
  final String? eventName;
  final String? location;
  final String? date;
  final String? audioDuration;
  final List<String> bulletPoints;
  final Map<String, String> contactDetails;

  const CaptureReviewData({
    required this.title,
    required this.summary,
    this.personName,
    this.personRole,
    this.companyName,
    this.eventName,
    this.location,
    this.date,
    this.audioDuration,
    this.bulletPoints = const [],
    this.contactDetails = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'personName': personName,
      'personRole': personRole,
      'companyName': companyName,
      'eventName': eventName,
      'location': location,
      'date': date,
      'audioDuration': audioDuration,
      'bulletPoints': bulletPoints,
      'contactDetails': contactDetails,
    };
  }

  factory CaptureReviewData.fromMap(Map<String, dynamic> map) {
    return CaptureReviewData(
      title: map['title']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      personName: map['personName']?.toString(),
      personRole: map['personRole']?.toString(),
      companyName: map['companyName']?.toString(),
      eventName: map['eventName']?.toString(),
      location: map['location']?.toString(),
      date: map['date']?.toString(),
      audioDuration: map['audioDuration']?.toString(),
      bulletPoints: (map['bulletPoints'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      contactDetails: (map['contactDetails'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? const {},
    );
  }

  CaptureReviewData copyWith({
    String? title,
    String? summary,
    String? personName,
    String? personRole,
    String? companyName,
    String? eventName,
    String? location,
    String? date,
    String? audioDuration,
    List<String>? bulletPoints,
    Map<String, String>? contactDetails,
  }) {
    return CaptureReviewData(
      title: title ?? this.title,
      summary: summary ?? this.summary,
      personName: personName ?? this.personName,
      personRole: personRole ?? this.personRole,
      companyName: companyName ?? this.companyName,
      eventName: eventName ?? this.eventName,
      location: location ?? this.location,
      date: date ?? this.date,
      audioDuration: audioDuration ?? this.audioDuration,
      bulletPoints: bulletPoints ?? this.bulletPoints,
      contactDetails: contactDetails ?? this.contactDetails,
    );
  }
}

/// Domain model representing a single captured memory item.
class CaptureItem {
  final String id;
  final CaptureType type;
  final String title;
  final String description;
  final String timestamp;
  final String? personId;
  final String? personName;
  final String? personRole;
  final String? companyId;
  final String? companyName;
  final String? eventName;
  final String? location;
  final String targetRoute;
  final bool isVerified;
  final Map<String, dynamic>? metadata;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? mediaUrl;
  final String? storagePath;
  final String? mimeType;
  final int? fileSize;
  final int? durationSeconds;
  final CaptureProcessingStatus? processingStatus;
  final DateTime? processedAt;
  final String? processingError;
  final String? extractedText;
  final String? summary;
  final double? confidence;
  final String? resolvedPersonId;
  final String? entityResolutionStatus;
  final double? entityResolutionConfidence;
  final DateTime? entityResolutionAt;
  final String? entityResolutionSource;
  final String? linkedActivityId;

  /// Temporary local device file path used for on-device OCR before upload.
  /// This field is NOT persisted to Firestore. It is only set during the
  /// active capture session and cleared after upload completes.
  final String? localFilePath;

  const CaptureItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.personId,
    this.personName,
    this.personRole,
    this.companyId,
    this.companyName,
    this.eventName,
    this.location,
    required this.targetRoute,
    this.isVerified = true,
    this.metadata,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.mediaUrl,
    this.storagePath,
    this.mimeType,
    this.fileSize,
    this.durationSeconds,
    this.processingStatus,
    this.processedAt,
    this.processingError,
    this.extractedText,
    this.summary,
    this.confidence,
    this.resolvedPersonId,
    this.entityResolutionStatus,
    this.entityResolutionConfidence,
    this.entityResolutionAt,
    this.entityResolutionSource,
    this.linkedActivityId,
    this.localFilePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'personId': personId,
      'personName': personName,
      'personRole': personRole,
      'companyId': companyId,
      'companyName': companyName,
      'eventName': eventName,
      'location': location,
      'targetRoute': targetRoute,
      'isVerified': isVerified,
      'metadata': metadata,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'mediaUrl': mediaUrl,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'durationSeconds': durationSeconds,
      'processingStatus': processingStatus?.name,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'processingError': processingError,
      'extractedText': extractedText,
      'summary': summary,
      'confidence': confidence,
      'resolvedPersonId': resolvedPersonId,
      'entityResolutionStatus': entityResolutionStatus,
      'entityResolutionConfidence': entityResolutionConfidence,
      'entityResolutionAt': entityResolutionAt != null ? Timestamp.fromDate(entityResolutionAt!) : null,
      'entityResolutionSource': entityResolutionSource,
      'linkedActivityId': linkedActivityId,
    };
  }

  factory CaptureItem.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    return CaptureItem(
      id: docId ?? map['id']?.toString() ?? '',
      type: CaptureType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CaptureType.note,
      ),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      timestamp: map['timestamp']?.toString() ?? '',
      personId: map['personId']?.toString(),
      personName: map['personName']?.toString(),
      personRole: map['personRole']?.toString(),
      companyId: map['companyId']?.toString(),
      companyName: map['companyName']?.toString(),
      eventName: map['eventName']?.toString(),
      location: map['location']?.toString(),
      targetRoute: map['targetRoute']?.toString() ?? '/captures/unknown',
      isVerified: map['isVerified'] != false,
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
      userId: map['userId']?.toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      mediaUrl: map['mediaUrl']?.toString(),
      storagePath: map['storagePath']?.toString(),
      mimeType: map['mimeType']?.toString(),
      fileSize: map['fileSize'] is num ? (map['fileSize'] as num).toInt() : int.tryParse(map['fileSize']?.toString() ?? ''),
      durationSeconds: map['durationSeconds'] is num ? (map['durationSeconds'] as num).toInt() : int.tryParse(map['durationSeconds']?.toString() ?? ''),
      processingStatus: map['processingStatus'] != null ? CaptureProcessingStatus.fromString(map['processingStatus']?.toString()) : null,
      processedAt: parseDate(map['processedAt']),
      processingError: map['processingError']?.toString(),
      extractedText: map['extractedText']?.toString(),
      summary: map['summary']?.toString(),
      confidence: parseDouble(map['confidence']),
      resolvedPersonId: map['resolvedPersonId']?.toString(),
      entityResolutionStatus: map['entityResolutionStatus']?.toString(),
      entityResolutionConfidence: parseDouble(map['entityResolutionConfidence']),
      entityResolutionAt: parseDate(map['entityResolutionAt']),
      entityResolutionSource: map['entityResolutionSource']?.toString(),
      linkedActivityId: map['linkedActivityId']?.toString(),
    );
  }

  factory CaptureItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CaptureItem.fromMap(data, doc.id);
  }

  CaptureItem copyWith({
    String? id,
    CaptureType? type,
    String? title,
    String? description,
    String? timestamp,
    String? personId,
    String? personName,
    String? personRole,
    String? companyId,
    String? companyName,
    String? eventName,
    String? location,
    String? targetRoute,
    bool? isVerified,
    Map<String, dynamic>? metadata,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mediaUrl,
    String? storagePath,
    String? mimeType,
    int? fileSize,
    int? durationSeconds,
    CaptureProcessingStatus? processingStatus,
    DateTime? processedAt,
    String? processingError,
    String? extractedText,
    String? summary,
    double? confidence,
    String? resolvedPersonId,
    String? entityResolutionStatus,
    double? entityResolutionConfidence,
    DateTime? entityResolutionAt,
    String? entityResolutionSource,
    String? linkedActivityId,
    String? localFilePath,
  }) {
    return CaptureItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      personRole: personRole ?? this.personRole,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      eventName: eventName ?? this.eventName,
      location: location ?? this.location,
      targetRoute: targetRoute ?? this.targetRoute,
      isVerified: isVerified ?? this.isVerified,
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      processingStatus: processingStatus ?? this.processingStatus,
      processedAt: processedAt ?? this.processedAt,
      processingError: processingError ?? this.processingError,
      extractedText: extractedText ?? this.extractedText,
      summary: summary ?? this.summary,
      confidence: confidence ?? this.confidence,
      resolvedPersonId: resolvedPersonId ?? this.resolvedPersonId,
      entityResolutionStatus: entityResolutionStatus ?? this.entityResolutionStatus,
      entityResolutionConfidence: entityResolutionConfidence ?? this.entityResolutionConfidence,
      entityResolutionAt: entityResolutionAt ?? this.entityResolutionAt,
      entityResolutionSource: entityResolutionSource ?? this.entityResolutionSource,
      linkedActivityId: linkedActivityId ?? this.linkedActivityId,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}