import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../screens/capture/capture_modal.dart';

/// Home-level Quick Capture entry card.
class QuickCaptureTile extends StatelessWidget {
  const QuickCaptureTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Quick capture visiting card or meeting notes',
      child: InkWell(
        onTap: () {
          RecallrBottomSheet.show(
            context: context,
            child: const CaptureModal(),
          );
        },
        borderRadius: RecallrRadii.radiusLg,
        child: Container(
          padding: const EdgeInsets.all(RecallrSpacing.md),
          decoration: BoxDecoration(
            color: RecallrColors.slateSurface,
            borderRadius: RecallrRadii.radiusLg,
            border: Border.all(color: RecallrColors.borderHighlight, width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: const BoxDecoration(
                  color: RecallrColors.aiElectricViolet,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: RecallrColors.textPrimary,
                  size: 20.0,
                ),
              ),
              RecallrSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Capture an Encounter',
                      style: RecallrTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Scan visiting card, record voice memo, or type meeting notes.',
                      style: RecallrTypography.bodyMedium.copyWith(
                        color: RecallrColors.textSecondary,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: RecallrColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}