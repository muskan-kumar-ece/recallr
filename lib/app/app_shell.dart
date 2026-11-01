import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../core/widgets/widgets.dart';
import '../screens/ask/ask_screen.dart';
import '../screens/capture/capture_modal.dart';
import '../screens/home/home_screen.dart';
import '../screens/people/people_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../services/auth_service.dart';
import '../core/routing/deep_link_manager.dart';
import '../core/routing/recallr_routes.dart';
import '../core/di/recallr_dependencies.dart';
import '../features/subscription/models/subscription_models.dart';

/// Responsive Breakpoint constants
const double kTabletBreakpoint = 600.0;
const double kDesktopBreakpoint = 1024.0;

/// Navigation destination model
class _NavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/// InheritedWidget providing child widgets access to shell tab switching
/// without pushing duplicate nested RecallrAppShell instances onto the Navigator.
class RecallrAppShellScope extends InheritedWidget {
  final int selectedIndex;
  final void Function(int index, {String? askQuery}) selectTab;

  const RecallrAppShellScope({
    super.key,
    required this.selectedIndex,
    required this.selectTab,
    required super.child,
  });

  static RecallrAppShellScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RecallrAppShellScope>();
  }

  static void openTab(BuildContext context, int index, {String? askQuery}) {
    final scope = of(context);
    if (scope != null) {
      scope.selectTab(index, askQuery: askQuery);
      return;
    }
    if (RecallrAppShell.selectTab(context, index, askQuery: askQuery)) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    // Fallback if not inside an active shell (e.g. standalone test harness)
    final routeNames = [
      RecallrRoutes.home,
      RecallrRoutes.people,
      RecallrRoutes.ask,
    ];
    if (index >= 0 && index < routeNames.length) {
      Navigator.of(context).pushNamed(routeNames[index], arguments: askQuery);
    }
  }

  @override
  bool updateShouldNotify(RecallrAppShellScope oldWidget) {
    return selectedIndex != oldWidget.selectedIndex;
  }
}

/// The permanent, authenticated Recallr Application Shell.
class RecallrAppShell extends StatefulWidget {
  final User? user;
  final int initialIndex;
  final bool autoOpenCapture;
  final String? initialAskQuery;

  const RecallrAppShell({
    super.key,
    this.user,
    this.initialIndex = 0,
    this.autoOpenCapture = false,
    this.initialAskQuery,
  });

  static _RecallrAppShellState? _activeShell;

  /// Helper to safely select a tab from any descendant widget within RecallrAppShell.
  static bool selectTab(BuildContext context, int index, {String? askQuery}) {
    final scope = RecallrAppShellScope.of(context);
    if (scope != null) {
      scope.selectTab(index, askQuery: askQuery);
      return true;
    }
    if (_activeShell != null) {
      _activeShell!.selectTab(index, askQuery: askQuery);
      return true;
    }
    return false;
  }

  @override
  State<RecallrAppShell> createState() => _RecallrAppShellState();
}

