// =============================================================================
// screens/app_shell.dart — NAVIGATION THAT ADAPTS TO THE SCREEN
// =============================================================================
//   Phones:          bottom tab bar
//   Tablets:         narrow side rail (icons + small labels)
//   Laptops/desktop: wide sidebar (logo, icons and names)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:subbies/layout/app_layout.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Subscriptions',
    ),
    (
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      label: 'Insights',
    ),
    (icon: Icons.tune_outlined, selectedIcon: Icons.tune, label: 'Settings'),
  ];

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);

    // Phones: bottom bar.
    if (!layout.usesRail) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelect,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: layout.extendedRail,
            minExtendedWidth: 220,
            labelType: layout.extendedRail
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onSelect,
            leading: _Brand(extended: layout.extendedRail),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final tile = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(Icons.autorenew_rounded, color: colors.onPrimary, size: 22),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
      child: extended
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                tile,
                const SizedBox(width: 12),
                Text(
                  'Subbies',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            )
          : tile,
    );
  }
}
