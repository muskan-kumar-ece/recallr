import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/capture_models.dart';

/// Structured review view before committing capture to permanent network memory.
class CaptureReviewView extends StatelessWidget {
  final CaptureType type;
  final CaptureReviewData reviewData;
  final VoidCallback onEdit;
  final VoidCallback onSave;

  const CaptureReviewView({
    super.key,
    required this.type,
    required this.reviewData,
    required this.onEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Structured Memory Preview Card
        Container(
          padding: RecallrSpacing.cardPadding,
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusLg,
            border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Method Badge + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: RecallrSpacing.xs,
                    children: [
                      Icon(type.icon, size: 14.0, color: type.color),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: type.color.withAlpha(25),
                          borderRadius: RecallrRadii.radiusSm,
                          border: Border.all(color: type.color.withAlpha(80), width: 1.0),
                        ),
                        child: Text(
                          type.label.toUpperCase(),
                          style: RecallrTypography.labelSmall.copyWith(
                            color: type.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (reviewData.date != null)
                    Text(
                      reviewData.date!,
                      style: RecallrTypography.monoMetadata.copyWith(
                        color: RecallrColors.textTertiary,
                        fontSize: 10.5,
                      ),
                    ),
                ],
              ),
              RecallrSpacing.gapSm,

              // Memory Title
              Text(
                reviewData.title,
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              RecallrSpacing.gapXs,

              // Entity Context Tag
              if (reviewData.personName != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.person_pin_circle_outlined,
                      size: 14.0,
                      color: RecallrColors.aiCyanHighlight,
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        '${reviewData.personName!}${reviewData.companyName != null ? ' · ${reviewData.companyName!}' : ''}${reviewData.eventName != null ? ' (${reviewData.eventName!})' : ''}',
                        style: RecallrTypography.bodyMedium.copyWith(
                          color: RecallrColors.aiCyanHighlight,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                RecallrSpacing.gapSm,
              ],

              // Summary
              Text(
                reviewData.summary,
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                  fontSize: 13.0,
                  height: 1.4,
                ),
              ),
              RecallrSpacing.gapMd,

              // Bullet Points / Key Takeaways
              if (reviewData.bulletPoints.isNotEmpty) ...[
                Text(
                  'KEY TAKEAWAYS',
                  style: RecallrTypography.labelSmall.copyWith(
                    color: RecallrColors.textTertiary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 6.0),
                ...reviewData.bulletPoints.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.aiElectricViolet)),
                        Expanded(
                          child: Text(
                            bullet,
                            style: RecallrTypography.bodyMedium.copyWith(
                              color: RecallrColors.textPrimary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                RecallrSpacing.gapSm,
              ],

              // Contact Details Matrix (For business cards)
              if (reviewData.contactDetails.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: RecallrColors.slateSurface,
                    borderRadius: RecallrRadii.radiusSm,
                  ),
                  child: Column(
                    children: reviewData.contactDetails.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: RecallrTypography.monoMetadata.copyWith(
                                color: RecallrColors.textTertiary,
                                fontSize: 11.0,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: RecallrTypography.monoMetadata.copyWith(
                                  color: RecallrColors.textPrimary,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        RecallrSpacing.gapLg,

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: RecallrButton(
                label: 'Edit',
                variant: RecallrButtonVariant.secondary,
                leadingIcon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: RecallrButton(
                label: 'Save to Memory',
                variant: RecallrButtonVariant.primary,
                leadingIcon: Icons.check_circle_outline_rounded,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}