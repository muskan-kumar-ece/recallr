import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_radii.dart';

/// Animated skeleton placeholder loader for text, cards, and avatars.
class RecallrSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const RecallrSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  @override
  State<RecallrSkeleton> createState() => _RecallrSkeletonState();
}

class _RecallrSkeletonState extends State<RecallrSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: RecallrColors.charcoalCard,
          borderRadius: widget.borderRadius ?? RecallrRadii.radiusMd,
        ),
      );
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.75).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: RecallrColors.charcoalCard,
          borderRadius: widget.borderRadius ?? RecallrRadii.radiusMd,
          border: Border.all(color: RecallrColors.borderSubtle, width: 0.5),
        ),
      ),
    );
  }
}