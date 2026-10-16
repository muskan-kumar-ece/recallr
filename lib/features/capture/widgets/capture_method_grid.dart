import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/capture_models.dart';
import 'capture_method_card.dart';

/// Grid of available multi-modal capture options.
class CaptureMethodGrid extends StatelessWidget {
  final ValueChanged<CaptureType> onSelectType;

  const CaptureMethodGrid({
    super.key,
    required this.onSelectType,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: CaptureType.values.length,
      separatorBuilder: (_, __) => RecallrSpacing.gapSm,
      itemBuilder: (context, index) {
        final type = CaptureType.values[index];
        return CaptureMethodCard(
          type: type,
          onTap: () => onSelectType(type),
        );
      },
    );
  }
}