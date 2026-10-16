import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/follow_up_models.dart';

/// Single memory-backed relationship commitment card for Recallr Phase 10.
class FollowUpCard extends StatelessWidget {
  final FollowUpItem item;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onTapPerson;
  final VoidCallback? onTapSource;
  final VoidCallback? onToggleComplete;

  const FollowUpCard({
    super.key,
    required this.item,
    this.isSelected = false,
    this.onTap,
    this.onTapPerson,
    this.onTapSource,
    this.onToggleComplete,
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
    final bool isCompleted = item.isCompleted || item.status == FollowUpStatus.completed;

    return Container(
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(
          color: isSelected
              ? RecallrColors.aiElectricViolet
              : isCompleted
                  ? RecallrColors.emeraldVerified.withAlpha(80)
                  : RecallrColors.borderSubtle,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: RecallrRadii.radiusLg,
        child: InkWell(
          borderRadius: RecallrRadii.radiusLg,
          onTap: onTap,
          child: Padding(
            padding: RecallrSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row: Commitment Badge + Due Date + Verification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: RecallrSpacing.xs,
                        runSpacing: 4.0,
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle_rounded : item.commitmentType.icon,
                            size: 15.0,
                            color: isCompleted ? RecallrColors.emeraldVerified : item.commitmentType.color,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: (isCompleted ? RecallrColors.emeraldVerified : item.commitmentType.color).withAlpha(30),
                              borderRadius: RecallrRadii.radiusSm,
                              border: Border.all(
                                color: (isCompleted ? RecallrColors.emeraldVerified : item.commitmentType.color).withAlpha(90),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              isCompleted ? 'COMPLETED' : item.commitmentType.badgeText,
                              style: RecallrTypography.labelSmall.copyWith(
                                color: isCompleted ? RecallrColors.emeraldVerified : item.commitmentType.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                          if (!isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: RecallrColors.slateSurface,
                                borderRadius: RecallrRadii.radiusSm,
                              ),
                              child: Text(
                                item.dueDate,
                                style: RecallrTypography.monoMetadata.copyWith(
                                  color: item.status == FollowUpStatus.overdue
                                      ? RecallrColors.crimsonAlert
                                      : RecallrColors.textSecondary,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    RecallrSpacing.gapXs,
                    if (item.isVerified)
                      const Icon(
                        Icons.verified_rounded,
                        size: 14.0,
                        color: RecallrColors.emeraldVerified,
                      ),
                  ],
                ),
                RecallrSpacing.gapSm,

                // Person / Entity Row (Tappable)
                if (item.personName != null) ...[
                  GestureDetector(
                    onTap: onTapPerson,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        RecallrAvatar(
                          initials: _getInitials(item.personName!),
                          size: RecallrAvatarSize.sm,
                        ),
                        RecallrSpacing.gapXs,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.personName!,
                                style: RecallrTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: RecallrColors.aiCyanHighlight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.personRole != null && item.companyName != null)
                                Text(
                                  '${item.personRole!} · ${item.companyName!}',
                                  style: RecallrTypography.bodyMedium.copyWith(
                                    color: RecallrColors.textTertiary,
                                    fontSize: 11.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else if (item.companyName != null)
                                Text(
                                  item.companyName!,
                                  style: RecallrTypography.bodyMedium.copyWith(
                                    color: RecallrColors.textTertiary,
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
                  ),
                  RecallrSpacing.gapSm,
                ],

                // Title
                Text(
                  item.title,
                  style: RecallrTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.0,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? RecallrColors.textTertiary : RecallrColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),

                // Context
                Text(
                  item.context,
                  style: RecallrTypography.bodyMedium.copyWith(
                    color: RecallrColors.textSecondary,
                    fontSize: 13.0,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                RecallrSpacing.gapSm,

                // Source Memory Provenance Tag
                if (item.sourceMemoryTitle != null) ...[
                  GestureDetector(
                    onTap: onTapSource,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: RecallrColors.slateSurface,
                        borderRadius: RecallrRadii.radiusSm,
                        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_stories_outlined,
                            size: 11.0,
                            color: RecallrColors.aiElectricViolet,
                          ),
                          const SizedBox(width: 4.0),
                          Flexible(
                            child: Text(
                              'From: ${item.sourceMemoryTitle!}${item.sourceMemoryDate != null ? ' · ${item.sourceMemoryDate!}' : ''}',
                              style: RecallrTypography.monoMetadata.copyWith(
                                color: RecallrColors.textTertiary,
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  RecallrSpacing.gapMd,
                ],

                // Action Footer
                Wrap(
                  spacing: RecallrSpacing.sm,
                  runSpacing: RecallrSpacing.xs,
                  children: [
                    // Complete Toggle Button
                    RecallrButton(
                      label: isCompleted ? 'Completed' : 'Complete',
                      variant: isCompleted ? RecallrButtonVariant.secondary : RecallrButtonVariant.primary,
                      leadingIcon: isCompleted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                      onPressed: onToggleComplete,
                    ),

                    // Secondary Action: Open Memory
                    if (item.sourceInteractionId != null || item.targetRoute.isNotEmpty)
                      RecallrButton(
                        label: 'Open Memory',
                        variant: RecallrButtonVariant.secondary,
                        leadingIcon: Icons.visibility_outlined,
                        onPressed: onTapSource ?? onTap,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}