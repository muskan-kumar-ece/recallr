import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Loading state for memory retrieval and AI synthesis.
class QueryLoadingState extends StatelessWidget {
  const QueryLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16.0,
              height: 16.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(RecallrColors.aiElectricViolet),
              ),
            ),
            RecallrSpacing.gapSm,
            Text(
              'Searching conversations, encounters, and notes...',
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textSecondary,
                fontSize: 13.0,
              ),
            ),
          ],
        ),
        RecallrSpacing.gapLg,

        // Skeleton Answer Card
        Container(
          padding: RecallrSpacing.cardPadding,
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusLg,
            border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              RecallrSkeleton(height: 20.0, width: 180.0),
              SizedBox(height: 12.0),
              RecallrSkeleton(height: 14.0),
              SizedBox(height: 8.0),
              RecallrSkeleton(height: 14.0),
              SizedBox(height: 8.0),
              RecallrSkeleton(height: 14.0, width: 220.0),
            ],
          ),
        ),
        RecallrSpacing.gapLg,

        // Skeleton Sources
        const RecallrSkeleton(height: 20.0, width: 160.0),
        RecallrSpacing.gapSm,
        const RecallrSkeleton(height: 90.0),
        RecallrSpacing.gapSm,
        const RecallrSkeleton(height: 90.0),
      ],
    );
  }
}