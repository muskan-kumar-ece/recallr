import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/capture_models.dart';

/// Recent capture history stream list.
class CaptureRecentList extends StatelessWidget {
  final List<CaptureItem> items;
  final ValueChanged<CaptureItem> onTapItem;

  const CaptureRecentList({
    super.key,
    required this.items,
    required this.onTapItem,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'R';
  }

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
              width: 6.0,
              height: 6.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: RecallrColors.aiElectricViolet,
              ),
            ),
            RecallrSpacing.gapSm,
            Text(
              'RECENT CAPTURES',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textSecondary,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                fontSize: 11.0,
              ),
            ),
            RecallrSpacing.gapXs,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
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
              child: Divider(color: RecallrColors.borderSubtle, height: 1.0),
            ),
          ],
        ),
        RecallrSpacing.gapMd,

        // Recent Capture Items
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => RecallrSpacing.gapSm,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              decoration: BoxDecoration(
                color: RecallrColors.charcoalCard,
                borderRadius: RecallrRadii.radiusMd,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: RecallrRadii.radiusMd,
                child: InkWell(
                  borderRadius: RecallrRadii.radiusMd,
                  onTap: () => onTapItem(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                    child: Row(
                      children: [
                        if (item.personName != null)
                          RecallrAvatar(
                            initials: _getInitials(item.personName!),
                            size: RecallrAvatarSize.sm,
                          )
                        else
                          Container(
                            width: 28.0,
                            height: 28.0,
                            decoration: BoxDecoration(
                              color: item.type.color.withAlpha(30),
                              borderRadius: RecallrRadii.radiusSm,
                            ),
                            child: Icon(item.type.icon, size: 15.0, color: item.type.color),
                          ),
                        RecallrSpacing.gapSm,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.type.label,
                                    style: RecallrTypography.labelSmall.copyWith(
                                      color: item.type.color,
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                  Expanded(
                                    child: Text(
                                      '· ${item.timestamp}',
                                      style: RecallrTypography.monoMetadata.copyWith(
                                        color: RecallrColors.textTertiary,
                                        fontSize: 10.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                item.title,
                                style: RecallrTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.personName != null)
                                Text(
                                  '${item.personName!}${item.companyName != null ? ' · ${item.companyName!}' : ''}',
                                  style: RecallrTypography.bodyMedium.copyWith(
                                    color: RecallrColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11.0,
                          color: RecallrColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}