import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/activity_models.dart';

/// Single chronological activity card for Recallr Phase 09.
class ActivityCard extends StatelessWidget {
  final ActivityItem activity;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onTapPerson;
  final VoidCallback? onTapAction;

  const ActivityCard({
    super.key,
    required this.activity,
    this.isSelected = false,
    this.onTap,
    this.onTapPerson,
    this.onTapAction,
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
    return Container(
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(
          color: isSelected
              ? RecallrColors.aiElectricViolet
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
                // Top Row: Badges (Wrap) + Timestamp
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
                            activity.type.icon,
                            size: 15.0,
                            color: _getActivityColor(),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: _getActivityColor().withAlpha(30),
                              borderRadius: RecallrRadii.radiusSm,
                              border: Border.all(
                                color: _getActivityColor().withAlpha(90),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              activity.type.badgeText,
                              style: RecallrTypography.labelSmall.copyWith(
                                color: _getActivityColor(),
                                fontWeight: FontWeight.w700,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                          if (activity.followUpStatus != null)
                            RecallrBadge(
                              text: activity.followUpStatus!.toUpperCase(),
                              variant: activity.followUpStatus!.toLowerCase().contains('overdue')
                                  ? RecallrBadgeVariant.warning
                                  : RecallrBadgeVariant.pending,
                            ),
                        ],
                      ),
                    ),
                    RecallrSpacing.gapXs,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (activity.isVerified) ...[
                          const Icon(
                            Icons.verified_rounded,
                            size: 13.0,
                            color: RecallrColors.emeraldVerified,
                          ),
                          const SizedBox(width: 4.0),
                        ],
                        Text(
                          activity.timestamp,
                          style: RecallrTypography.monoMetadata.copyWith(
                            color: RecallrColors.textTertiary,
                            fontSize: 11.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                RecallrSpacing.gapSm,

                // Person / Company Row (Tappable)
                if (activity.personName != null) ...[
                  GestureDetector(
                    onTap: onTapPerson,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        RecallrAvatar(
                          initials: _getInitials(activity.personName!),
                          size: RecallrAvatarSize.sm,
                        ),
                        RecallrSpacing.gapXs,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.personName!,
                                style: RecallrTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: RecallrColors.aiCyanHighlight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (activity.companyName != null)
                                Text(
                                  activity.companyName!,
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
                  activity.title,
                  style: RecallrTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),

                // Context Summary
                Text(
                  activity.summary,
                  style: RecallrTypography.bodyMedium.copyWith(
                    color: RecallrColors.textSecondary,
                    fontSize: 13.0,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                RecallrSpacing.gapSm,

                // Location & Relationship Context Chips
                Wrap(
                  spacing: RecallrSpacing.xs,
                  runSpacing: 4.0,
                  children: [
                    if (activity.location != null)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 240.0),
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: RecallrColors.slateSurface,
                          borderRadius: RecallrRadii.radiusSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 11.0,
                              color: RecallrColors.textTertiary,
                            ),
                            const SizedBox(width: 3.0),
                            Flexible(
                              child: Text(
                                activity.location!,
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
                    if (activity.relationshipIndicator != null)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 240.0),
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: RecallrColors.slateSurface,
                          borderRadius: RecallrRadii.radiusSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.hub_outlined,
                              size: 11.0,
                              color: RecallrColors.aiCyanHighlight,
                            ),
                            const SizedBox(width: 3.0),
                            Flexible(
                              child: Text(
                                activity.relationshipIndicator!,
                                style: RecallrTypography.monoMetadata.copyWith(
                                  color: RecallrColors.aiCyanHighlight,
                                  fontSize: 10.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                RecallrSpacing.gapMd,

                // Action Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RecallrButton(
                      label: activity.actionLabel,
                      variant: RecallrButtonVariant.secondary,
                      leadingIcon: _getActionIcon(),
                      onPressed: onTapAction ?? onTap,
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

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.meeting:
        return RecallrColors.aiElectricViolet;
      case ActivityType.encounter:
        return RecallrColors.aiCyanHighlight;
      case ActivityType.call:
        return RecallrColors.aiCyanHighlight;
      case ActivityType.note:
        return RecallrColors.textSecondary;
      case ActivityType.capture:
        return RecallrColors.warmAmberGold;
      case ActivityType.file:
        return RecallrColors.aiCyanHighlight;
      case ActivityType.followUp:
        return RecallrColors.warmAmberGold;
      case ActivityType.companyUpdate:
        return RecallrColors.aiElectricViolet;
    }
  }

  IconData _getActionIcon() {
    switch (activity.type) {
      case ActivityType.encounter:
        return Icons.person_outline_rounded;
      case ActivityType.meeting:
        return Icons.visibility_outlined;
      case ActivityType.call:
        return Icons.phone_outlined;
      case ActivityType.note:
        return Icons.article_outlined;
      case ActivityType.capture:
        return Icons.badge_outlined;
      case ActivityType.file:
        return Icons.attach_file_rounded;
      case ActivityType.followUp:
        return Icons.task_alt_rounded;
      case ActivityType.companyUpdate:
        return Icons.business_outlined;
    }
  }
}