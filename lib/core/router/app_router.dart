import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/player/presentation/player_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) => router);

/// App router configuration using go_router.
///
/// Features:
/// - Shell route for persistent navigation bar
/// - Nested routes for each feature
/// - Auth redirect handling
final GoRouter router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,

  // Redirect based on auth state
  redirect: (context, state) {
    // TODO: Check auth state and redirect to login if needed
    // final isLoggedIn = ref.read(authProvider).isLoggedIn;
    // if (!isLoggedIn && state.uri.path != '/login') {
    //   return '/login';
    // }
    return null;
  },

  routes: [
    // Login route (outside shell)
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    // Main app shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        // Home
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),

        // Favorites
        GoRoute(
          path: '/favorites',
          name: 'favorites',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: FavoritesScreen()),
        ),

        // History
        GoRoute(
          path: '/history',
          name: 'history',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HistoryScreen()),
        ),

        // Search
        GoRoute(
          path: '/search',
          name: 'search',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SearchScreen()),
        ),
      ],
    ),

    // Player (full screen overlay)
    GoRoute(
      path: '/player/:trackId',
      name: 'player',
      builder: (context, state) {
        final trackId = state.pathParameters['trackId'] ?? '';
        return PlayerScreen(trackId: trackId);
      },
    ),

    // Settings
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],

  // Error handling
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.uri.path,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);

/// Navigation helper extension
extension RouterExtension on BuildContext {
  /// Navigate to favorites
  void goFavorites() => go('/favorites');

  /// Navigate to history
  void goHistory() => go('/history');

  /// Navigate to home
  void goHome() => go('/');

  /// Navigate to login
  void goLogin() => go('/login');

  /// Navigate to player with track
  void goPlayer(String trackId) => go('/player/$trackId');

  /// Navigate to search
  void goSearch() => go('/search');

  /// Navigate to settings
  void goSettings() => go('/settings');
}
