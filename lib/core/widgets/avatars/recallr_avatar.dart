import 'package:flutter/material.dart';
import '../../theme/recallr_colors.dart';
import '../../theme/recallr_typography.dart';

enum RecallrAvatarSize { sm, md, lg, xl }

/// Reusable Avatar with gradient initials fallback and network image support.
class RecallrAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final RecallrAvatarSize size;
  final bool showBorder;

  const RecallrAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = RecallrAvatarSize.md,
    this.showBorder = true,
  });

  double get _dimension {
    switch (size) {
      case RecallrAvatarSize.sm:
        return 28.0;
      case RecallrAvatarSize.md:
        return 40.0;
      case RecallrAvatarSize.lg:
        return 56.0;
      case RecallrAvatarSize.xl:
        return 72.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = _dimension;

    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl == null
            ? const LinearGradient(
                colors: [RecallrColors.charcoalCard, RecallrColors.slateSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: showBorder
            ? Border.all(color: RecallrColors.borderSubtle, width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: dim,
                height: dim,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(dim),
              ),
            )
          : _buildInitials(dim),
    );
  }

  Widget _buildInitials(double dim) {
    return Text(
      initials.toUpperCase(),
      style: RecallrTypography.titleMedium.copyWith(
        fontSize: dim * 0.38,
        fontWeight: FontWeight.w600,
        color: RecallrColors.textPrimary,
      ),
    );
  }
}