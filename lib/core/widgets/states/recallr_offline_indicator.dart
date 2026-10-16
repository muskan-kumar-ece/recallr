import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_spacing.dart';
import '../../theme/recallr_typography.dart';

/// Slim 24dp banner indicating offline mode backed by native Firestore persistence.
class RecallrOfflineIndicator extends StatelessWidget {
  final bool isOffline;

  const RecallrOfflineIndicator({
    super.key,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.md, vertical: 4.0),
      decoration: const BoxDecoration(
        color: RecallrColors.charcoalCard,
        border: Border(
          bottom: BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6.0,
            height: 6.0,
            decoration: const BoxDecoration(
              color: RecallrColors.warmAmberGold,
              shape: BoxShape.circle,
            ),
          ),
          RecallrSpacing.gapSm,
          Text(
            'Working offline — all changes saved locally',
            style: RecallrTypography.labelSmall.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 11.0,
            ),
          ),
        ],
      ),
    );
  }
}