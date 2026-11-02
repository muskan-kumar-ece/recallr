import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/ask_models.dart';
import 'source_memory_card.dart';

/// Sources & Evidence Section for Grounded Answer.
class MemorySourcesSection extends StatefulWidget {
  final List<MemorySource> sources;

  const MemorySourcesSection({super.key, required this.sources});

  @override
  State<MemorySourcesSection> createState() => _MemorySourcesSectionState();
}

class _MemorySourcesSectionState extends State<MemorySourcesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.sources.isEmpty) return const SizedBox.shrink();
    final visibleSources =
        _expanded ? widget.sources : widget.sources.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.account_tree_outlined,
                    size: 16.0,
                    color: RecallrColors.emeraldVerified,
                  ),
                  RecallrSpacing.gapXs,
                  Expanded(
                    child: Text(
                      'Source Memories & Evidence',
                      style: RecallrTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            RecallrSpacing.gapSm,
            Text(
              '${widget.sources.length} ${widget.sources.length == 1 ? 'source' : 'sources'}',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        RecallrSpacing.gapSm,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleSources.length,
          separatorBuilder: (context, index) => RecallrSpacing.gapSm,
          itemBuilder: (context, index) {
            return SourceMemoryCard(source: visibleSources[index]);
          },
        ),
        if (widget.sources.length > 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16),
              label:
                  Text(_expanded ? 'Show fewer sources' : 'Show all sources'),
            ),
          ),
      ],
    );
  }
}
