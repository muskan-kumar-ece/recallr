import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../services/auth_service.dart';
import '../../core/routing/deep_link_manager.dart';
import '../../core/routing/recallr_routes.dart';

/// Production-ready Settings & Preferences Screen matching new Recallr specifications.
class SettingsScreen extends StatefulWidget {
  final AuthService? authService;

  const SettingsScreen({super.key, this.authService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AuthService? _authService;
  bool _offlineCacheEnabled = true;
  bool _aiGroundingStrict = true;

  AuthService get _effectiveAuthService => widget.authService ?? (_authService ??= AuthService());

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    final email = user?.email ?? 'Not Signed In';
    final displayName = user?.displayName ?? 'Professional';

    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: RecallrColors.obsidianBase,
        surfaceTintColor: Colors.transparent,
        title: const Text('Settings & Preferences'),
        leading: RecallrIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              children: [
                // ── User Profile Card ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: RecallrColors.charcoalCard,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: RecallrColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      RecallrAvatar(
                        initials: displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
                        imageUrl: user?.photoURL,
                        size: RecallrAvatarSize.lg,
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: RecallrTypography.headlineMedium.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const RecallrBadge(
                        text: 'ACTIVE',
                        variant: RecallrBadgeVariant.verified,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),

                // ── 5 Core Management Tiles (from Sketch) ─────────────────────
                const Text(
                  'PREFERENCES & MANAGEMENT',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: RecallrColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 10.0),
                _buildManagementTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile Details',
                  subtitle: 'Manage bio, digital card and contact info',
                  onTap: () => _showVisitingCardSheet(context, displayName, email),
                ),
                const SizedBox(height: 8.0),
                _buildManagementTile(
                  icon: Icons.hub_outlined,
                  title: 'Manage Network',
                  subtitle: 'Tags, circles, relationship thresholds and categories',
                  onTap: () => Navigator.of(context).pushNamed(RecallrRoutes.people),
                ),
                const SizedBox(height: 8.0),
                _buildManagementTile(
                  icon: Icons.qr_code_2_rounded,
                  title: 'QR Bio / My Card',
                  subtitle: 'Instant contact sharing QR and public handle',
                  onTap: () => _showQrBioSheet(context, displayName, email),
                ),
                const SizedBox(height: 8.0),
                _buildManagementTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Reminders & Follow-ups',
                  subtitle: 'Commitment tracking schedules and alerts',
                  onTap: () => Navigator.of(context).pushNamed(RecallrRoutes.followUps),
                ),
                const SizedBox(height: 8.0),
                _buildManagementTile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Subscription & Storage',
                  subtitle: 'AI credits, plan upgrades and media capacity',
                  onTap: () => Navigator.of(context).pushNamed(RecallrRoutes.subscription),
                ),
                const SizedBox(height: 24.0),

                // ── AI & Grounding Controls ──────────────────────────────────
                const Text(
                  'AI & Grounding Controls',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: RecallrColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10.0),
                Material(
                  color: RecallrColors.charcoalCard,
                  borderRadius: BorderRadius.circular(14.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: RecallrColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Strict Grounding Mode', style: RecallrTypography.bodyLarge),
                          subtitle: Text(
                            'Only return facts cited directly from verified memory claims.',
                            style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                          ),
                          value: _aiGroundingStrict,
                          activeThumbColor: RecallrColors.aiElectricViolet,
                          onChanged: (val) {
                            setState(() => _aiGroundingStrict = val);
                          },
                        ),
                        const Divider(color: RecallrColors.borderSubtle, height: 1),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Local Offline Persistence', style: RecallrTypography.bodyLarge),
                          subtitle: Text(
                            'Cache recent people, activities, and relationship scores on device.',
                            style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                          ),
                          value: _offlineCacheEnabled,
                          activeThumbColor: RecallrColors.aiElectricViolet,
                          onChanged: (val) {
                            setState(() => _offlineCacheEnabled = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // ── Security & Multi-Tenancy ──────────────────────────────────
                const Text(
                  'Security & Storage',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: RecallrColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: RecallrColors.charcoalCard,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: RecallrColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 20, color: RecallrColors.emeraldVerified),
                          const SizedBox(width: 8.0),
                          const Text('Tenant Isolation & App Check', style: RecallrTypography.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Your data is protected by strict Firebase Security Rules isolated to your authenticated UID (${user?.uid ?? "Anonymous"}).',
                        style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28.0),

                // ── Sign Out Button ───────────────────────────────────────────
                RecallrButton(
                  label: 'Sign Out',
                  leadingIcon: Icons.logout_rounded,
                  variant: RecallrButtonVariant.secondary,
                  onPressed: () async {
                    DeepLinkManager().consumePendingPath();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    await _effectiveAuthService.signOut();
                  },
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: Text(
                    'Recallr v1.0.0 — Unified Relationship Intelligence',
                    style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.textTertiary),
                  ),
                ),
                const SizedBox(height: 80.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManagementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: RecallrColors.charcoalCard,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: RecallrColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: RecallrColors.aiElectricViolet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: RecallrColors.aiElectricViolet, size: 18),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: RecallrColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: RecallrColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14.0, color: RecallrColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showQrBioSheet(BuildContext context, String name, String email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RecallrColors.slateSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: RecallrColors.borderHighlight, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Your Recallr QR Identity', style: RecallrTypography.headlineMedium),
            const SizedBox(height: 8),
            Text('Scan to connect and exchange verified contact info with $name', style: RecallrTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(email, style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textSecondary)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showVisitingCardSheet(BuildContext context, String name, String email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RecallrColors.slateSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: RecallrColors.borderHighlight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Digital Visiting Card', style: RecallrTypography.headlineMedium),
            const SizedBox(height: 6),
            const Text('Your shareable professional network card preview.', style: RecallrTypography.bodyMedium),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF2E1065)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Icon(Icons.contactless_rounded, color: RecallrColors.aiElectricViolet),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Member · Verified Network', style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 12)),
                  const SizedBox(height: 20),
                  Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
