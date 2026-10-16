import 'package:flutter/material.dart';
import '../../../core/routing/recallr_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../screens/capture/capture_modal.dart';
import '../models/person_profile_model.dart';

/// Header for Person Memory Profile (Phase 12).
class PersonProfileHeader extends StatelessWidget {
  final PersonProfile profile;
  final VoidCallback? onBack;

  const PersonProfileHeader({
    super.key,
    required this.profile,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = profile.name.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Navigation & Badge Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: RecallrColors.textPrimary),
              tooltip: 'Back to People',
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            ),
            RecallrBadge(
              text: profile.relationshipType.name.toUpperCase(),
              variant: RecallrBadgeVariant.neutral,
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