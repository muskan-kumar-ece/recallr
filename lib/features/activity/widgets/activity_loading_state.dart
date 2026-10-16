import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Structured loading skeleton for the Activity timeline.
class ActivityLoadingState extends StatelessWidget {
  const ActivityLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        // Search & Filter Skeletons
        const RecallrSkeleton(height: 48.0),
        RecallrSpacing.gapMd,
        Row(
          children: const [
            RecallrSkeleton(width: 60.0, height: 32.0),
            SizedBox(width: 8.0),
            RecallrSkeleton(width: 80.0, height: 32.0),
            SizedBox(width: 8.0),
            RecallrSkeleton(width: 90.0, height: 32.0),
            SizedBox(width: 8.0),
            RecallrSkeleton(width: 70.0, height: 32.0),
          ],
        ),
        RecallrSpacing.gapXl,

        // Group 1 Header
        Row(
          children: const [
            RecallrSkeleton(width: 12.0, height: 12.0),
            SizedBox(width: 8.0),
            RecallrSkeleton(width: 90.0, height: 18.0),
          ],
        ),
        RecallrSpacing.gapMd,
        const RecallrSkeleton(height: 140.0),
        RecallrSpacing.gapSm,
        const RecallrSkeleton(height: 140.0),
        RecallrSpacing.gapXl,

        // Group 2 Header
        Row(
          children: const [
            RecallrSkeleton(width: 12.0, height: 12.0),
            SizedBox(width: 8.0),
            RecallrSkeleton(width: 110.0, height: 18.0),
          ],
        ),
        RecallrSpacing.gapMd,
        const RecallrSkeleton(height: 140.0),
      ],
    );
  }
}