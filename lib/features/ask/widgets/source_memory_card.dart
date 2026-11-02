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
    final personLine = [source.personName, source.personRole, source.company]
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');
    return RecallrCard(
      onTap: source.targetRoute != null
          ? () => Navigator.of(context).pushNamed(source.targetRoute!)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
              Text(
                source.date,
                style: RecallrTypography.monoMetadata.copyWith(
                  color: RecallrColors.textTertiary,
                  fontSize: 10.5,
                ),
              ),
              if (source.isVerified) ...[
                const SizedBox(width: 6.0),
                const RecallrBadge(
                  text: 'VERIFIED',
                  variant: RecallrBadgeVariant.verified,
                ),
              ],
            ],
          ),
          RecallrSpacing.gapSm,
          Text(
            personLine.isEmpty ? 'Memory source' : personLine,
            style: RecallrTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          if (source.eventOrLocation?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 2.0),
            Text(
              source.eventOrLocation!,
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6.0),
          Text(
            source.excerpt,
            style: RecallrTypography.bodyMedium.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 12.0,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
