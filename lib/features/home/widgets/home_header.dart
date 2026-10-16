import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Compact greeting and context header.
class HomeHeader extends StatelessWidget {
  final String? userName;

  const HomeHeader({super.key, this.userName});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final name = userName?.isNotEmpty == true ? ', ${userName!.split(' ').first}' : '';

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
                '$greeting$name',
                style: RecallrTypography.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2.0),
              Text(
                'What should you remember or act on right now?',
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
              ),
            ],
          ),
        ),
        RecallrSpacing.gapSm,
        const RecallrBadge(
          text: 'SYNCED',
          isDot: false,
          variant: RecallrBadgeVariant.verified,
        ),
      ],
    );
  }
}