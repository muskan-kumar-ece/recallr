import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/person_profile_model.dart';

/// Connected Entities Section (Company, Events, Files, Mutual Contacts).
class ConnectedEntitiesSection extends StatelessWidget {
  final List<ConnectedEntity> items;

  const ConnectedEntitiesSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.account_tree_outlined,
              size: 16.0,
              color: RecallrColors.aiCyanHighlight,
            ),
            RecallrSpacing.gapXs,
            Flexible(
              child: Text(
                'Connected Network Entities',
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
          itemCount: items.length,
          separatorBuilder: (context, index) => RecallrSpacing.gapXs,
          itemBuilder: (context, index) {
            final entity = items[index];
            return RecallrCard(
              onTap: () => Navigator.of(context).pushNamed(entity.targetRoute),
              child: Row(
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
                      entity.type.icon,
                      size: 16.0,
                      color: RecallrColors.textSecondary,
                    ),
                  ),
                  RecallrSpacing.gapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entity.title,
                          style: RecallrTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          entity.subtitle,
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
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16.0,
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