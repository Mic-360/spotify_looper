import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main scaffold with persistent custom bottom navigation.
///
/// Matches the high-fidelity Pulse Loop design with a central elevated Search button.
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const List<_NavDestination> _destinations = [
    _NavDestination(path: '/', icon: Icons.home_rounded, label: 'Home'),
    _NavDestination(
      path: '/history',
      icon: Icons.history_rounded,
      label: 'History',
    ),
    _NavDestination(
      path: '/search', // Middle FAB
      icon: Icons.search_rounded,
      label: 'Search',
    ),
    _NavDestination(
      path: '/favorites',
      icon: Icons.favorite_rounded,
      label: 'Favorites',
    ),
    _NavDestination(
      path: '/settings',
      icon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isExpanded = screenWidth >= 840;

    return Scaffold(
      body: Stack(
        children: [widget.child, if (!isExpanded) _buildBottomNav(context)],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  Widget _buildBottomNav(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(bottom: safeAreaBottom),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F).withOpacity(0.9),
              border: const Border(
                top: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0),
                      _buildNavItem(1),
                      _buildSearchItem(),
                      _buildNavItem(3),
                      _buildNavItem(4),
                    ],
                  ),
                ),
                // Home Indicator simulator
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final destination = _destinations[index];
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onDestinationSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              destination.icon,
              size: 24,
              color: isSelected ? Colors.white : Colors.grey[500],
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchItem() {
    const int index = 0;
    // Special handling for the center search button which is elevated
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => _onDestinationSelected(index),
            child: Container(
              width: 56,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954), // Spotify Green
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F0F0F), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 28,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
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
  final String label;

  const _NavDestination({
    required this.path,
    required this.icon,
    required this.label,
  });
}
