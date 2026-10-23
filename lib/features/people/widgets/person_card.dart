import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/utils/share_formatter.dart';
import '../../../core/widgets/share_bottom_sheet.dart';
import '../../../core/widgets/destructive_confirm_dialog.dart';
import '../../relationship_intelligence/models/models.dart';
import '../models/person_item.dart';

/// Relationship-aware Person Card for Recallr People directory.
class PersonCard extends StatelessWidget {
  final PersonItem person;
  final UnifiedPersonRelationshipIntelligence? intelligence;
  final VoidCallback? onDelete;

  const PersonCard({
    super.key,
    required this.person,
    this.intelligence,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return RecallrCard(
      onTap: () => Navigator.of(context).pushNamed(person.targetRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Avatar + Name/Role + Last Contacted + 3-dots Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecallrAvatar(
                initials: person.initials,
                size: RecallrAvatarSize.md,
              ),
              RecallrSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            person.name,
                            style: RecallrTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (person.lastInteraction != null) ...[
                          RecallrSpacing.gapSm,
                          Text(
                            person.lastInteraction!,
                            style: RecallrTypography.monoMetadata.copyWith(
                              color: RecallrColors.textTertiary,
                              fontSize: 11.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${person.role} · ${person.company}',
                      style: RecallrTypography.bodyMedium.copyWith(
                        color: RecallrColors.textSecondary,
                        fontSize: 13.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (intelligence != null) ...[
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: intelligence!.relationshipState.colorToken.withValues(alpha: 0.15),
                              borderRadius: RecallrRadii.radiusPill,
                              border: Border.all(
                                color: intelligence!.relationshipState.colorToken.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              intelligence!.relationshipState.displayName.toUpperCase(),
                              style: RecallrTypography.labelSmall.copyWith(
                                color: intelligence!.relationshipState.colorToken,
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            '${intelligence!.strengthScore.toInt()}/100',
                            style: RecallrTypography.labelSmall.copyWith(
                              color: RecallrColors.textTertiary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (intelligence!.momentumDirection != MomentumDirection.insufficientHistory) ...[
                            const SizedBox(width: 4.0),
                            Icon(
                              intelligence!.momentumDirection.icon,
                              size: 11.0,
                              color: intelligence!.momentumDirection.colorToken,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18.0, color: RecallrColors.textTertiary),
                color: RecallrColors.charcoalCard,
                shape: RoundedRectangleBorder(
                  borderRadius: RecallrRadii.radiusMd,
                  side: const BorderSide(color: RecallrColors.borderSubtle),
                ),
                onSelected: (val) {
                  if (val == 'view') {
                    Navigator.of(context).pushNamed(person.targetRoute);
                  } else if (val == 'share') {
                    _handleShare(context);
                  } else if (val == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 16.0, color: RecallrColors.textSecondary),
                        const SizedBox(width: 8.0),
                        Text('View Dossier', style: RecallrTypography.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined, size: 16.0, color: RecallrColors.aiElectricViolet),
                        const SizedBox(width: 8.0),
                        Text('Share Contact', style: RecallrTypography.bodyMedium),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 16.0, color: RecallrColors.crimsonAlert),
                          const SizedBox(width: 8.0),
                          Text('Delete Contact', style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.crimsonAlert)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Direct Contact Info: Phone & Email
          if ((person.phone != null && person.phone!.isNotEmpty) ||
              (person.email != null && person.email!.isNotEmpty)) ...[
            RecallrSpacing.gapSm,
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (person.phone != null && person.phone!.isNotEmpty)
                  InkWell(
                    borderRadius: RecallrRadii.radiusSm,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: person.phone!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied phone: ${person.phone!}')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: RecallrColors.slateSurface,
                        borderRadius: RecallrRadii.radiusSm,
                        border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_outlined, size: 12.0, color: RecallrColors.aiCyanHighlight),
                          const SizedBox(width: 4.0),
                          Text(
                            person.phone!,
                            style: RecallrTypography.labelSmall.copyWith(
                              color: RecallrColors.textSecondary,
                              fontSize: 11.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (person.email != null && person.email!.isNotEmpty)
                  InkWell(
                    borderRadius: RecallrRadii.radiusSm,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: person.email!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied email: ${person.email!}')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: RecallrColors.slateSurface,
                        borderRadius: RecallrRadii.radiusSm,
                        border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.email_outlined, size: 12.0, color: RecallrColors.aiElectricViolet),
                          const SizedBox(width: 4.0),
                          Text(
                            person.email!,
                            style: RecallrTypography.labelSmall.copyWith(
                              color: RecallrColors.textSecondary,
                              fontSize: 11.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Context Snippet / Encounter Location
          if (person.contextSnippet != null || person.locationOrEvent != null) ...[
            RecallrSpacing.gapSm,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: RecallrColors.slateSurface,
                borderRadius: RecallrRadii.radiusSm,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (person.locationOrEvent != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13.0,
                          color: RecallrColors.aiCyanHighlight,
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            person.locationOrEvent!,
                            style: RecallrTypography.labelSmall.copyWith(
                              color: RecallrColors.aiCyanHighlight,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                  ],
                  if (person.contextSnippet != null)
                    Text(
                      person.contextSnippet!,
                      style: RecallrTypography.bodyMedium.copyWith(
                        color: RecallrColors.textPrimary,
                        fontSize: 12.0,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],

          // Pending Follow-up Banner
          if (person.hasPendingFollowUp && person.pendingFollowUp != null) ...[
            RecallrSpacing.gapSm,
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 14.0,
                  color: RecallrColors.warmAmberGold,
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    'Follow-up: ${person.pendingFollowUp!}',
                    style: RecallrTypography.bodyMedium.copyWith(
                      color: RecallrColors.warmAmberGold,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Bottom Capabilities & Interaction Count Row
          RecallrSpacing.gapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: RecallrSpacing.xs,
                  runSpacing: 4.0,
                  children: [
                    ...person.brands.take(2).map((brand) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: RecallrColors.slateSurface,
                            borderRadius: RecallrRadii.radiusSm,
                            border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sell_outlined, size: 9.0, color: RecallrColors.aiCyanHighlight),
                              const SizedBox(width: 3.0),
                              Text(
                                brand,
                                style: RecallrTypography.labelSmall.copyWith(
                                  color: RecallrColors.textPrimary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                    ...person.capabilities
                        .take(person.brands.isNotEmpty ? 2 : 3)
                        .map((cap) => RecallrBadge(
                              text: cap,
                              variant: RecallrBadgeVariant.neutral,
                            )),
                  ],
                ),
              ),
              RecallrSpacing.gapSm,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.forum_outlined,
                    size: 13.0,
                    color: RecallrColors.textTertiary,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '${person.interactionCount}',
                    style: RecallrTypography.monoMetadata.copyWith(
                      color: RecallrColors.textTertiary,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleShare(BuildContext context) {
    final summary = ShareFormatter.formatPersonItemSummary(person);
    final vCard = ShareFormatter.personItemToVCard(person);
    ShareBottomSheet.show(
      context,
      title: 'Share Contact',
      subtitle: '${person.name} · ${person.company}',
      textSummary: summary,
      vCardContent: vCard,
      shareSubject: 'Contact Card: ${person.name}',
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await DestructiveConfirmDialog.show(
      context,
      title: 'Delete Contact',
      message: 'Are you sure you want to remove \${person.name} from your contacts? This cannot be undone.',
      confirmLabel: 'Delete Contact',
    );
    if (confirmed && onDelete != null) {
      onDelete!();
    }
  }
}
