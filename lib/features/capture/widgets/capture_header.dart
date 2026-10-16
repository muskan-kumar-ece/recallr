import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/capture_models.dart';

/// Editorial Header for Omni-Capture Hub.
class CaptureHeader extends StatelessWidget {
  final CaptureState state;
  final CaptureType? activeType;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  const CaptureHeader({
    super.key,
    required this.state,
    this.activeType,
    this.onBack,
    this.onClose,
  });

  String get _title {
    if (state == CaptureState.idle) {
      return 'Omni-Capture Hub';
    }
    if (state == CaptureState.saved) {
      return 'Memory Saved';
    }
    if (activeType != null) {
      return activeType!.label;
    }
    return 'Capture Memory';
  }

  String get _subtitle {
    if (state == CaptureState.idle) {
      return 'Add encounters, visiting cards, and conversations to your professional memory.';
    }
    if (state == CaptureState.review) {
      return 'Review what Recallr will remember before saving.';
    }
    if (state == CaptureState.saved) {
      return 'Recallr will now remember this context across all relationships.';
    }
    if (activeType != null) {
      return activeType!.description;
    }
    return 'Grounded personal network memory capture.';
  }

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = state != CaptureState.idle && state != CaptureState.saved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (canGoBack)
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: RecallrColors.textSecondary, size: 20.0),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
                tooltip: 'Back to capture options',
              ),
            Expanded(
              child: Text(
                _title,
                style: RecallrTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  fontSize: 20.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, color: RecallrColors.textTertiary, size: 20.0),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
                tooltip: 'Close modal',
              ),
          ],
        ),
        RecallrSpacing.gapXs,
        Text(
          _subtitle,
          style: RecallrTypography.bodyMedium.copyWith(
            color: RecallrColors.textSecondary,
            fontSize: 13.0,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}