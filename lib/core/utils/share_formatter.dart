import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/people/models/person_item.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/ask/models/ask_models.dart';

/// Centralized utility for formatting Recallr entities into clean,
/// shareable text and industry-standard vCard 3.0 representations.
class ShareFormatter {
  ShareFormatter._();

  /// Formats a person dossier into a human-readable markdown text summary
  /// ideal for sharing via messaging apps, email, or pasting into notes.
  static String formatPersonSummary(PersonProfile profile) {
    final buffer = StringBuffer();
    buffer.writeln('👤 *${profile.name}*');

    final subtitleParts = <String>[];
    if (profile.role.isNotEmpty) subtitleParts.add(profile.role);
    if (profile.company.isNotEmpty) subtitleParts.add(profile.company);
    if (subtitleParts.isNotEmpty) {
      buffer.writeln('💼 ${subtitleParts.join(' · ')}');
    }

    if (profile.location.isNotEmpty) {
      buffer.writeln('📍 ${profile.location}');
    }

    if (profile.email != null && profile.email!.isNotEmpty) {
      buffer.writeln('✉️ ${profile.email}');
    }
    if (profile.phone != null && profile.phone!.isNotEmpty) {
      buffer.writeln('📞 ${profile.phone}');
    }

    if (profile.brands.isNotEmpty) {
      buffer.writeln('🏷️ Brands / Tags: ${profile.brands.join(', ')}');
    }

    if (profile.aiSummary.isNotEmpty) {
      buffer.writeln('\n🧠 *Context & Summary:*');
      buffer.writeln(profile.aiSummary);
    }

    if (profile.keyTakeaways.isNotEmpty) {
      buffer.writeln('\n📌 *Key Takeaways:*');
      for (final takeaway in profile.keyTakeaways) {
        buffer.writeln('• $takeaway');
      }
    }

    if (profile.lastInteraction.isNotEmpty && profile.lastInteraction != 'Never') {
      buffer.writeln('\n⏱️ *Last Interaction:* ${profile.lastInteraction}');
    }

    buffer.writeln('\n_Shared via Recallr_');
    return buffer.toString().trim();
  }

  /// Formats a lightweight PersonItem into a clean markdown contact card.
  static String formatPersonItemSummary(PersonItem item) {
    final buffer = StringBuffer();
    buffer.writeln('👤 *${item.name}*');

    final subtitleParts = <String>[];
    if (item.role.isNotEmpty) subtitleParts.add(item.role);
    if (item.company.isNotEmpty) subtitleParts.add(item.company);
    if (subtitleParts.isNotEmpty) {
      buffer.writeln('💼 ${subtitleParts.join(' · ')}');
    }

    if (item.locationOrEvent != null && item.locationOrEvent!.isNotEmpty) {
      buffer.writeln('📍 ${item.locationOrEvent!}');
    }
    if (item.email != null && item.email!.isNotEmpty) {
      buffer.writeln('✉️ ${item.email}');
    }
    if (item.phone != null && item.phone!.isNotEmpty) {
      buffer.writeln('📞 ${item.phone}');
    }

    if (item.brands.isNotEmpty) {
      buffer.writeln('🏷️ Brands: ${item.brands.join(', ')}');
    }

    buffer.writeln('\n_Shared via Recallr_');
    return buffer.toString().trim();
  }

  /// Exports a contact profile to standard vCard 3.0 (.vcf) format.
  /// Compliant with RFC 2426 for Apple Contacts, Google Contacts, and Outlook.
  /// Exports a PersonItem to standard vCard 3.0 (.vcf) format.
  static String personItemToVCard(PersonItem item) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');

    final nameTokens = item.name.trim().split(RegExp(r'\s+'));
    final family = nameTokens.length > 1 ? nameTokens.last : '';
    final given = nameTokens.length > 1
        ? nameTokens.sublist(0, nameTokens.length - 1).join(' ')
        : item.name;

    buffer.writeln('N:$family;$given;;;');
    buffer.writeln('FN:${item.name}');

    if (item.company.isNotEmpty) {
      buffer.writeln('ORG:${_escapeVCard(item.company)}');
    }
    if (item.role.isNotEmpty) {
      buffer.writeln('TITLE:${_escapeVCard(item.role)}');
    }
    if (item.email != null && item.email!.isNotEmpty) {
      buffer.writeln('EMAIL;TYPE=INTERNET:${item.email}');
    }
    if (item.phone != null && item.phone!.isNotEmpty) {
      buffer.writeln('TEL;TYPE=CELL:${item.phone}');
    }
    if (item.locationOrEvent != null && item.locationOrEvent!.isNotEmpty) {
      buffer.writeln('ADR;TYPE=WORK:;;${_escapeVCard(item.locationOrEvent!)};;;;');
    }
    if (item.contextSnippet != null && item.contextSnippet!.isNotEmpty) {
      buffer.writeln('NOTE:${_escapeVCard(item.contextSnippet!)}');
    }

