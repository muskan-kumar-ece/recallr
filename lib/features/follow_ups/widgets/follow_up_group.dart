import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/follow_up_models.dart';
import 'follow_up_card.dart';

/// Group container for categorized relationship commitments.
class FollowUpGroup extends StatelessWidget {
  final String title;
  final List<FollowUpItem> items;
  final String? selectedFollowUpId;
  final ValueChanged<FollowUpItem>? onTapFollowUp;
  final ValueChanged<String>? onTapPerson;
  final ValueChanged<FollowUpItem>? onTapSource;
  final ValueChanged<FollowUpItem>? onToggleComplete;
  final ValueChanged<FollowUpItem>? onShareFollowUp;
  final ValueChanged<FollowUpItem>? onDeleteFollowUp;

  const FollowUpGroup({
    super.key,
    required this.title,
    required this.items,
    this.selectedFollowUpId,
    this.onTapFollowUp,
    this.onTapPerson,
    this.onTapSource,
    this.onToggleComplete,
    this.onShareFollowUp,
    this.onDeleteFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              width: 7.0,
              height: 7.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: RecallrColors.aiElectricViolet,
              ),
            ),
            RecallrSpacing.gapSm,
            Text(
              title.toUpperCase(),
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            RecallrSpacing.gapXs,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
              decoration: BoxDecoration(
                color: RecallrColors.slateSurface,
                borderRadius: RecallrRadii.radiusSm,
              ),
              child: Text(
                '${items.length}',
                style: RecallrTypography.monoMetadata.copyWith(
                  fontSize: 10.0,
                  color: RecallrColors.textTertiary,
                ),
              ),
            ),
            RecallrSpacing.gapSm,
            const Expanded(
              child: Divider(
                color: RecallrColors.borderSubtle,
                height: 1.0,
              ),
            ),
          ],
        ),
        RecallrSpacing.gapMd,

        // Items List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => RecallrSpacing.gapSm,
          itemBuilder: (context, index) {
            final item = items[index];
            return FollowUpCard(
              item: item,
              isSelected: item.id == selectedFollowUpId,
              onTap: () {
                if (onTapFollowUp != null) {
                  onTapFollowUp!(item);
                } else if (item.targetRoute != '/follow-ups' &&
                    item.targetRoute != '/follow-up' &&
                    !item.targetRoute.startsWith('/follow-up/')) {
                  Navigator.of(context).pushNamed(item.targetRoute);
                }
              },
              onTapPerson: item.personId != null
                  ? () {
                      if (onTapPerson != null) {
                        onTapPerson!(item.personId!);
                      } else {
                        Navigator.of(context).pushNamed('/person/${item.personId}');
                      }
                    }
                  : null,
              onTapSource: () {
                if (onTapSource != null) {
                  onTapSource!(item);
                } else if (item.sourceInteractionId != null) {
                  Navigator.of(context).pushNamed('/interaction/${item.sourceInteractionId}');
                } else if (item.targetRoute != '/follow-ups' &&
                    item.targetRoute != '/follow-up' &&
                    !item.targetRoute.startsWith('/follow-up/')) {
                  Navigator.of(context).pushNamed(item.targetRoute);
                }
              },
              onToggleComplete: () {
                if (onToggleComplete != null) {
                  onToggleComplete!(item);
                }
              },
              onShare: onShareFollowUp != null ? () => onShareFollowUp!(item) : null,
              onDelete: onDeleteFollowUp != null ? () => onDeleteFollowUp!(item) : null,
            );
          },
        ),
      ],
    );
  }
}