import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/theme.dart';
import '../buttons/recallr_button.dart';

/// Modal for displaying a real, scannable Recallr identity QR code.
class QrBioSheet extends StatelessWidget {
  final String name;
  final String email;

  const QrBioSheet({
    super.key,
    required this.name,
    required this.email,
  });

  static Future<void> show(
    BuildContext context, {
    required String name,
    required String email,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: RecallrColors.slateSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => QrBioSheet(name: name, email: email),
    );
  }

  String get _identityLink => 'https://recallr.app/u/${email.split('@').first}';

  void _copyIdentityLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _identityLink));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Identity link copied to clipboard'),
        backgroundColor: RecallrColors.slateSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: RecallrRadii.radiusSm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
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
            Text('Your Recallr QR Identity', style: RecallrTypography.headlineMedium),
            const SizedBox(height: 6.0),
            Text(
              'Scan this code to open your Recallr profile link.',
              style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18.0),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: RecallrColors.aiElectricViolet.withValues(alpha: 0.2),
                    blurRadius: 16.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _identityLink,
                size: 180.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
              ),
            ),
            const SizedBox(height: 14.0),
            Text(
              name.isNotEmpty ? name : 'Professional',
              style: RecallrTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2.0),
            Text(email, style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textSecondary)),
            const SizedBox(height: 14.0),
            SizedBox(
              width: double.infinity,
              child: RecallrButton(
                label: 'Copy Profile Link',
                variant: RecallrButtonVariant.secondary,
                leadingIcon: Icons.copy_rounded,
                onPressed: () => _copyIdentityLink(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
