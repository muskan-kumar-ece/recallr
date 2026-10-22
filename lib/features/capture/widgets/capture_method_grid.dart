import 'package:flutter/material.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 540;

        if (isWide) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: CaptureType.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 74.0,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            itemBuilder: (context, index) {
              final type = CaptureType.values[index];
              return CaptureMethodCard(
                type: type,
                onTap: () => onSelectType(type),
              );
            },
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: CaptureType.values.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8.0),
          itemBuilder: (context, index) {
            final type = CaptureType.values[index];
            return CaptureMethodCard(
              type: type,
              onTap: () => onSelectType(type),
            );
          },
        );
      },
    );
  }
}