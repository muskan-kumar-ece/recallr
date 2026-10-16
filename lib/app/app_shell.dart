import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../core/widgets/widgets.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/ask/ask_screen.dart';
import '../screens/capture/capture_modal.dart';
import '../screens/home/home_screen.dart';
import '../screens/people/people_screen.dart';
import '../services/auth_service.dart';
import '../core/routing/deep_link_manager.dart';
import '../core/routing/recallr_routes.dart';

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
      RecallrRoutes.activity,
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
      const ActivityScreen(),
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

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    _NavDestination(
      label: 'People',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
    ),
    _NavDestination(
      label: 'Ask',
      icon: Icons.search_rounded,
      selectedIcon: Icons.saved_search_rounded,
    ),
    _NavDestination(
      label: 'Activity',
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt_rounded,
    ),
  ];

  void selectTab(int index, {String? askQuery}) {
    if (_selectedIndex != index || (askQuery != null && askQuery != _askQuery)) {
      setState(() {
        _selectedIndex = index;
        if (askQuery != null) {
          _askQuery = askQuery;
          _initPages();
        }
      });
      HapticFeedback.selectionClick();
    }
  }

  void _onDestinationSelected(int index) => selectTab(index);

  void _openQuickCapture() {
    HapticFeedback.mediumImpact();
    RecallrBottomSheet.show(
      context: context,
      child: const CaptureModal(),
    );
  }

  String get _currentTitle => _destinations[_selectedIndex].label;

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
            _onDestinationSelected(0);
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
              floatingActionButton: isMobile ? _buildCaptureFab() : null,
              floatingActionButtonLocation: isMobile ? FloatingActionButtonLocation.centerDocked : null,
              bottomNavigationBar: isMobile ? _buildBottomNavBar() : null,
            );
          },
        ),
      ),
    );
  }

  /// Top Dynamic AppBar
  PreferredSizeWidget _buildAppBar() {
    final initials = widget.user?.displayName?.isNotEmpty == true
        ? widget.user!.displayName!.substring(0, 1)
        : (widget.user?.email?.isNotEmpty == true ? widget.user!.email!.substring(0, 1) : 'U');

    return AppBar(
      title: Text(_currentTitle),
      actions: [
        RecallrIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Universal Search',
          onPressed: () {
            // Switch to Ask tab on search trigger
            _onDestinationSelected(2);
          },
        ),
        // Sync Status Indicator Dot
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: RecallrSpacing.xs),
            child: RecallrBadge(
              isDot: true,
              variant: RecallrBadgeVariant.verified,
            ),
          ),
        ),
        RecallrSpacing.gapSm,
        // User Profile Avatar with Sign Out
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          color: RecallrColors.slateSurface,
          shape: RoundedRectangleBorder(
            borderRadius: RecallrRadii.radiusMd,
            side: const BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
          ),
          onSelected: (value) async {
            if (value == 'settings') {
              Navigator.of(context).pushNamed('/settings');
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
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, size: 18, color: RecallrColors.textSecondary),
                  RecallrSpacing.gapSm,
                  Text('Settings & Preferences', style: RecallrTypography.bodyMedium),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'sign_out',
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: 18, color: RecallrColors.crimsonAlert),
                  RecallrSpacing.gapSm,
                  Text('Sign Out', style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.crimsonAlert)),
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

  /// Center Floating Capture FAB
  Widget _buildCaptureFab() {
    return Container(
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
    );
  }

  Widget _buildNavigationRail({required bool isDesktop}) {
    return NavigationRail(
      extended: isDesktop,
      backgroundColor: RecallrColors.slateSurface,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
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
            : _buildCaptureFab(),
      ),
      destinations: _destinations.map((d) {
        return NavigationRailDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon),
          label: Text(d.label),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
        ),
      ),
      child: BottomAppBar(
        color: RecallrColors.slateSurface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 0,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0),
              _buildNavItem(1),
              const SizedBox(width: 48.0), // Space for center FAB
              _buildNavItem(2),
              _buildNavItem(3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final dest = _destinations[index];
    final isSelected = _selectedIndex == index;
    final color = isSelected ? RecallrColors.aiElectricViolet : RecallrColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => _onDestinationSelected(index),
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
}