import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/person_item.dart';

/// Recently Interacted horizontal section in People Directory.
class RecentlyInteractedSection extends StatelessWidget {
  final List<PersonItem> items;

  const RecentlyInteractedSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 18.0,
                    color: RecallrColors.aiElectricViolet,
                  ),
                  RecallrSpacing.gapXs,
                  Flexible(
                    child: Text(
                      'Recently Interacted',
                      style: RecallrTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            RecallrSpacing.gapSm,
            Text(
              '${items.length} recent',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        RecallrSpacing.gapSm,
        SizedBox(
          height: 140.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => RecallrSpacing.gapSm,
            itemBuilder: (context, index) {
              final person = items[index];
              return SizedBox(
                width: 220.0,
                child: RecallrCard(
                  onTap: () => Navigator.of(context).pushNamed(person.targetRoute),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          RecallrAvatar(
                            initials: person.initials,
                            size: RecallrAvatarSize.sm,
                          ),
                          RecallrSpacing.gapSm,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  person.name,
                                  style: RecallrTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1.0),
                                Text(
                                  '${person.role} · ${person.company}',
                                  style: RecallrTypography.bodyMedium.copyWith(
                                    color: RecallrColors.textSecondary,
                                    fontSize: 11.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (person.capabilities.isNotEmpty) ...[
                        RecallrSpacing.gapXs,
                        RecallrBadge(
                          text: person.capabilities.first,
                          variant: RecallrBadgeVariant.neutral,
                        ),
                      ],
                      if (person.lastInteraction != null)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            person.lastInteraction!,
                            style: RecallrTypography.monoMetadata.copyWith(
                              color: RecallrColors.textTertiary,
                              fontSize: 10.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}