import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';
import '../buttons/recallr_button.dart';

/// Modal bottom sheet for viewing and sharing the Digital Visiting Card.
class VisitingCardSheet extends StatelessWidget {
  final String name;
  final String email;
  final String? company;
  final String? title;

  const VisitingCardSheet({
    super.key,
    required this.name,
    required this.email,
    this.company,
    this.title,
  });

  /// Displays the Digital Visiting Card preview sheet.
  static Future<void> show(
    BuildContext context, {
    required String name,
    required String email,
    String? company,
    String? title,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: RecallrColors.slateSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => VisitingCardSheet(
        name: name,
        email: email,
        company: company,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardText = [
      name.isNotEmpty ? name : 'Professional',
      if (title != null && title!.isNotEmpty) title!,
      if (company != null && company!.isNotEmpty) company!,
      email,
    ].join('\n');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: RecallrColors.borderHighlight,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            const SizedBox(height: 16.0),
            Text('Digital Visiting Card', style: RecallrTypography.headlineMedium),
            const SizedBox(height: 4.0),
            Text(
              'Your shareable professional network card preview.',
              style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
            ),
            const SizedBox(height: 20.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [RecallrColors.charcoalCard, RecallrColors.slateSurface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: RecallrColors.aiElectricViolet.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: RecallrColors.aiElectricViolet.withValues(alpha: 0.15),
                    blurRadius: 20.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: RecallrColors.emeraldVerified.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14.0, color: RecallrColors.emeraldVerified),
                            const SizedBox(width: 4.0),
                            Text(
                              'Verified Member',
                              style: RecallrTypography.labelSmall.copyWith(
                                color: RecallrColors.emeraldVerified,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.nfc_rounded, size: 24.0, color: RecallrColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    name.isNotEmpty ? name : 'Professional',
                    style: RecallrTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    title?.isNotEmpty == true ? title! : 'Add your role',
                    style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.aiCyanHighlight),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16.0, color: RecallrColors.textSecondary),
                      const SizedBox(width: 8.0),
                      Text(email, style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
                    ],
                  ),
                  if (company != null) ...[
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        const Icon(Icons.business_outlined, size: 16.0, color: RecallrColors.textSecondary),
                        const SizedBox(width: 8.0),
                        Text(company!, style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              child: RecallrButton(
                label: 'Copy Card Details',
                variant: RecallrButtonVariant.primary,
                leadingIcon: Icons.copy_rounded,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cardText));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Card details copied to clipboard'),
                      backgroundColor: RecallrColors.slateSurface,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
