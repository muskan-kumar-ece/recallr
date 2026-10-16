import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Structured loading skeleton for Follow-ups Hub.
class FollowUpLoadingState extends StatelessWidget {
  const FollowUpLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        // Summary Metrics Skeletons
        Row(
          children: const [
            Expanded(child: RecallrSkeleton(height: 72.0)),
            SizedBox(width: 8.0),
            Expanded(child: RecallrSkeleton(height: 72.0)),
            SizedBox(width: 8.0),
            Expanded(child: RecallrSkeleton(height: 72.0)),
            SizedBox(width: 8.0),
            Expanded(child: RecallrSkeleton(height: 72.0)),
          ],
        ),
        RecallrSpacing.gapLg,

        // Search Bar Skeleton
        const RecallrSkeleton(height: 48.0),
        RecallrSpacing.gapMd,

        // Filter Chips Skeleton
        Row(
          children: const [
            RecallrSkeleton(width: 50.0, height: 32.0),
            SizedBox(width: 8.0),
            RecallrSkeleton(width: 80.0, height: 32.0),
            SizedBox(width: 8.0),
            RecallrSkeleton(width: 75.0, height: 32.0),
            SizedBox(width: 8.0),
            RecallrSkeleton(width: 70.0, height: 32.0),
          ],
        ),
        RecallrSpacing.gapLg,

        // Commitment Cards Skeletons
        const RecallrSkeleton(height: 160.0),
        RecallrSpacing.gapSm,
        const RecallrSkeleton(height: 160.0),
        RecallrSpacing.gapSm,
        const RecallrSkeleton(height: 160.0),
      ],
    );
  }
}