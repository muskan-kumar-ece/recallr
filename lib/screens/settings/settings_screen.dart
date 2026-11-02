import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../services/auth_service.dart';
import '../../core/routing/deep_link_manager.dart';
import '../../core/routing/recallr_routes.dart';
import '../../app/app_shell.dart';
import '../../core/state/recallr_credit_balance.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted)
        setState(() =>
            _offlineCacheEnabled = prefs.getBool('offlinePersistence') ?? true);
    });
  }

  AuthService get _effectiveAuthService =>
      widget.authService ?? (_authService ??= AuthService());

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('Settings & Preferences'),
        leading: RecallrIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              RecallrAppShellScope.openTab(context, 0);
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
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
                        initials: displayName.isNotEmpty
                            ? displayName.substring(0, 1).toUpperCase()
                            : 'U',
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
                              style: RecallrTypography.headlineMedium
                                  .copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: RecallrTypography.bodyMedium
                                  .copyWith(color: RecallrColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),

                _buildAppearanceSection(),
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
                  icon: Icons.badge_outlined,
                  title: 'My Visiting Card',
                  subtitle: 'Manage your bio, contact details, and public card',
                  onTap: () => Navigator.of(context).pushNamed('/my-card'),
                ),
                const SizedBox(height: 8.0),
                _buildManagementTile(
                  icon: Icons.folder_outlined,
                  title: 'Categories',
                  subtitle: 'Organize saved contacts, memories, and follow-ups',
                  onTap: () => Navigator.of(context).pushNamed('/categories'),
                ),
                const SizedBox(height: 8.0),
                _buildManagementTile(
                    icon: Icons.qr_code_scanner,
                    title: 'Scan a Visiting Card',
                    subtitle:
                        'Scan a QR code and save the person to your network',
                    onTap: () => Navigator.of(context).pushNamed('/scan-card')),
                const SizedBox(height: 8.0),
                _buildManagementTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Reminders & Follow-ups',
                  subtitle: 'Commitment tracking schedules and alerts',
                  onTap: () =>
                      Navigator.of(context).pushNamed(RecallrRoutes.followUps),
                ),
                const SizedBox(height: 8.0),
                _buildManagementTile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Subscription & Storage',
                  subtitle: 'AI credits, plan upgrades and media capacity',
                  onTap: () => Navigator.of(context)
                      .pushNamed(RecallrRoutes.subscription),
                ),
                const SizedBox(height: 24.0),

                // ── Local data preference ───────────────────────────────────
                _buildOfflinePersistenceTile(),
                const SizedBox(height: 24.0),

                // ── Sign Out Button ───────────────────────────────────────────
                RecallrButton(
                  label: 'Sign Out',
                  leadingIcon: Icons.logout_rounded,
                  variant: RecallrButtonVariant.secondary,
                  onPressed: () async {
                    DeepLinkManager().consumePendingPath();
                    RecallrCreditBalance.clear();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    await _effectiveAuthService.signOut();
                  },
                ),
                const SizedBox(height: 16.0),
                const SizedBox(height: 80.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: RecallrThemeModeController.mode,
      builder: (context, selectedMode, _) {
        final colors = context.colors;
        return Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: colors.charcoalCard,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: RecallrTypography.titleMedium.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Choose how Recallr looks on this device.',
                style: RecallrTypography.bodyMedium
                    .copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 10.0),
              SegmentedButton<ThemeMode>(
                key: const ValueKey<String>('theme_mode_selector'),
                segments: const [
                  ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('System')),
                  ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light')),
                  ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark')),
                ],
                selected: {selectedMode},
                onSelectionChanged: (selection) {
                  RecallrThemeModeController.setMode(selection.first);
                },
                showSelectedIcon: false,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflinePersistenceTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: RecallrColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Local Offline Persistence',
              style: RecallrTypography.bodyLarge),
          subtitle: Text(
            'Cache recent data on this device. Restart the app after changing this setting.',
            style: RecallrTypography.bodyMedium
                .copyWith(color: RecallrColors.textSecondary),
          ),
          value: _offlineCacheEnabled,
          activeThumbColor: RecallrColors.aiElectricViolet,
          onChanged: (value) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('offlinePersistence', value);
            if (!mounted) return;
            setState(() => _offlineCacheEnabled = value);
          },
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
              child:
                  Icon(icon, color: RecallrColors.aiElectricViolet, size: 18),
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
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14.0, color: RecallrColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
