import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

/// Placeholder screen for future deep-link routes (/person/:id, /company/:id, etc.).
class DetailPlaceholderScreen extends StatelessWidget {
  final String entityType;
  final String entityId;

  const DetailPlaceholderScreen({
    super.key,
    required this.entityType,
    required this.entityId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        title: Text('$entityType Details'),
        leading: RecallrIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: Padding(
          padding: RecallrSpacing.pagePadding,
          child: RecallrCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$entityType Route', style: RecallrTypography.headlineMedium),
                    const RecallrBadge(text: 'FUTURE PHASE', variant: RecallrBadgeVariant.neutral),
                  ],
                ),
                RecallrSpacing.gapMd,
                Text(
                  'Entity ID: $entityId',
                  style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.aiCyanHighlight),
                ),
                RecallrSpacing.gapMd,
                Text(
                  'This deep-link route is registered and ready for future dossier implementation.',
                  style: RecallrTypography.bodyMedium,
                ),
                RecallrSpacing.gapLg,
                RecallrButton(
                  label: 'Return to Network',
                  variant: RecallrButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}