class _RecallrAppShellState extends State<RecallrAppShell> {
  /// Page index into _pages list (0=Home, 1=People, 2=Ask, 3=Settings)
  late int _selectedIndex;
  String? _askQuery;
  final AuthService _authService = AuthService();
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    RecallrAppShell._activeShell = this;
    _selectedIndex = widget.initialIndex;
    _askQuery = widget.initialAskQuery;
    _initPages();
    if (widget.autoOpenCapture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openQuickCapture();
        }
      });
    }
  }

  @override
  void dispose() {
    if (RecallrAppShell._activeShell == this) {
      RecallrAppShell._activeShell = null;
    }
    super.dispose();
  }

  void _initPages() {
    _pages = [
      HomeScreen(userName: widget.user?.displayName ?? widget.user?.email ?? 'Professional'),
      const PeopleScreen(),
      AskScreen(key: ValueKey('ask_${_askQuery ?? widget.initialAskQuery}'), initialQuery: _askQuery ?? widget.initialAskQuery),
      const SettingsScreen(),
    ];
  }

  @override
  void didUpdateWidget(covariant RecallrAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user ||
        oldWidget.initialAskQuery != widget.initialAskQuery) {
      _askQuery = widget.initialAskQuery;
      _initPages();
    }
  }

  /// Nav destinations for display — 4 real destinations (+ button is handled separately).
  static const List<_NavDestination> _destinations = [
    _NavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavDestination(
      label: 'People',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
    ),
    _NavDestination(
      label: 'Search',
      icon: Icons.search_rounded,
      selectedIcon: Icons.saved_search_rounded,
    ),
    _NavDestination(
      label: 'More',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
  ];

  /// Public API: external callers use logical indices:
  ///   0 = Home, 1 = People, 2 = Ask (page index 2), 3 = Settings (page index 3)
  /// The + button at nav position 2 does NOT set a tab.
  void selectTab(int index, {String? askQuery}) {
    // Map logical tab index → internal page index
    // 0→0 (Home), 1→1 (People), 2→2 (Ask), 3→3 (Settings)
    final pageIndex = index.clamp(0, 3);
    if (_selectedIndex != pageIndex || (askQuery != null && askQuery != _askQuery)) {
      setState(() {
        _selectedIndex = pageIndex;
        if (askQuery != null) {
          _askQuery = askQuery;
          _initPages();
        }
      });
      HapticFeedback.selectionClick();
    }
  }

  /// Called when a nav bar item is tapped.
  /// nav positions: 0=Home, 1=People, 2=QuickAdd(special), 3=Search, 4=More
  void _onNavTapped(int navPosition) {
    switch (navPosition) {
      case 0:
        selectTab(0);
      case 1:
        selectTab(1);
      case 2:
        _openQuickCapture();
      case 3:
        selectTab(2); // Ask screen → page index 2
      case 4:
        selectTab(3); // Settings screen → page index 3
    }
  }

  void _openQuickCapture() {
    HapticFeedback.mediumImpact();
    RecallrBottomSheet.show(
      context: context,
      child: const CaptureModal(),
    );
  }

  /// Map page index back to nav position for highlight purposes
  int get _activeNavPosition {
    switch (_selectedIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // People
      case 2:
        return 3; // Ask → nav pos 3
      case 3:
        return 4; // Settings → nav pos 4
      default:
        return 0;
    }
  }

  String get _currentTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'People';
      case 2:
        return 'Search';
      case 3:
        return 'More';
      default:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecallrAppShellScope(
      selectedIndex: _selectedIndex,
      selectTab: selectTab,
      child: PopScope<Object?>(
        key: const ValueKey<String>('recallr_shell_pop_scope'),
        canPop: _selectedIndex == 0,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          if (_selectedIndex != 0) {
            selectTab(0);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < kTabletBreakpoint;
            final isDesktop = width >= kDesktopBreakpoint;

            return Scaffold(
              backgroundColor: RecallrColors.obsidianBase,
              appBar: _buildAppBar(),
              body: Row(
                children: [
                  if (!isMobile) ...[
                    _buildNavigationRail(isDesktop: isDesktop),
                    const VerticalDivider(
                      color: RecallrColors.borderSubtle,
                      thickness: 1.0,
                      width: 1.0,
                    ),
                  ],
                  Expanded(
                    key: const ValueKey<String>('shell_content_expanded'),
                    child: IndexedStack(
                      key: const PageStorageKey<String>('recallr_shell_stack'),
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: isMobile ? _buildBottomNavBar() : null,
            );
          },
        ),
      ),
    );
  }

  /// Top Dynamic AppBar — hamburger on home, back arrow on sub-screens.
  PreferredSizeWidget _buildAppBar() {
    final initials = widget.user?.displayName?.isNotEmpty == true
        ? widget.user!.displayName!.substring(0, 1)
        : (widget.user?.email?.isNotEmpty == true ? widget.user!.email!.substring(0, 1) : 'U');

    final isHome = _selectedIndex == 0;

    return AppBar(
      leading: isHome
          ? IconButton(
              icon: const Icon(Icons.menu_rounded, color: RecallrColors.textSecondary),
              tooltip: 'Menu',
              onPressed: () {
                // Drawer / side menu placeholder
              },
            )
          : null,
      title: isHome
          ? null
          : Text(_currentTitle),
      actions: [
        // AI Credits & Subscription Quick Access Pill
        StreamBuilder<UserSubscription>(
          stream: context.subscriptionRepo.streamSubscription(),
          builder: (context, snapshot) {
            final subscription = snapshot.data;
            final credits = subscription?.totalAvailableCredits ?? 20;
            final tier = subscription?.tier ?? SubscriptionTier.starter;
            final isPro = tier != SubscriptionTier.starter;

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.xs),
                child: Tooltip(
                  message: 'AI Credits: $credits remaining\nTap to manage subscription & top up',
                  child: InkWell(
                    key: const ValueKey<String>('appbar_credits_pill'),
                    onTap: () {
                      Navigator.of(context).pushNamed(RecallrRoutes.subscription);
                    },
                    borderRadius: RecallrRadii.radiusPill,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 5.0),
                      decoration: BoxDecoration(
                        color: isPro
                            ? RecallrColors.aiElectricViolet.withValues(alpha: 0.15)
                            : RecallrColors.slateSurface,
                        borderRadius: RecallrRadii.radiusPill,
                        border: Border.all(
                          color: isPro
                              ? RecallrColors.aiElectricViolet.withValues(alpha: 0.4)
                              : RecallrColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 15.0,
                            color: isPro ? RecallrColors.aiElectricViolet : RecallrColors.warmAmberGold,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '$credits',
                            style: RecallrTypography.labelSmall.copyWith(
                              color: RecallrColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.0,
                            ),
                          ),
                          if (isPro) ...[
                            const SizedBox(width: 4.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                              decoration: const BoxDecoration(
                                color: RecallrColors.aiElectricViolet,
                                borderRadius: RecallrRadii.radiusSm,
                              ),
                              child: Text(
                                tier.displayName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        RecallrSpacing.gapXs,
        // QR Scanner icon
        RecallrIconButton(
          icon: Icons.qr_code_scanner_rounded,
          tooltip: 'QR Scanner',
          onPressed: () {
            // QR scanner placeholder
          },
        ),
        const SizedBox(width: 4.0),
        // User Profile Avatar with Sign Out and Subscription Menu
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          color: RecallrColors.slateSurface,
          shape: RoundedRectangleBorder(
            borderRadius: RecallrRadii.radiusMd,
            side: const BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
          ),
          onSelected: (value) async {
            if (value == 'subscription') {
              Navigator.of(context).pushNamed(RecallrRoutes.subscription);
            } else if (value == 'sign_out') {
              DeepLinkManager().consumePendingPath();
              Navigator.of(context).popUntil((route) => route.isFirst);
              await _authService.signOut();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                widget.user?.email ?? 'User',
                style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textSecondary),
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              key: const ValueKey<String>('menu_item_subscription'),
              value: 'subscription',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 18, color: RecallrColors.warmAmberGold),
                  RecallrSpacing.gapSm,
                  Expanded(
                    child: Text(
                      'Subscription & Storage',
                      style: RecallrTypography.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'sign_out',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded, size: 18, color: RecallrColors.crimsonAlert),
                  RecallrSpacing.gapSm,
                  Expanded(
                    child: Text(
                      'Sign Out',
                      style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.crimsonAlert),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: RecallrSpacing.md),
            child: RecallrAvatar(
              initials: initials,
              imageUrl: widget.user?.photoURL,
              size: RecallrAvatarSize.sm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRail({required bool isDesktop}) {
    // For rail, map _selectedIndex to a rail index that excludes the center button
    // Rail destinations: Home(0), People(1), Search(2), More(3)
    final railIndex = _selectedIndex; // 0=Home,1=People,2=Ask,3=Settings

    return NavigationRail(
      extended: isDesktop,
      backgroundColor: RecallrColors.slateSurface,
      selectedIndex: railIndex,
      onDestinationSelected: (i) {
        // rail: 0=Home,1=People,2=Ask,3=Settings
        selectTab(i);
      },
      labelType: isDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: RecallrSpacing.md, bottom: RecallrSpacing.lg),
        child: isDesktop
            ? SizedBox(
                width: 180.0,
                child: RecallrButton(
                  label: 'Quick Capture',
                  variant: RecallrButtonVariant.aiGradient,
                  leadingIcon: Icons.add_rounded,
                  onPressed: _openQuickCapture,
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [RecallrShadows.glowAi],
                ),
                child: FloatingActionButton(
                  onPressed: _openQuickCapture,
                  backgroundColor: RecallrColors.aiElectricViolet,
                  foregroundColor: RecallrColors.textPrimary,
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add_rounded, size: 28.0),
                ),
              ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('People'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search_rounded),
          selectedIcon: Icon(Icons.saved_search_rounded),
          label: Text('Search'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: Text('More'),
        ),
      ],
      trailing: Padding(
        padding: const EdgeInsets.only(top: RecallrSpacing.xl, bottom: RecallrSpacing.md),
        child: isDesktop
            ? StreamBuilder<UserSubscription>(
                stream: context.subscriptionRepo.streamSubscription(),
                builder: (context, snapshot) {
                  final sub = snapshot.data;
                  final credits = sub?.totalAvailableCredits ?? 20;
                  final tier = sub?.tier ?? SubscriptionTier.starter;
                  final isPro = tier != SubscriptionTier.starter;

                  return InkWell(
                    key: const ValueKey<String>('nav_rail_subscription_desktop'),
                    onTap: () => Navigator.of(context).pushNamed(RecallrRoutes.subscription),
                    borderRadius: RecallrRadii.radiusMd,
                    child: Container(
                      width: 180.0,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isPro
                            ? RecallrColors.aiElectricViolet.withValues(alpha: 0.12)
                            : RecallrColors.charcoalCard,
                        borderRadius: RecallrRadii.radiusMd,
                        border: Border.all(
                          color: isPro
                              ? RecallrColors.aiElectricViolet.withValues(alpha: 0.35)
                              : RecallrColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPro ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
                            size: 18.0,
                            color: isPro ? RecallrColors.aiElectricViolet : RecallrColors.warmAmberGold,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tier.displayName,
                                  style: RecallrTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                                Text(
                                  '$credits credits',
                                  style: RecallrTypography.labelSmall.copyWith(
                                    color: RecallrColors.textSecondary,
                                    fontSize: 10.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 11.0, color: RecallrColors.textSecondary),
                        ],
                      ),
                    ),
                  );
                },
              )
            : IconButton(
                key: const ValueKey<String>('nav_rail_subscription_tablet'),
                icon: Icon(Icons.workspace_premium_rounded, color: RecallrColors.warmAmberGold),
                tooltip: 'Subscription & Cloud Storage',
                onPressed: () => Navigator.of(context).pushNamed(RecallrRoutes.subscription),
              ),
      ),
    );
  }

  /// Integrated bottom nav bar with 5 positions:
  /// [Home] [People] [+ circle] [Search] [More]
  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.0,
          child: Row(
            children: [
              _buildNavItem(navPosition: 0, destIndex: 0),
              _buildNavItem(navPosition: 1, destIndex: 1),
              _buildCenterFabItem(),
              _buildNavItem(navPosition: 3, destIndex: 2),
              _buildNavItem(navPosition: 4, destIndex: 3),
            ],
          ),
        ),
      ),
    );
  }

  /// A regular bottom nav item. [navPosition] is the tap index (0,1,3,4).
  /// [destIndex] is the index into [_destinations] list (0-3).
  Widget _buildNavItem({required int navPosition, required int destIndex}) {
    final dest = _destinations[destIndex];
    final isSelected = _activeNavPosition == navPosition;
    final color = isSelected ? RecallrColors.aiElectricViolet : RecallrColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => _onNavTapped(navPosition),
        borderRadius: RecallrRadii.radiusMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? dest.selectedIcon : dest.icon, color: color, size: 22.0),
            const SizedBox(height: 2.0),
            Text(
              dest.label,
              style: RecallrTypography.labelSmall.copyWith(
                color: color,
                fontSize: 10.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The center Quick-Add FAB button integrated into the bottom nav bar.
  Widget _buildCenterFabItem() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTapped(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: RecallrColors.aiElectricViolet,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: RecallrColors.aiElectricViolet.withValues(alpha: 0.45),
                    blurRadius: 12.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
