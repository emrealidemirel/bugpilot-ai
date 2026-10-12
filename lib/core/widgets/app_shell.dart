import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../constants/app_dimensions.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BugPilotBottomNavigation(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _BugPilotBottomNavigation extends StatelessWidget {
  const _BugPilotBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const double _visualHeight =
      AppDimensions.bottomNavigationVisualHeight;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTheme.darkBackground
        : AppTheme.background;

    return Semantics(
      container: true,
      label: 'Main navigation',
      child: SizedBox(
        height: _visualHeight + bottomPadding,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor.withAlpha(230),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _visualHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        index: 0,
                        selectedIndex: selectedIndex,
                        label: 'DASHBOARD',
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard_rounded,
                        onTap: onDestinationSelected,
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        index: 1,
                        selectedIndex: selectedIndex,
                        label: 'BUGS',
                        icon: Icons.bug_report_outlined,
                        selectedIcon: Icons.bug_report_rounded,
                        onTap: onDestinationSelected,
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        index: 2,
                        selectedIndex: selectedIndex,
                        label: 'REPORT',
                        icon: Icons.add_circle_outline,
                        selectedIcon: Icons.add_circle,
                        onTap: onDestinationSelected,
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        index: 3,
                        selectedIndex: selectedIndex,
                        label: 'SETTINGS',
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        onTap: onDestinationSelected,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final color = isSelected
        ? AppTheme.primary
        : AppTheme.textSecondaryFor(context);

    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          splashFactory: InkRipple.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return color.withAlpha(18);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return color.withAlpha(10);
            }
            return null;
          }),
          onTap: () => onTap(index),
          child: SizedBox(
            height: _BugPilotBottomNavigation._visualHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isSelected ? selectedIcon : icon, color: color, size: 22),
                const SizedBox(height: AppDimensions.spacingXSmall),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 16 / 12,
                    letterSpacing: 0.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
