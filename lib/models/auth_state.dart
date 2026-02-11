/// Authentication state model.
library;

import 'user_profile.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final SpotifyUserProfile? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.user,
    this.errorMessage,
  });

  /// Check if access token is expired
  bool get isTokenExpired {
    if (expiresAt == null) return true;
    return DateTime.now().isAfter(
      expiresAt!.subtract(const Duration(minutes: 5)),
    );
  }

  /// Check if user is authenticated
  bool get isAuthenticated =>
      status == AuthStatus.authenticated &&
      accessToken != null &&
      !isTokenExpired;

  /// Create loading state
  AuthState copyWithLoading() => AuthState(
    status: AuthStatus.loading,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
    user: user,
  );

  /// Create authenticated state
  AuthState copyWithAuthenticated({
    required String accessToken,
    String? refreshToken,
    required DateTime expiresAt,
    SpotifyUserProfile? user,
  }) => AuthState(
    status: AuthStatus.authenticated,
    accessToken: accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt,
    user: user ?? this.user,
  );

  /// Create error state
  AuthState copyWithError(String message) => AuthState(
    status: AuthStatus.error,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
    user: user,
    errorMessage: message,
  );

  /// Clear error
  AuthState clearError() => AuthState(
    status: status == AuthStatus.error ? AuthStatus.unauthenticated : status,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
    user: user,
    errorMessage: null,
  );

  /// Create unauthenticated state
  static const AuthState unauthenticated = AuthState(
    status: AuthStatus.unauthenticated,
  );

  /// Initial state
  static const AuthState initial = AuthState(status: AuthStatus.initial);

  @override
  String toString() {
    return 'AuthState(status: $status, hasToken: ${accessToken != null}, user: ${user?.displayName})';
  }
}
