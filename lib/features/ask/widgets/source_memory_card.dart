import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../models/ask_models.dart';

/// Single source/provenance memory card.
class SourceMemoryCard extends StatelessWidget {
  final MemorySource source;

  const SourceMemoryCard({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    return RecallrCard(
      onTap: source.targetRoute != null
          ? () => Navigator.of(context).pushNamed(source.targetRoute!)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Source Type + Verified Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      source.icon,
                      size: 14.0,
                      color: RecallrColors.aiCyanHighlight,
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        source.sourceType,
                        style: RecallrTypography.labelSmall.copyWith(
                          color: RecallrColors.aiCyanHighlight,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (source.isVerified) ...[
                RecallrSpacing.gapXs,
                const RecallrBadge(
                  text: 'VERIFIED',
                  variant: RecallrBadgeVariant.verified,
                ),
              ],
            ],
          ),
          RecallrSpacing.gapSm,

          // Person Info
          Text(
            '${source.personName} · ${source.company}',
            style: RecallrTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          Row(
            children: [
              if (source.eventOrLocation != null) ...[
                const Icon(
                  Icons.place_outlined,
                  size: 12.0,
                  color: RecallrColors.textTertiary,
                ),
                const SizedBox(width: 3.0),
                Expanded(
                  child: Text(
                    source.eventOrLocation!,
                    style: RecallrTypography.bodyMedium.copyWith(
                      color: RecallrColors.textTertiary,
                      fontSize: 11.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  '•',
                  style: RecallrTypography.monoMetadata.copyWith(
                    color: RecallrColors.textTertiary,
                    fontSize: 10.0,
                  ),
                ),
                const SizedBox(width: 6.0),
              ],
              Text(
                source.date,
                style: RecallrTypography.monoMetadata.copyWith(
                  color: RecallrColors.textTertiary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          RecallrSpacing.gapSm,

          // Excerpt Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: RecallrColors.slateSurface,
              borderRadius: RecallrRadii.radiusSm,
              border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
            ),
            child: Text(
              '"${source.excerpt}"',
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textPrimary,
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}