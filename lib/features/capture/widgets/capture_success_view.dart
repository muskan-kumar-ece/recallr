import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/capture_models.dart';
import '../models/capture_processing_models.dart';

/// Memory saved confirmation screen with intelligence processing status.
class CaptureSuccessView extends StatelessWidget {
  final CaptureItem item;
  final VoidCallback onViewMemory;
  final VoidCallback onDone;
  final CaptureProcessingStatus? processingStatus;
  final String? processingError;
  final VoidCallback? onRetryProcessing;

  const CaptureSuccessView({
    super.key,
    required this.item,
    required this.onViewMemory,
    required this.onDone,
    this.processingStatus,
    this.processingError,
    this.onRetryProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final status = processingStatus ?? item.processingStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusLg,
            border: Border.all(color: RecallrColors.emeraldVerified.withAlpha(120), width: 1.0),
          ),
          child: Column(
            children: [
              Container(
                width: 52.0,
                height: 52.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RecallrColors.emeraldVerified.withAlpha(30),
                  border: Border.all(color: RecallrColors.emeraldVerified, width: 1.5),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 28.0,
                  color: RecallrColors.emeraldVerified,
                ),
              ),
              RecallrSpacing.gapMd,
              Text(
                'Memory Saved',
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17.0,
                ),
              ),
              RecallrSpacing.gapXs,
              Text(
                'Recallr will now remember this context across your network.',
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
              RecallrSpacing.gapMd,

              // Associated Entity Tag
              if (item.personName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: RecallrColors.slateSurface,
                    borderRadius: RecallrRadii.radiusSm,
                    border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_pin_circle_outlined,
                        size: 14.0,
                        color: RecallrColors.aiCyanHighlight,
                      ),
                      const SizedBox(width: 6.0),
                      Flexible(
                        child: Text(
                          'Associated with: ${item.personName!}${item.companyName != null ? ' · ${item.companyName!}' : ''}',
                          style: RecallrTypography.monoMetadata.copyWith(
                            color: RecallrColors.aiCyanHighlight,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                RecallrSpacing.gapSm,
              ],

              // Processing Status Badge / Indicator
              if (status != null) _buildProcessingStatusBadge(context, status),
            ],
          ),
        ),
        RecallrSpacing.gapLg,

        // Actions
        Row(
          children: [
            Expanded(
              child: RecallrButton(
                label: 'View Memory',
                variant: RecallrButtonVariant.secondary,
                leadingIcon: Icons.visibility_outlined,
                onPressed: onViewMemory,
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: RecallrButton(
                label: 'Done',
                variant: RecallrButtonVariant.primary,
                leadingIcon: Icons.done_rounded,
                onPressed: onDone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessingStatusBadge(BuildContext context, CaptureProcessingStatus status) {
    switch (status) {
      case CaptureProcessingStatus.processing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: RecallrColors.aiElectricViolet.withAlpha(25),
            borderRadius: RecallrRadii.radiusSm,
            border: Border.all(color: RecallrColors.aiElectricViolet.withAlpha(90), width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12.0,
                height: 12.0,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(RecallrColors.aiElectricViolet),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Extracting & indexing entities...',
                style: RecallrTypography.labelSmall.copyWith(
                  color: RecallrColors.aiElectricViolet,
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
        );

      case CaptureProcessingStatus.completed:
        final resolutionStatus = item.entityResolutionStatus;
        final personName = item.personName;
        String label = 'Processed & Indexed';
        if (resolutionStatus == 'resolvedExisting' && personName != null && personName.isNotEmpty) {
          label = 'Matched to $personName';
        } else if (resolutionStatus == 'resolvedNew' && personName != null && personName.isNotEmpty) {
          label = 'New person detected · $personName';
        } else if (resolutionStatus == 'requiresReview') {
          label = 'Possible matches found · Review';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: RecallrColors.emeraldVerified.withAlpha(20),
            borderRadius: RecallrRadii.radiusSm,
            border: Border.all(color: RecallrColors.emeraldVerified.withAlpha(80), width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 13.0,
                color: RecallrColors.emeraldVerified,
              ),
              const SizedBox(width: 6.0),
              Text(
                label,
                style: RecallrTypography.labelSmall.copyWith(
                  color: RecallrColors.emeraldVerified,
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
        );

      case CaptureProcessingStatus.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: RecallrColors.warmAmberGold.withAlpha(20),
                borderRadius: RecallrRadii.radiusSm,
                border: Border.all(color: RecallrColors.warmAmberGold.withAlpha(90), width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13.0,
                    color: RecallrColors.warmAmberGold,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Entity extraction failed',
                    style: RecallrTypography.labelSmall.copyWith(
                      color: RecallrColors.warmAmberGold,
                      fontSize: 11.0,
                    ),
                  ),
                  if (onRetryProcessing != null) ...[
                    const SizedBox(width: 8.0),
                    InkWell(
                      onTap: onRetryProcessing,
                      child: Text(
                        'Retry',
                        style: RecallrTypography.labelSmall.copyWith(
                          color: RecallrColors.aiCyanHighlight,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

      case CaptureProcessingStatus.pending:
        return const SizedBox.shrink();
    }
  }
}