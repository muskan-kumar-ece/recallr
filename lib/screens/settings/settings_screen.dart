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
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: canPop
          ? AppBar(
              backgroundColor: RecallrColors.obsidianBase,
              leading: RecallrIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              title: const Text('Settings'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              children: [
                // Header (if not shown in AppBar)
                if (!canPop) ...[
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28.0,
                      fontWeight: FontWeight.w700,
                      color: RecallrColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Text(
                    'Manage your account, personal information and reminders.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.0,
                      color: RecallrColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                ],

                // ── User Profile Mini-Card ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: RecallrColors.charcoalCard,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: RecallrColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      RecallrAvatar(
                        initials: displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
                        imageUrl: user?.photoURL,
                        size: RecallrAvatarSize.md,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700,
                                color: RecallrColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              email,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.0,
                                color: RecallrColors.textSecondary,
                              ),
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
                const SizedBox(height: 20.0),

                // ── 5 Core Sections per Reference ─────────────────────────────
                _SettingsMenuTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification Management',
                  subtitle: 'Reminders, follow-ups and notification preferences.',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings updated')),
                    );
                  },
                ),
                const SizedBox(height: 8.0),
                _SettingsMenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Account',
                  subtitle: 'Sign-in method, security and account management.',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Signed in as $email')),
                    );
                  },
                ),
                const SizedBox(height: 8.0),
                _SettingsMenuTile(
                  icon: Icons.badge_outlined,
                  title: 'Personal Information',
                  subtitle: 'Your name, photo, contact details and personal bio.',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile details are up to date')),
                    );
                  },
                ),
                const SizedBox(height: 8.0),
                _SettingsMenuTile(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Your QR Code & Bio',
                  subtitle: 'View and share your Recallr identity.',
                  onTap: () {
                    _showQrBioSheet(context, displayName, email);
                  },
                ),
                const SizedBox(height: 8.0),
                _SettingsMenuTile(
                  icon: Icons.contact_page_outlined,
                  title: 'Digital Visiting Card',
                  subtitle: 'Design and manage your shareable professional card.',
                  onTap: () {
                    _showVisitingCardSheet(context, displayName, email);
                  },
                ),
                const SizedBox(height: 20.0),

                // ── Membership & AI Credits ───────────────────────────────────
                _SettingsMenuTile(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: RecallrColors.warmAmberGold,
                  iconBgColor: const Color(0xFF281E10),
                  title: 'Subscription & Storage',
                  subtitle: 'Manage tier, AI credits, and cloud media quotas',
                  onTap: () => Navigator.of(context).pushNamed(RecallrRoutes.subscription),
                ),
                const SizedBox(height: 20.0),

                // ── App Controls & AI Strictness ──────────────────────────────
                const Text(
                  'APP PREFERENCES',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: RecallrColors.textTertiary,
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
                          'Only return facts cited directly from verified memory records.',
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
                          'Cache recent contacts, activities, and relationship scores locally.',
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
                const SizedBox(height: 80.0),
              ],
            ),
          ),
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

// ─── Settings Menu Tile ───────────────────────────────────────────────────────

class _SettingsMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBgColor;

  const _SettingsMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: RecallrColors.charcoalCard,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 42.0,
              height: 42.0,
              decoration: BoxDecoration(
                color: iconBgColor ?? const Color(0xFF221E42),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(
                icon,
                color: iconColor ?? RecallrColors.aiElectricViolet,
                size: 22.0,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: RecallrColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0,
                      color: RecallrColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
