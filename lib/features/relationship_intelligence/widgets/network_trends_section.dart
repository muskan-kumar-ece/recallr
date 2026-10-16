import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/models.dart';

/// Renders measurable temporal trends for the network.
class NetworkTrendsSection extends StatelessWidget {
  final List<NetworkTrend> trends;

  const NetworkTrendsSection({
    super.key,
    required this.trends,
  });

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trending_up_rounded,
              size: 15.0,
              color: RecallrColors.aiCyanHighlight,
            ),
            const SizedBox(width: 6.0),
            Text(
              'NETWORK TRENDS',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ...trends.map((t) => _buildTrendCard(context, t)),
      ],
    );
  }

  Widget _buildTrendCard(BuildContext context, NetworkTrend trend) {
    final type = trend.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: type.colorToken.withValues(alpha: 0.12),
              borderRadius: RecallrRadii.radiusSm,
            ),
            child: Icon(type.icon, size: 16.0, color: type.colorToken),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type.displayName,
                      style: RecallrTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        '•  ${trend.periodLabel}',
                        style: RecallrTypography.labelSmall.copyWith(
                          color: RecallrColors.textTertiary,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3.0),
                Text(
                  trend.description,
                  style: RecallrTypography.bodyMedium.copyWith(
                    color: RecallrColors.textSecondary,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
