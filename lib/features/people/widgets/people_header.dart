import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Header for People Directory.
class PeopleHeader extends StatelessWidget {
  final int count;

  const PeopleHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'People',
                style: RecallrTypography.headlineMedium,
              ),
              const SizedBox(height: 2.0),
              Text(
                'Your professional memory, organized around the people you know.',
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
              ),
            ],
          ),
        ),
        RecallrSpacing.gapSm,
        RecallrBadge(
          text: '$count REMEMBERED',
          isDot: false,
          variant: RecallrBadgeVariant.neutral,
        ),
      ],
    );
  }
}