import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../follow_ups/models/follow_up_models.dart';

/// Follow-ups & Active Commitments Section for Person Profile.
class PersonFollowUpsSection extends StatelessWidget {
  final List<FollowUpItem> items;

  const PersonFollowUpsSection({super.key, required this.items});

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
                    Icons.bolt_rounded,
                    size: 16.0,
                    color: RecallrColors.warmAmberGold,
                  ),
                  RecallrSpacing.gapXs,
                  Flexible(
                    child: Text(
                      'Active Commitments & Follow-ups',
                      style: RecallrTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            RecallrSpacing.gapSm,
            Text(
              '${items.length} active',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        RecallrSpacing.gapSm,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => RecallrSpacing.gapSm,
          itemBuilder: (context, index) {
            final followUp = items[index];
            final isIPromised = followUp.isIPromised;

            return RecallrCard(
              onTap: () => Navigator.of(context).pushNamed(followUp.targetRoute),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: RecallrColors.slateSurface,
                      borderRadius: RecallrRadii.radiusSm,
                      border: Border.all(
                        color: isIPromised
                            ? RecallrColors.warmAmberGold.withAlpha(80)
                            : RecallrColors.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      isIPromised ? Icons.outbox_rounded : Icons.move_to_inbox_rounded,
                      size: 16.0,
                      color: isIPromised ? RecallrColors.warmAmberGold : RecallrColors.aiCyanHighlight,
                    ),
                  ),
                  RecallrSpacing.gapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: RecallrBadge(
                                text: isIPromised ? 'I PROMISED' : 'THEY PROMISED',
                                variant: isIPromised
                                    ? RecallrBadgeVariant.pending
                                    : RecallrBadgeVariant.neutral,
                              ),
                            ),
                            RecallrSpacing.gapXs,
                            Text(
                              followUp.dueDate,
                              style: RecallrTypography.monoMetadata.copyWith(
                                color: RecallrColors.textTertiary,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        RecallrSpacing.gapXs,
                        Text(
                          followUp.title,
                          style: RecallrTypography.bodyMedium.copyWith(
                            color: RecallrColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.0,
                          ),
                        ),
                      ],
                    ),
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