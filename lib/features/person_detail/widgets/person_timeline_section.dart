import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/person_profile_model.dart';

/// Interaction Timeline section showing chronological stream of meetings and captures.
class PersonTimelineSection extends StatelessWidget {
  final List<TimelineItem> items;

  const PersonTimelineSection({super.key, required this.items});

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
                    Icons.history_edu_rounded,
                    size: 16.0,
                    color: RecallrColors.aiElectricViolet,
                  ),
                  RecallrSpacing.gapXs,
                  Flexible(
                    child: Text(
                      'Interaction Timeline',
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
              '${items.length} records',
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
            final item = items[index];
            return RecallrCard(
              onTap: item.targetRoute != null
                  ? () => Navigator.of(context).pushNamed(item.targetRoute!)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: RecallrColors.slateSurface,
                          borderRadius: RecallrRadii.radiusSm,
                          border: Border.all(
                            color: RecallrColors.borderSubtle,
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          item.type.icon,
                          size: 15.0,
                          color: RecallrColors.aiCyanHighlight,
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
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: RecallrTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                RecallrSpacing.gapSm,
                                Text(
                                  item.date,
                                  style: RecallrTypography.monoMetadata.copyWith(
                                    color: RecallrColors.textTertiary,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1.0),
                            Text(
                              item.subtitle,
                              style: RecallrTypography.bodyMedium.copyWith(
                                color: RecallrColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item.locationOrEvent != null) ...[
                    RecallrSpacing.gapXs,
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 12.0,
                          color: RecallrColors.textTertiary,
                        ),
                        const SizedBox(width: 3.0),
                        Expanded(
                          child: Text(
                            item.locationOrEvent!,
                            style: RecallrTypography.bodyMedium.copyWith(
                              color: RecallrColors.textTertiary,
                              fontSize: 11.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  RecallrSpacing.gapSm,
                  Text(
                    item.summary,
                    style: RecallrTypography.bodyMedium.copyWith(
                      color: RecallrColors.textPrimary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  if (item.keyBullets.isNotEmpty) ...[
                    RecallrSpacing.gapSm,
                    ...item.keyBullets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5.0, right: 6.0),
                              child: Icon(
                                Icons.arrow_right_rounded,
                                size: 14.0,
                                color: RecallrColors.aiCyanHighlight,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                b,
                                style: RecallrTypography.bodyMedium.copyWith(
                                  color: RecallrColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}