import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/follow_up_models.dart';

/// Relationship context inspector panel for wide / desktop viewports (>= 720dp).
class FollowUpDetailContext extends StatelessWidget {
  final FollowUpItem item;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onTapPerson;
  final VoidCallback? onTapSource;

  const FollowUpDetailContext({
    super.key,
    required this.item,
    this.onToggleComplete,
    this.onTapPerson,
    this.onTapSource,
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
      padding: RecallrSpacing.cardPadding,
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Header: Inspector Title + Badge
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
            ],
          ),
          RecallrSpacing.gapMd,

          // Person Profile Context Card
          if (item.personName != null) ...[
            GestureDetector(
              onTap: onTapPerson,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: RecallrColors.slateSurface,
                  borderRadius: RecallrRadii.radiusMd,
                  border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                ),
                child: Row(
                  children: [
                    RecallrAvatar(
                      initials: _getInitials(item.personName!),
                      size: RecallrAvatarSize.md,
                    ),
                    RecallrSpacing.gapSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.personName!,
                            style: RecallrTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: RecallrColors.aiCyanHighlight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.personRole != null && item.companyName != null)
                            Text(
                              '${item.personRole!} · ${item.companyName!}',
                              style: RecallrTypography.bodyMedium.copyWith(
                                color: RecallrColors.textSecondary,
                                fontSize: 12.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (item.companyName != null)
                            Text(
                              item.companyName!,
                              style: RecallrTypography.bodyMedium.copyWith(
                                color: RecallrColors.textTertiary,
                                fontSize: 12.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13.0,
                      color: RecallrColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            RecallrSpacing.gapMd,
          ],

          // Commitment Title & Description
          Text(
            item.title,
            style: RecallrTypography.headlineMedium.copyWith(
              fontSize: 16.0,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? RecallrColors.textTertiary : RecallrColors.textPrimary,
            ),
          ),
          RecallrSpacing.gapXs,
          Text(
            item.context,
            style: RecallrTypography.bodyLarge.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          RecallrSpacing.gapMd,

          // Metadata Matrix
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: RecallrColors.slateSurface,
              borderRadius: RecallrRadii.radiusSm,
            ),
            child: Column(
              children: [
                _buildMetaRow(Icons.schedule_rounded, 'Timing', item.dueDate),
                if (item.sourceMemoryTitle != null) ...[
                  const SizedBox(height: 6.0),
                  _buildMetaRow(Icons.auto_stories_outlined, 'Origin', item.sourceMemoryTitle!),
                ],
                if (item.location != null) ...[
                  const SizedBox(height: 6.0),
                  _buildMetaRow(Icons.location_on_outlined, 'Location', item.location!),
                ],
                if (item.priority.label.isNotEmpty) ...[
                  const SizedBox(height: 6.0),
                  _buildMetaRow(Icons.flag_outlined, 'Priority', item.priority.label),
                ],
              ],
            ),
          ),
          RecallrSpacing.gapLg,

          // Action Buttons (Wrap)
          Wrap(
            spacing: RecallrSpacing.sm,
            runSpacing: RecallrSpacing.xs,
            children: [
              RecallrButton(
                label: isCompleted ? 'Completed' : 'Complete',
                variant: isCompleted ? RecallrButtonVariant.secondary : RecallrButtonVariant.primary,
                leadingIcon: isCompleted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                onPressed: onToggleComplete,
              ),
              if (item.personId != null)
                RecallrButton(
                  label: 'View Dossier',
                  variant: RecallrButtonVariant.secondary,
                  leadingIcon: Icons.person_search_rounded,
                  onPressed: onTapPerson ?? () => Navigator.of(context).pushNamed('/person/${item.personId}'),
                ),
              if (item.sourceInteractionId != null)
                RecallrButton(
                  label: 'Source Interaction',
                  variant: RecallrButtonVariant.secondary,
                  leadingIcon: Icons.visibility_outlined,
                  onPressed: onTapSource ?? () => Navigator.of(context).pushNamed('/interaction/${item.sourceInteractionId}'),
                ),
            ],
          ),
        ],
      ),
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