    buffer.writeln('END:VCARD');
    return buffer.toString().trim();
  }

  static String toVCard(PersonProfile profile) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');

    // Split name into Given and Family names if possible
    final nameTokens = profile.name.trim().split(RegExp(r'\s+'));
    final family = nameTokens.length > 1 ? nameTokens.last : '';
    final given = nameTokens.length > 1
        ? nameTokens.sublist(0, nameTokens.length - 1).join(' ')
        : profile.name;

    buffer.writeln('N:$family;$given;;;');
    buffer.writeln('FN:${profile.name}');

    if (profile.company.isNotEmpty) {
      buffer.writeln('ORG:${_escapeVCard(profile.company)}');
    }
    if (profile.role.isNotEmpty) {
      buffer.writeln('TITLE:${_escapeVCard(profile.role)}');
    }
    if (profile.email != null && profile.email!.isNotEmpty) {
      buffer.writeln('EMAIL;TYPE=INTERNET:${profile.email}');
    }
    if (profile.phone != null && profile.phone!.isNotEmpty) {
      buffer.writeln('TEL;TYPE=CELL:${profile.phone}');
    }
    if (profile.location.isNotEmpty) {
      buffer.writeln('ADR;TYPE=WORK:;;${_escapeVCard(profile.location)};;;;');
    }
    if (profile.aiSummary.isNotEmpty) {
      buffer.writeln('NOTE:${_escapeVCard(profile.aiSummary)}');
    }

    buffer.writeln('END:VCARD');
    return buffer.toString().trim();
  }

  /// Formats an activity or meeting encounter into a clean notes summary.
  static String formatActivityNote(ActivityItem activity) {
    final buffer = StringBuffer();
    buffer.writeln('📝 *${activity.title}*');
    if (activity.personName != null && activity.personName!.isNotEmpty) {
      final roleCompany = [
        if (activity.personRole != null && activity.personRole!.isNotEmpty) activity.personRole!,
        if (activity.companyName != null && activity.companyName!.isNotEmpty) activity.companyName!,
      ].join(' · ');
      buffer.writeln('👤 Contact: ${activity.personName}${roleCompany.isNotEmpty ? ' ($roleCompany)' : ''}');
    }
    if (activity.location != null && activity.location!.isNotEmpty) {
      buffer.writeln('📍 Location: ${activity.location!}');
    }
    buffer.writeln('📅 ${activity.timestamp}');

    if (activity.summary.isNotEmpty) {
      buffer.writeln('\n${activity.summary}');
    }

    if (activity.relationshipIndicator != null && activity.relationshipIndicator!.isNotEmpty) {
      buffer.writeln('\n🔗 Relationship: ${activity.relationshipIndicator!}');
    }

    buffer.writeln('\n_Shared via Recallr_');
    return buffer.toString().trim();
  }

  /// Formats a follow-up commitment into clean reminder text.
  static String formatFollowUp(FollowUpItem followUp) {
    final buffer = StringBuffer();
    final typeLabel = followUp.commitmentType == CommitmentType.iPromised
        ? 'I Promised'
        : 'They Promised';

    buffer.writeln('📌 *$typeLabel: ${followUp.title}*');
    buffer.writeln('👤 With: ${followUp.personName}');
    buffer.writeln('📅 Due: ${followUp.dueDate}');
    if (followUp.isCompleted) {
      buffer.writeln('✅ Status: Completed');
    }

    buffer.writeln('\n_Shared via Recallr_');
    return buffer.toString().trim();
  }

  /// Formats an Ask AI grounded answer and its cited evidence for sharing.
  static String formatAiAnswer({
    required String query,
    required String answer,
    List<MemorySource>? sources,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('💬 *Query:* "$query"');
    buffer.writeln('\n🧠 *Recallr Answer:*');
    buffer.writeln(answer);

    if (sources != null && sources.isNotEmpty) {
      buffer.writeln('\n📚 *Sources & Evidence:*');
      for (final s in sources) {
        final context = s.personName.isNotEmpty ? ' (${s.personName} · ${s.company})' : '';
        final excerpt = s.excerpt.isNotEmpty ? ': "${s.excerpt}"' : '';
        buffer.writeln('• [${s.sourceType}]$context$excerpt');
      }
    }

    buffer.writeln('\n_Generated by Recallr AI Memory_');
    return buffer.toString().trim();
  }

  static String _escapeVCard(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }
}
