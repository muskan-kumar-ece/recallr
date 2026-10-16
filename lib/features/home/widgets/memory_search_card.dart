import 'package:flutter/material.dart';
import '../../../app/app_shell.dart';
import '../../../core/theme/theme.dart';

/// Universal Memory Search entry card.
class MemorySearchCard extends StatelessWidget {
  const MemorySearchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ask your network memory search',
      child: InkWell(
        onTap: () {
          RecallrAppShellScope.openTab(context, 2);
        },
        borderRadius: RecallrRadii.radiusLg,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RecallrSpacing.md,
            vertical: RecallrSpacing.md,
          ),
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusLg,
            border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: RecallrColors.aiElectricViolet,
                size: RecallrIconography.lg,
              ),
              RecallrSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ask your memory...',
                      style: RecallrTypography.titleMedium.copyWith(
                        color: RecallrColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '"What did I discuss with Arjun?" · "Who does AI hardware?"',
                      style: RecallrTypography.labelSmall.copyWith(
                        color: RecallrColors.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              RecallrSpacing.gapSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: RecallrColors.slateSurface,
                  borderRadius: RecallrRadii.radiusSm,
                  border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                ),
                child: Text(
                  'ASK',
                  style: RecallrTypography.monoMetadata.copyWith(
                    color: RecallrColors.aiCyanHighlight,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}