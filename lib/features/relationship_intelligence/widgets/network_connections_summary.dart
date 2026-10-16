import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/models.dart';

/// Renders aggregate metrics for network connectivity, density, and cluster health.
class NetworkConnectionsSummary extends StatelessWidget {
  final NetworkConnectionIntelligence intelligence;

  const NetworkConnectionsSummary({
    super.key,
    required this.intelligence,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.hub_outlined,
              size: 15.0,
              color: RecallrColors.aiCyanHighlight,
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                'NETWORK GRAPH & CONNECTIONS',
                style: RecallrTypography.labelSmall.copyWith(
                  color: RecallrColors.textTertiary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: RecallrSpacing.sm,
          mainAxisSpacing: RecallrSpacing.sm,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMetricCard(
              context,
              title: 'TOTAL CONNECTIONS',
              value: intelligence.totalConnections.toString(),
              subtitle: '${intelligence.connectedPeople} connected contacts',
              icon: Icons.link_rounded,
              color: RecallrColors.aiCyanHighlight,
            ),
            _buildMetricCard(
              context,
              title: 'NETWORK DENSITY',
              value: intelligence.densityPercentageString,
              subtitle: intelligence.totalNodes >= 2
                  ? 'of max possible edges'
                  : 'N/A (< 2 contacts)',
              icon: Icons.grain_rounded,
              color: RecallrColors.aiElectricViolet,
            ),
            _buildMetricCard(
              context,
              title: 'RELATIONSHIP CLUSTERS',
              value: intelligence.clusterCount.toString(),
              subtitle: intelligence.strongestCluster != null
                  ? 'Top: ${intelligence.strongestCluster!.name}'
                  : 'No clusters formed',
              icon: Icons.groups_outlined,
              color: RecallrColors.emeraldVerified,
            ),
            _buildMetricCard(
              context,
              title: 'ISOLATED CONTACTS',
              value: intelligence.isolatedPeople.toString(),
              subtitle: intelligence.isolatedPeople > 0
                  ? '0 explicit connections'
                  : 'Fully interconnected',
              icon: Icons.person_off_outlined,
              color: intelligence.isolatedPeople > 0
                  ? RecallrColors.warmAmberGold
                  : RecallrColors.textTertiary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(RecallrSpacing.sm),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 13.0, color: color),
              const SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  title,
                  style: RecallrTypography.labelSmall.copyWith(
                    color: RecallrColors.textTertiary,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: RecallrTypography.headlineMedium.copyWith(
              color: RecallrColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18.0,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            subtitle,
            style: RecallrTypography.labelSmall.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 9.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
