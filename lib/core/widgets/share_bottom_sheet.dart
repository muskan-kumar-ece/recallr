import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

/// Modal bottom sheet providing multi-format sharing actions
/// (Formatted Markdown text, vCard 3.0, and Clipboard copy).
class ShareBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String textSummary;
  final String? vCardContent;
  final String? shareSubject;

  const ShareBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.textSummary,
    this.vCardContent,
    this.shareSubject,
  });

  /// Displays the share sheet modal.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String textSummary,
    String? vCardContent,
    String? shareSubject,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ShareBottomSheet(
        title: title,
        subtitle: subtitle,
        textSummary: textSummary,
        vCardContent: vCardContent,
        shareSubject: shareSubject,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String successMessage) {
    Clipboard.setData(ClipboardData(text: text));
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: RecallrColors.slateSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusSm,
          side: const BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: RecallrColors.emeraldVerified,
              size: 18.0,
            ),
            const SizedBox(width: RecallrSpacing.sm),
            Expanded(
              child: Text(
                successMessage,
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textPrimary,
                  fontSize: 13.0,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVCard = vCardContent != null && vCardContent!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: RecallrColors.slateSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      padding: const EdgeInsets.fromLTRB(
        RecallrSpacing.lg,
        RecallrSpacing.md,
        RecallrSpacing.lg,
        RecallrSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle Pill
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: RecallrColors.borderHighlight,
                  borderRadius: RecallrRadii.radiusPill,
                ),
              ),
            ),
            const SizedBox(height: RecallrSpacing.md),

            // Header
            Row(
              children: [
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: RecallrColors.aiElectricViolet.withAlpha(25),
                    borderRadius: RecallrRadii.radiusSm,
                    border: Border.all(
                      color: RecallrColors.aiElectricViolet.withAlpha(50),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: RecallrColors.aiElectricViolet,
                    size: 18.0,
                  ),
                ),
                const SizedBox(width: RecallrSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: RecallrTypography.titleMedium.copyWith(
                          color: RecallrColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: RecallrTypography.bodyMedium.copyWith(fontSize: 12.0).copyWith(
                          color: RecallrColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20.0),
                  color: RecallrColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: RecallrSpacing.lg),

            // Option 1: Copy Formatted Summary
            _ShareOptionTile(
              icon: Icons.copy_rounded,
              title: 'Copy Formatted Summary',
              description: 'Readable text with key takeaways, perfect for messaging or email',
              onTap: () => _copyToClipboard(
                context,
                textSummary,
                'Summary copied to clipboard',
              ),
            ),
            const SizedBox(height: RecallrSpacing.sm),

            // Option 2: Copy vCard Contact (if available)
            if (hasVCard) ...[
              _ShareOptionTile(
                icon: Icons.contact_page_outlined,
                title: 'Copy vCard Contact (.vcf)',
                description: 'Standard contact card ready to paste into Contacts or Outlook',
                onTap: () => _copyToClipboard(
                  context,
                  vCardContent!,
                  'vCard contact copied to clipboard',
                ),
              ),
              const SizedBox(height: RecallrSpacing.sm),
            ],

            // Preview Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(RecallrSpacing.md),
              decoration: BoxDecoration(
                color: RecallrColors.charcoalCard,
                borderRadius: RecallrRadii.radiusSm,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: RecallrTypography.labelSmall.copyWith(
                      color: RecallrColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: RecallrSpacing.xs),
                  Text(
                    textSummary,
                    style: RecallrTypography.bodyMedium.copyWith(fontSize: 12.0).copyWith(
                      color: RecallrColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: RecallrRadii.radiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: RecallrSpacing.md,
          vertical: RecallrSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: RecallrColors.charcoalCard,
          borderRadius: RecallrRadii.radiusMd,
          border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: RecallrColors.slateSurface,
                borderRadius: RecallrRadii.radiusSm,
              ),
              child: Icon(icon, color: RecallrColors.textPrimary, size: 18.0),
            ),
            const SizedBox(width: RecallrSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: RecallrTypography.bodyMedium.copyWith(
                      color: RecallrColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: RecallrTypography.bodyMedium.copyWith(fontSize: 12.0).copyWith(
                      color: RecallrColors.textSecondary,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: RecallrColors.textTertiary,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}
