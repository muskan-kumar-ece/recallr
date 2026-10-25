import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../services/auth_service.dart';
import '../../core/routing/deep_link_manager.dart';

/// Production-ready Settings & Preferences Screen.
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
        title: const Text('Settings & Preferences'),
        leading: RecallrIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: RecallrSpacing.pagePadding,
            children: [
              // User Account Card
              RecallrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RecallrAvatar(
                          initials: displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
                          imageUrl: user?.photoURL,
                          size: RecallrAvatarSize.lg,
                        ),
                        RecallrSpacing.gapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: RecallrTypography.headlineMedium),
                              Text(email, style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
                            ],
                          ),
                        ),
                        const RecallrBadge(
                          text: 'ACTIVE',
                          variant: RecallrBadgeVariant.verified,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              RecallrSpacing.gapLg,

              // Membership & Resource Quotas
              Text('Membership & Cloud Usage', style: RecallrTypography.titleMedium),
              RecallrSpacing.gapSm,
              RecallrCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: RecallrColors.aiElectricViolet.withAlpha(35),
                      borderRadius: RecallrRadii.radiusMd,
                      border: Border.all(color: RecallrColors.aiElectricViolet.withAlpha(80)),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: RecallrColors.aiElectricViolet, size: 22),
                  ),
                  title: Text('Subscription & Storage', style: RecallrTypography.titleMedium),
                  subtitle: Text(
                    'Manage tier, AI credits, and cloud media quotas',
                    style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: RecallrColors.textSecondary),
                  onTap: () => Navigator.of(context).pushNamed('/subscription'),
                ),
              ),
              RecallrSpacing.gapLg,

              // AI & Intelligence Settings
              Text('AI & Grounding Controls', style: RecallrTypography.titleMedium),
              RecallrSpacing.gapSm,
              RecallrCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Strict Grounding Mode', style: RecallrTypography.bodyLarge),
                      subtitle: Text('Only return facts cited directly from verified encounters and memory claims.', style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
                      value: _aiGroundingStrict,
                      activeThumbColor: RecallrColors.aiElectricViolet,
                      onChanged: (val) {
                        setState(() => _aiGroundingStrict = val);
                      },
                    ),
                    const Divider(color: RecallrColors.borderSubtle, height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Local Offline Persistence', style: RecallrTypography.bodyLarge),
                      subtitle: Text('Cache recent people, activities, and relationship scores on device.', style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
                      value: _offlineCacheEnabled,
                      activeThumbColor: RecallrColors.aiElectricViolet,
                      onChanged: (val) {
                        setState(() => _offlineCacheEnabled = val);
                      },
                    ),
                  ],
                ),
              ),
              RecallrSpacing.gapLg,

              // Security & Multi-Tenancy
              Text('Security & Storage', style: RecallrTypography.titleMedium),
              RecallrSpacing.gapSm,
              RecallrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 20, color: RecallrColors.emeraldVerified),
                        RecallrSpacing.gapSm,
                        Text('Tenant Isolation & App Check', style: RecallrTypography.titleMedium),
                      ],
                    ),
                    RecallrSpacing.gapSm,
                    Text(
                      'Your data is protected by strict Firebase Security Rules isolated to your authenticated UID (${user?.uid ?? "Anonymous"}).',
                      style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                    ),
                  ],
                ),
              ),
              RecallrSpacing.gapXl,

              // Sign Out Action
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
              RecallrSpacing.gapLg,
              Center(
                child: Text(
                  'Recallr v1.0.0 — Unified Relationship Intelligence',
                  style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
