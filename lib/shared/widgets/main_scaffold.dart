import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main scaffold with persistent bottom navigation.
///
/// Uses NavigationBar for compact screens and NavigationRail for expanded.
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const List<_NavDestination> _destinations = [
    _NavDestination(
      path: '/',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    _NavDestination(
      path: '/favorites',
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      label: 'Favorites',
    ),
    _NavDestination(
      path: '/history',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      label: 'History',
    ),
    _NavDestination(
      path: '/search',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: 'Search',
    ),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isExpanded = screenWidth >= 840;

    if (isExpanded) {
      // Use NavigationRail for larger screens
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: IconButton.filledTonal(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                ),
              ),
              destinations: _destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Use NavigationBar for compact screens
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _onDestinationSelected(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      context.go(_destinations[index].path);
    }
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.path;
    final index = _destinations.indexWhere((d) => d.path == location);
    if (index != -1 && index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }
}

class _NavDestination {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavDestination({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
