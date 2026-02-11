/// Authentication state provider using Riverpod.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_state.dart';
import '../models/user_profile.dart';
import '../services/spotify_auth_service.dart';
import '../services/spotify_api_service.dart';

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial);

  /// Track codes already being processed to prevent double-redemption
  final Set<String> _processedCodes = {};

  /// Initialize auth state from stored tokens
  Future<void> initialize() async {
    state = state.copyWithLoading();

    final storedAuth = await SpotifyAuthService.loadStoredAuth();

    if (storedAuth != null && storedAuth.isSuccess) {
      // Fetch user profile
      try {
        final api = SpotifyApiService(storedAuth.accessToken!);
        final user = await api.getCurrentUser();

        state = state.copyWithAuthenticated(
          accessToken: storedAuth.accessToken!,
          refreshToken: storedAuth.refreshToken,
          expiresAt: storedAuth.expiresAt!,
          user: user,
        );
      } catch (e) {
        state = AuthState.unauthenticated;
      }
    } else {
      state = AuthState.unauthenticated;
    }
  }

  /// Start login flow
  Future<void> login() async {
    state = state.copyWithLoading();

    final result = await SpotifyAuthService.authenticate();

    if (result.isSuccess) {
      // Fetch user profile
      try {
        final api = SpotifyApiService(result.accessToken!);
        final user = await api.getCurrentUser();

        state = state.copyWithAuthenticated(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken,
          expiresAt: result.expiresAt!,
          user: user,
        );
      } catch (e) {
        state = state.copyWithError('Failed to fetch user profile: $e');
      }
    } else {
      state = state.copyWithError(
        result.errorMessage ?? 'Authentication failed',
      );
    }
  }

  /// Handle OAuth callback (Web)
  Future<void> handleCallback(String code) async {
    // Guard: prevent the same code from being exchanged twice
    if (_processedCodes.contains(code)) return;
    // Also skip if we're already authenticated (callback screen already handled it)
    if (state.isAuthenticated) return;
    _processedCodes.add(code);

    state = state.copyWithLoading();

    final result = await SpotifyAuthService.exchangeCodeFromCallback(code);

    if (result.isSuccess) {
      try {
        final api = SpotifyApiService(result.accessToken!);
        final user = await api.getCurrentUser();

        state = state.copyWithAuthenticated(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken,
          expiresAt: result.expiresAt!,
          user: user,
        );
      } catch (e) {
        state = state.copyWithError('Failed to fetch user profile: $e');
      }
    } else {
      state = state.copyWithError(
        result.errorMessage ?? 'Authentication failed',
      );
    }
  }

  /// Clear auth error
  void clearError() {
    state = state.clearError();
  }

  /// Logout
  Future<void> logout() async {
    await SpotifyAuthService.clearTokens();
    state = AuthState.unauthenticated;
  }

  /// Update user profile
  void updateUser(SpotifyUserProfile user) {
    if (state.accessToken != null && state.expiresAt != null) {
      state = state.copyWithAuthenticated(
        accessToken: state.accessToken!,
        refreshToken: state.refreshToken,
        expiresAt: state.expiresAt!,
        user: user,
      );
    }
  }

  /// Set authenticated state directly (used by callback screen)
  void setAuthenticated({
    required String accessToken,
    String? refreshToken,
    required DateTime expiresAt,
    SpotifyUserProfile? user,
  }) {
    state = state.copyWithAuthenticated(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      user: user,
    );
  }

  /// Get valid access token (refreshing if needed)
  Future<String?> getValidToken() async {
    if (state.isTokenExpired) {
      final result = await SpotifyAuthService.refreshAccessToken();
      if (result.isSuccess) {
        state = state.copyWithAuthenticated(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken,
          expiresAt: result.expiresAt!,
          user: state.user,
        );
        return result.accessToken;
      }
      return null;
    }
    return state.accessToken;
  }
}

/// Main auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience provider for checking if authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Convenience provider for current user
final currentUserProvider = Provider<SpotifyUserProfile?>((ref) {
  return ref.watch(authProvider).user;
});

/// Provider for access token
final accessTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).accessToken;
});
