import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/routing/recallr_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../screens/capture/capture_modal.dart';
import '../models/person_profile_model.dart';

/// Header for Person Memory Profile (Phase 12).
class PersonProfileHeader extends StatelessWidget {
  final PersonProfile profile;
  final VoidCallback? onBack;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  const PersonProfileHeader({
    super.key,
    required this.profile,
    this.onBack,
    this.onDelete,
    this.onEdit,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = profile.name.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Navigation & Actions Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: RecallrColors.textPrimary),
              tooltip: 'Back to People',
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RecallrBadge(
                  text: profile.relationshipType.name.toUpperCase(),
                  variant: RecallrBadgeVariant.neutral,
                ),
                if (onShare != null) ...[
                  const SizedBox(width: 4.0),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: RecallrColors.textSecondary, size: 20.0),
                    tooltip: 'Share Contact',
                    onPressed: onShare,
                  ),
                ],
                if (onEdit != null) ...[
                  const SizedBox(width: 4.0),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: RecallrColors.textSecondary, size: 20.0),
                    tooltip: 'Edit Contact Details',
                    onPressed: onEdit,
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 4.0),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: RecallrColors.crimsonAlert, size: 20.0),
                    tooltip: 'Delete Contact',
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
        RecallrSpacing.gapSm,

        // Profile Identity Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecallrAvatar(
              initials: profile.initials,
              size: RecallrAvatarSize.xl,
            ),
            RecallrSpacing.gapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          style: RecallrTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 24.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      const Icon(
                        Icons.verified_rounded,
                        color: RecallrColors.emeraldVerified,
                        size: 18.0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    '${profile.role} · ${profile.company}',
                    style: RecallrTypography.titleMedium.copyWith(
                      color: RecallrColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.location.isNotEmpty) ...[
                    const SizedBox(height: 3.0),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13.0,
                          color: RecallrColors.textTertiary,
                        ),
                        const SizedBox(width: 3.0),
                        Expanded(
                          child: Text(
                            profile.location,
                            style: RecallrTypography.bodyMedium.copyWith(
                              color: RecallrColors.textTertiary,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (profile.brands.isNotEmpty) ...[
                    const SizedBox(height: 4.0),
                    Wrap(
                      spacing: 5.0,
                      runSpacing: 4.0,
                      children: profile.brands.map((brand) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: RecallrColors.slateSurface,
                          borderRadius: RecallrRadii.radiusSm,
                          border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sell_outlined, size: 10.0, color: RecallrColors.aiCyanHighlight),
                            const SizedBox(width: 3.5),
                            Text(
                              brand,
                              style: RecallrTypography.labelSmall.copyWith(
                                color: RecallrColors.textPrimary,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                  if ((profile.phone != null && profile.phone!.isNotEmpty) ||
                      (profile.email != null && profile.email!.isNotEmpty)) ...[
                    const SizedBox(height: 6.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        if (profile.phone != null && profile.phone!.isNotEmpty)
                          InkWell(
                            borderRadius: RecallrRadii.radiusSm,
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: profile.phone!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied phone: ${profile.phone!}')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
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
                                    profile.phone!,
                                    style: RecallrTypography.labelSmall.copyWith(
                                      color: RecallrColors.aiCyanHighlight,
                                      fontSize: 11.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (profile.email != null && profile.email!.isNotEmpty)
                          InkWell(
                            borderRadius: RecallrRadii.radiusSm,
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: profile.email!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied email: ${profile.email!}')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
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
                                    profile.email!,
                                    style: RecallrTypography.labelSmall.copyWith(
                                      color: RecallrColors.aiElectricViolet,
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
                ],
              ),
            ),
          ],
        ),
        RecallrSpacing.gapMd,

        // Quick Action Bar
        Row(
          children: [
            Expanded(
              child: RecallrButton(
                label: 'Ask Recallr',
                leadingIcon: Icons.search_rounded,
                variant: RecallrButtonVariant.aiGradient,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    RecallrRoutes.ask,
                    arguments: 'What should I know about $firstName?',
                  );
                },
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: RecallrButton(
                label: 'Capture',
                leadingIcon: Icons.add_rounded,
                variant: RecallrButtonVariant.secondary,
                onPressed: () {
                  RecallrBottomSheet.show(
                    context: context,
                    child: const CaptureModal(),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}