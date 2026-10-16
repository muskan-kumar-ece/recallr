import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/capture_models.dart';

/// Single interactive capture method card.
class CaptureMethodCard extends StatelessWidget {
  final CaptureType type;
  final VoidCallback onTap;

  const CaptureMethodCard({
    super.key,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: RecallrRadii.radiusMd,
        child: InkWell(
          borderRadius: RecallrRadii.radiusMd,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: type.color.withAlpha(25),
                    borderRadius: RecallrRadii.radiusSm,
                    border: Border.all(color: type.color.withAlpha(80), width: 1.0),
                  ),
                  child: Icon(
                    type.icon,
                    size: 20.0,
                    color: type.color,
                  ),
                ),
                RecallrSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        type.label,
                        style: RecallrTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        type.description,
                        style: RecallrTypography.bodyMedium.copyWith(
                          color: RecallrColors.textSecondary,
                          fontSize: 12.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13.0,
                  color: RecallrColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}