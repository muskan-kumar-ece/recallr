import 'dart:convert';
import 'package:flutter/material.dart';

/// The draft and public projection share this bounded, contact-only schema.
class VisitingCard {
  final String id;
  final Map<String, String> fields;
  final Set<String> visibleFields;
  final String layout;
  final int accent;
  final bool published;
  final int version;
  final String? sourcePersonId;
  final String? publicId;

  static const labels = <String, String>{
    'name': 'Full name',
    'role': 'Role / designation',
    'company': 'Company',
    'bio': 'About you',
    'email': 'Email',
    'phone': 'Phone',
    'whatsapp': 'WhatsApp',
    'location': 'City / location',
    'website': 'Website',
    'linkedin': 'LinkedIn',
    'services': 'Skills / services',
    'photoUrl': 'Profile photo URL',
  };

  VisitingCard(
      {required this.id,
      Map<String, String> fields = const {},
      Set<String>? visibleFields,
      this.layout = 'classic',
      this.accent = 0xFF7C3AED,
      this.published = false,
      this.version = 0,
      this.sourcePersonId,
      this.publicId})
      : fields = Map.unmodifiable(fields),
        visibleFields = Set.unmodifiable(visibleFields ?? labels.keys.toSet());

  String get name => fields['name'] ?? '';
  Color get color => Color(accent);
  Map<String, String> get publicFields => {
        for (final entry in fields.entries)
          if (labels.containsKey(entry.key) &&
              (entry.key == 'name' || visibleFields.contains(entry.key)))
            entry.key: entry.value,
      };

  Map<String, dynamic> toMap() => {
        'fields': fields,
        'visibleFields': visibleFields.toList(),
        'layout': layout,
        'accent': accent,
        'published': published,
        'version': version,
        if (sourcePersonId != null) 'sourcePersonId': sourcePersonId
      };

  factory VisitingCard.fromMap(String id, Map<String, dynamic> data) =>
      VisitingCard(
        id: id,
        fields: Map<String, String>.from(data['fields'] as Map? ?? {}),
        visibleFields:
            (data['visibleFields'] as List?)?.whereType<String>().toSet(),
        layout: data['layout'] as String? ?? 'classic',
        accent: (data['accent'] as num?)?.toInt() ?? 0xFF7C3AED,
        published: data['published'] == true,
        version: (data['version'] as num?)?.toInt() ?? 0,
        sourcePersonId: data['sourcePersonId'] as String?,
        publicId: data['publicId'] as String?,
      );

  String get vCard {
    String escape(String value) => value
        .replaceAll('\\', '\\\\')
        .replaceAll('\r', '')
        .replaceAll('\n', r'\n')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,');
    final f = publicFields;
    return [
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:${escape(name)}',
      for (final entry in {
        'ORG': 'company',
        'TITLE': 'role',
        'EMAIL': 'email',
        'TEL': 'phone',
        'URL': 'website',
        'NOTE': 'bio'
      }.entries)
        if (f[entry.value]?.isNotEmpty == true)
          '${entry.key}:${escape(f[entry.value]!)}',
      'END:VCARD',
      ''
    ].join('\r\n');
  }

  String encodeDraft() => jsonEncode(toMap());
}
