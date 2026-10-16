import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/person_profile_model.dart';

/// Expertise & Context Section for Person Memory Profile.
class PersonContextSection extends StatelessWidget {
  final PersonProfile profile;

  const PersonContextSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.psychology_outlined,
              size: 16.0,
              color: RecallrColors.aiCyanHighlight,
            ),
            RecallrSpacing.gapXs,
            Flexible(
              child: Text(
                'Expertise & Capabilities',
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
        Wrap(
          spacing: RecallrSpacing.xs,
          runSpacing: RecallrSpacing.xs,
          children: profile.capabilities.map((cap) {
            return RecallrBadge(
              text: cap,
              variant: RecallrBadgeVariant.neutral,
            );
          }).toList(),
        ),
      ],
    );
  }
}