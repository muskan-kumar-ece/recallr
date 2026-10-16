import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: people.length,
          separatorBuilder: (context, index) => RecallrSpacing.gapSm,
          itemBuilder: (context, index) {
            final person = people[index];
            return RecallrCard(
              onTap: () => Navigator.of(context).pushNamed(person.targetRoute),
              child: Row(
                children: [
                  RecallrAvatar(
                    initials: person.initials,
                    size: RecallrAvatarSize.md,
                  ),
                  RecallrSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          person.name,
                          style: RecallrTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1.0),
                        Text(
                          '${person.role} · ${person.company}',
                          style: RecallrTypography.bodyMedium.copyWith(
                            color: RecallrColors.textSecondary,
                            fontSize: 12.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (person.relationshipContext.isNotEmpty) ...[
                          const SizedBox(height: 2.0),
                          Text(
                            person.relationshipContext,
                            style: RecallrTypography.labelSmall.copyWith(
                              color: RecallrColors.aiCyanHighlight,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18.0,
                    color: RecallrColors.textTertiary,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}