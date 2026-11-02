import 'package:flutter/material.dart';
import '../models/visiting_card.dart';

class VisitingCardPreview extends StatelessWidget {
  final VisitingCard card;
  const VisitingCardPreview({super.key, required this.card});
  @override
  Widget build(BuildContext context) {
    final fields = card.publicFields;
    final theme = Theme.of(context);
    final centered = card.layout == 'centered';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: card.color.withValues(alpha: .5)),
          boxShadow: [
            BoxShadow(
                color: card.color.withValues(alpha: .08),
                blurRadius: 28,
                offset: const Offset(0, 8))
          ]),
      child: Column(
          crossAxisAlignment:
              centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            CircleAvatar(
                radius: 36,
                backgroundColor: card.color.withValues(alpha: .15),
                child: fields['photoUrl']?.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(fields['photoUrl']!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, size: 36)))
                    : Icon(Icons.person_outline, color: card.color, size: 36)),
            const SizedBox(height: 20),
            Text(card.name.isEmpty ? 'Your name' : card.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: centered ? TextAlign.center : TextAlign.start),
            const SizedBox(height: 6),
            Text(
                [fields['role'], fields['company']]
                    .whereType<String>()
                    .where((v) => v.isNotEmpty)
                    .join(' · '),
                style:
                    theme.textTheme.titleMedium?.copyWith(color: card.color)),
            for (final key in [
              'bio',
              'services',
              'location',
              'email',
              'phone',
              'website',
              'linkedin'
            ])
              if (fields[key]?.isNotEmpty == true)
                Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SelectableText(fields[key]!,
                        textAlign:
                            centered ? TextAlign.center : TextAlign.start,
                        style: theme.textTheme.bodyMedium)),
            const SizedBox(height: 24),
            Text('RECALLR · DIGITAL VISITING CARD',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: card.color, letterSpacing: 1.2)),
          ]),
    );
  }
}
