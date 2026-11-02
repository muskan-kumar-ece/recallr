import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/ask_models.dart';

/// People mentions section showing contextual relevance and routing to /person/:id.
class PeopleMentions extends StatelessWidget {
  final List<PersonReference> people;

  const PeopleMentions({super.key, required this.people});

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 16.0,
              color: RecallrColors.aiCyanHighlight,
            ),
            RecallrSpacing.gapXs,
            Expanded(
              child: Text(
                'Referenced People',
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        RecallrSpacing.gapSm,
        Wrap(
          spacing: RecallrSpacing.xs,
          runSpacing: RecallrSpacing.xs,
          children: people.map((person) {
            final contextLabel = [person.role, person.company]
                .where((value) => value.trim().isNotEmpty)
                .join(' · ');
            return ActionChip(
              avatar: CircleAvatar(
                radius: 10,
                child:
                    Text(person.initials, style: const TextStyle(fontSize: 9)),
              ),
              label: Text(person.name),
              tooltip: contextLabel.isEmpty ? person.name : contextLabel,
              onPressed: () =>
                  Navigator.of(context).pushNamed(person.targetRoute),
            );
          }).toList(),
        ),
      ],
    );
  }
}
