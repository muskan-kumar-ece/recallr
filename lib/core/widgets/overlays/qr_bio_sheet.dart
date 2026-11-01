import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';
import '../buttons/recallr_button.dart';

/// Modal bottom sheet for displaying user QR Identity and quick QR scanner actions.
class QrBioSheet extends StatefulWidget {
  final String name;
  final String email;

  const QrBioSheet({
    super.key,
    required this.name,
    required this.email,
  });

  /// Displays the QR Bio Sheet.
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

  @override
  State<QrBioSheet> createState() => _QrBioSheetState();
}

class _QrBioSheetState extends State<QrBioSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyIdentityLink() {
    final link = 'https://recallr.app/u/${widget.email.split('@').first}';
    Clipboard.setData(ClipboardData(text: link));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Identity link copied: $link'),
        backgroundColor: RecallrColors.slateSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
            TabBar(
              controller: _tabController,
              indicatorColor: RecallrColors.aiElectricViolet,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: RecallrColors.textPrimary,
              unselectedLabelColor: RecallrColors.textSecondary,
              labelStyle: RecallrTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.qr_code_2_rounded, size: 20), text: 'My QR Card'),
                Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 20), text: 'Scan QR'),
              ],
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 320.0,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: My QR Card
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Your Recallr QR Identity',
                        style: RecallrTypography.headlineMedium,
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Scan to connect and exchange verified contact info with ${widget.name}',
                        style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16.0),
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
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 110.0,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        widget.email,
                        style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textSecondary),
                      ),
                      const SizedBox(height: 12.0),
                      TextButton.icon(
                        onPressed: _copyIdentityLink,
                        icon: const Icon(Icons.copy_rounded, size: 16.0, color: RecallrColors.aiCyanHighlight),
                        label: const Text(
                          'Copy Profile Link',
                          style: TextStyle(color: RecallrColors.aiCyanHighlight, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  // Tab 2: Scan QR Viewfinder
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Scan Recallr Contact QR',
                        style: RecallrTypography.headlineMedium,
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Point camera at another user\'s Recallr QR code to import and link memory.',
                        style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20.0),
                      Container(
                        width: 150.0,
                        height: 150.0,
                        decoration: BoxDecoration(
                          color: RecallrColors.charcoalCard,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: RecallrColors.aiElectricViolet, width: 2.0),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 48.0,
                            color: RecallrColors.aiElectricViolet,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      RecallrButton(
                        label: 'Simulate Verified Scan',
                        variant: RecallrButtonVariant.secondary,
                        leadingIcon: Icons.document_scanner_rounded,
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Scanned contact verified: Priya Sharma (Microsoft)'),
                              backgroundColor: RecallrColors.slateSurface,
                            ),
                          );
                        },
                      ),
                    ],
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
