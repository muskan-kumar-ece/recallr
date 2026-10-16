import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/models.dart';

/// Renders detected relationship clusters with member details and strength badges.
class NetworkClustersSection extends StatelessWidget {
  final List<RelationshipCluster> clusters;
  final ValueChanged<RelationshipCluster>? onClusterTap;

  const NetworkClustersSection({
    super.key,
    required this.clusters,
    this.onClusterTap,
  });

  @override
  Widget build(BuildContext context) {
    if (clusters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bubble_chart_outlined,
              size: 15.0,
              color: RecallrColors.aiCyanHighlight,
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                'RELATIONSHIP CLUSTERS (${clusters.length})',
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
        ...clusters.map((c) => _buildClusterCard(context, c)),
      ],
    );
  }

  Widget _buildClusterCard(BuildContext context, RelationshipCluster cluster) {
    final type = cluster.type;
    final color = type.colorToken;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: RecallrRadii.radiusSm,
                ),
                child: Icon(type.icon, size: 16.0, color: color),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cluster.name,
                            style: RecallrTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: RecallrColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: RecallrRadii.radiusPill,
                            border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
                          ),
                          child: Text(
                            type.label,
                            style: RecallrTypography.labelSmall.copyWith(
                              color: color,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${cluster.memberCount} members • ${cluster.interactionCount} total interactions',
                      style: RecallrTypography.labelSmall.copyWith(
                        color: RecallrColors.textSecondary,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: RecallrColors.slateSurface,
                  borderRadius: RecallrRadii.radiusSm,
                  border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${cluster.clusterStrength.toInt()}',
                      style: RecallrTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      'STRENGTH',
                      style: RecallrTypography.labelSmall.copyWith(
                        fontSize: 8.0,
                        color: RecallrColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            cluster.description,
            style: RecallrTypography.bodyMedium.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}
