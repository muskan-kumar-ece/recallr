import 'package:flutter/material.dart';
import '../../../app/app_shell.dart';
import '../../../core/routing/recallr_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/home_memory_item.dart';

/// Compact, restrained memory statistics bar/grid.
class MemoryPulse extends StatelessWidget {
  final MemoryPulseStats stats;

  const MemoryPulse({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;

        if (isNarrow) {
          return Row(
            children: [
              Expanded(child: _buildMetricItem(context, 'People', stats.peopleCount, RecallrRoutes.people, Icons.people_outline_rounded, tabIndex: 1)),
              _buildDivider(),
              Expanded(child: _buildMetricItem(context, 'Companies', stats.companiesCount, '/company/overview', Icons.business_outlined)),
              _buildDivider(),
              Expanded(child: _buildMetricItem(context, 'Interactions', stats.interactionsCount, RecallrRoutes.activity, Icons.forum_outlined, tabIndex: 3)),
              _buildDivider(),
              Expanded(child: _buildMetricItem(context, 'Follow-ups', stats.followUpsCount, RecallrRoutes.activity, Icons.task_alt_outlined, tabIndex: 3, isHighlighted: stats.followUpsCount > 0)),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildCardMetric(context, 'People', stats.peopleCount, RecallrRoutes.people, Icons.people_outline_rounded, tabIndex: 1)),
            RecallrSpacing.gapSm,
            Expanded(child: _buildCardMetric(context, 'Companies', stats.companiesCount, '/company/overview', Icons.business_outlined)),
            RecallrSpacing.gapSm,
            Expanded(child: _buildCardMetric(context, 'Interactions', stats.interactionsCount, RecallrRoutes.activity, Icons.forum_outlined, tabIndex: 3)),
            RecallrSpacing.gapSm,
            Expanded(child: _buildCardMetric(context, 'Follow-ups', stats.followUpsCount, RecallrRoutes.activity, Icons.task_alt_outlined, tabIndex: 3, isHighlighted: stats.followUpsCount > 0)),
          ],
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 28.0,
      width: 1.0,
      color: RecallrColors.borderSubtle,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
    );
  }

  void _handleNavigation(BuildContext context, String route, int? tabIndex) {
    if (tabIndex != null) {
      RecallrAppShellScope.openTab(context, tabIndex);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  Widget _buildMetricItem(BuildContext context, String label, int count, String route, IconData icon, {int? tabIndex, bool isHighlighted = false}) {
    return InkWell(
      onTap: () => _handleNavigation(context, route, tabIndex),
      borderRadius: RecallrRadii.radiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RecallrSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: RecallrTypography.titleMedium.copyWith(
                color: isHighlighted ? RecallrColors.warmAmberGold : RecallrColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textTertiary,
                fontSize: 10.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardMetric(BuildContext context, String label, int count, String route, IconData icon, {int? tabIndex, bool isHighlighted = false}) {
    return RecallrCard(
      onTap: () => _handleNavigation(context, route, tabIndex),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RecallrSpacing.xs, horizontal: RecallrSpacing.sm),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18.0,
              color: isHighlighted ? RecallrColors.warmAmberGold : RecallrColors.textSecondary,
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count.toString(),
                    style: RecallrTypography.titleMedium.copyWith(
                      color: isHighlighted ? RecallrColors.warmAmberGold : RecallrColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    label,
                    style: RecallrTypography.labelSmall.copyWith(
                      color: RecallrColors.textTertiary,
                      fontSize: 10.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}