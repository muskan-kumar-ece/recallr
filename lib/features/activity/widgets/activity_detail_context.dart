import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/activity_models.dart';

/// Relationship context inspector card for wide / desktop viewports.
class ActivityDetailContext extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback? onTapAction;
  final VoidCallback? onTapPerson;

  const ActivityDetailContext({
    super.key,
    required this.activity,
    this.onTapAction,
    this.onTapPerson,
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
      padding: RecallrSpacing.cardPadding,
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Context Inspector Title + Type Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_stories_outlined,
                      size: 16.0,
                      color: RecallrColors.aiElectricViolet,
                    ),
                    RecallrSpacing.gapXs,
                    Expanded(
                      child: Text(
                        'Relationship Context',
                        style: RecallrTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              RecallrSpacing.gapXs,
              RecallrBadge(
                text: activity.type.badgeText,
                variant: RecallrBadgeVariant.verified,
              ),
            ],
          ),
          RecallrSpacing.gapMd,

          // Person Profile Context
          if (activity.personName != null) ...[
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: RecallrColors.slateSurface,
                borderRadius: RecallrRadii.radiusMd,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: Row(
                children: [
                  RecallrAvatar(
                    initials: _getInitials(activity.personName!),
                    size: RecallrAvatarSize.md,
                  ),
                  RecallrSpacing.gapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.personName!,
                          style: RecallrTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: RecallrColors.aiCyanHighlight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (activity.personRole != null && activity.companyName != null)
                          Text(
                            '${activity.personRole!} · ${activity.companyName!}',
                            style: RecallrTypography.bodyMedium.copyWith(
                              color: RecallrColors.textSecondary,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (activity.companyName != null)
                          Text(
                            activity.companyName!,
                            style: RecallrTypography.bodyMedium.copyWith(
                              color: RecallrColors.textTertiary,
                              fontSize: 12.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            RecallrSpacing.gapMd,
          ],

          // Title & Summary
          Text(
            activity.title,
            style: RecallrTypography.headlineMedium.copyWith(
              fontSize: 16.0,
            ),
          ),
          RecallrSpacing.gapXs,
          Text(
            activity.summary,
            style: RecallrTypography.bodyLarge.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          RecallrSpacing.gapMd,

          // Encounter Metadata Matrix
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: RecallrColors.slateSurface,
              borderRadius: RecallrRadii.radiusSm,
            ),
            child: Column(
              children: [
                _buildMetaRow(Icons.schedule_rounded, 'Timestamp', activity.timestamp),
                if (activity.location != null) ...[
                  const SizedBox(height: 6.0),
                  _buildMetaRow(Icons.location_on_outlined, 'Location', activity.location!),
                ],
                if (activity.relationshipIndicator != null) ...[
                  const SizedBox(height: 6.0),
                  _buildMetaRow(Icons.hub_outlined, 'Network Status', activity.relationshipIndicator!),
                ],
                if (activity.followUpStatus != null) ...[
                  const SizedBox(height: 6.0),
                  _buildMetaRow(Icons.task_alt_rounded, 'Commitment', activity.followUpStatus!),
                ],
              ],
            ),
          ),
          RecallrSpacing.gapLg,

          // Action Buttons
          Wrap(
            spacing: RecallrSpacing.sm,
            runSpacing: RecallrSpacing.xs,
            children: [
              RecallrButton(
                label: activity.actionLabel,
                variant: RecallrButtonVariant.primary,
                onPressed: onTapAction ?? () => Navigator.of(context).pushNamed(activity.targetRoute),
              ),
              if (activity.personId != null)
                RecallrButton(
                  label: 'View Dossier',
                  variant: RecallrButtonVariant.secondary,
                  leadingIcon: Icons.person_search_rounded,
                  onPressed: onTapPerson ?? () => Navigator.of(context).pushNamed('/person/${activity.personId}'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 13.0, color: RecallrColors.textTertiary),
        const SizedBox(width: 6.0),
        Text(
          '$label: ',
          style: RecallrTypography.monoMetadata.copyWith(
            color: RecallrColors.textTertiary,
            fontSize: 11.0,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: RecallrTypography.monoMetadata.copyWith(
              color: RecallrColors.textPrimary,
              fontSize: 11.0,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}