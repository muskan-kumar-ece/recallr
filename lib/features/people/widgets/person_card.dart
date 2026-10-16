import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../relationship_intelligence/models/models.dart';
import '../models/person_item.dart';

/// Relationship-aware Person Card for Recallr People directory.
class PersonCard extends StatelessWidget {
  final PersonItem person;
  final UnifiedPersonRelationshipIntelligence? intelligence;

  const PersonCard({
    super.key,
    required this.person,
    this.intelligence,
  });

  @override
  Widget build(BuildContext context) {
    return RecallrCard(
      onTap: () => Navigator.of(context).pushNamed(person.targetRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Avatar + Name/Role + Last Contacted
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
            ],
          ),

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
                  children: person.capabilities
                      .take(3)
                      .map((cap) => RecallrBadge(
                            text: cap,
                            variant: RecallrBadgeVariant.neutral,
                          ))
                      .toList(),
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
}