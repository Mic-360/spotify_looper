/// Spotify OAuth authentication service with PKCE support.
///
/// Implements the Authorization Code Flow with PKCE as required by:
/// https://developer.spotify.com/blog/2025-02-12-increasing-the-security-requirements-for-integrating-with-spotify
library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../core/app_config.dart';

class SpotifyAuthService {
  static const String _authEndpoint = 'https://accounts.spotify.com/authorize';
  static const String _tokenEndpoint = 'https://accounts.spotify.com/api/token';

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'spotify_access_token';
  static const _refreshTokenKey = 'spotify_refresh_token';
  static const _expiresAtKey = 'spotify_expires_at';
  static const _codeVerifierKey = 'spotify_code_verifier';

  /// Generate a cryptographically random code verifier for PKCE
  static String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (_) => random.nextInt(256));
    return base64UrlEncode(
      values,
    ).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }

  /// Generate code challenge from verifier using SHA-256
  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(
      digest.bytes,
    ).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }

  /// Start OAuth flow with PKCE and return access token
  static Future<AuthResult> authenticate() async {
    try {
      final config = AppConfig.instance;
      final redirectUri = kIsWeb
          ? AppConfig.redirectUriWeb
          : AppConfig.redirectUriAndroid;

      // Generate PKCE code verifier and challenge
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // Store code verifier for token exchange (needed later)
      await _storage.write(key: _codeVerifierKey, value: codeVerifier);

      // Build authorization URL with PKCE parameters
      final authUrl = Uri.parse(_authEndpoint).replace(
        queryParameters: {
          'client_id': config.spotifyClientId,
          'response_type': 'code',
          'redirect_uri': redirectUri,
          'scope': AppConfig.scopesString,
          'show_dialog': 'true',
          // PKCE parameters
          'code_challenge_method': 'S256',
          'code_challenge': codeChallenge,
        },
      );

      // Open browser for authentication
      final callbackUrlScheme = kIsWeb
          ? AppConfig.webCallbackScheme
          : 'spotify-looper';

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: callbackUrlScheme,
      );

      // Extract authorization code from callback
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        return AuthResult.failure('Authentication failed: $error');
      }

      if (code == null) {
        return AuthResult.failure('No authorization code received');
      }

      // Exchange code for tokens using PKCE
      return await _exchangeCodeForTokens(code, redirectUri, codeVerifier);
    } catch (e) {
      return AuthResult.failure('Authentication error: $e');
    }
  }

  /// Exchange code from callback URL (used when landing on /callback directly)
  static Future<AuthResult> exchangeCodeFromCallback(String code) async {
    try {
      final codeVerifier = await _storage.read(key: _codeVerifierKey);

      if (codeVerifier == null) {
        return AuthResult.failure(
          'No code verifier found. Please try logging in again.',
        );
      }

      final redirectUri = kIsWeb
          ? AppConfig.redirectUriWeb
          : AppConfig.redirectUriAndroid;

      return await _exchangeCodeForTokens(code, redirectUri, codeVerifier);
    } catch (e) {
      return AuthResult.failure('Token exchange error: $e');
    }
  }

  /// Exchange authorization code for access and refresh tokens using PKCE
  static Future<AuthResult> _exchangeCodeForTokens(
    String code,
    String redirectUri,
    String codeVerifier,
  ) async {
    try {
      final config = AppConfig.instance;

      // For PKCE flow, we don't use client_secret in the token request
      // Instead, we use the code_verifier to prove we initiated the auth
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': config.spotifyClientId,
          'code_verifier': codeVerifier,
        },
      );

      // Clean up stored code verifier
      await _storage.delete(key: _codeVerifierKey);

      if (response.statusCode != 200) {
        return AuthResult.failure('Token exchange failed: ${response.body}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final expiresIn = data['expires_in'] as int;
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      // Save tokens
      await _saveTokens(accessToken, refreshToken, expiresAt);

      return AuthResult.success(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );
    } catch (e) {
      return AuthResult.failure('Token exchange error: $e');
    }
  }

  /// Refresh access token using refresh token
  static Future<AuthResult> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);

      if (refreshToken == null) {
        return AuthResult.failure('No refresh token available');
      }

      final config = AppConfig.instance;

      // For PKCE refresh, we only need client_id (no client_secret)
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': config.spotifyClientId,
        },
      );

      if (response.statusCode != 200) {
        // Refresh failed, need to re-authenticate
        await clearTokens();
        return AuthResult.failure('Token refresh failed');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final accessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String? ?? refreshToken;
      final expiresIn = data['expires_in'] as int;
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      await _saveTokens(accessToken, newRefreshToken, expiresAt);

      return AuthResult.success(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        expiresAt: expiresAt,
      );
    } catch (e) {
      return AuthResult.failure('Token refresh error: $e');
    }
  }

  /// Get stored access token (refreshing if needed)
  static Future<String?> getValidAccessToken() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final expiresAtStr = await _storage.read(key: _expiresAtKey);

    if (accessToken == null || expiresAtStr == null) {
      return null;
    }

    final expiresAt = DateTime.parse(expiresAtStr);

    // Refresh if expiring within 5 minutes
    if (DateTime.now().isAfter(
      expiresAt.subtract(const Duration(minutes: 5)),
    )) {
      final result = await refreshAccessToken();
      return result.isSuccess ? result.accessToken : null;
    }

    return accessToken;
  }

  /// Check if user has stored tokens
  static Future<bool> hasStoredTokens() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    return accessToken != null;
  }

  /// Load stored authentication
  static Future<AuthResult?> loadStoredAuth() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAtStr = await _storage.read(key: _expiresAtKey);

    if (accessToken == null || expiresAtStr == null) {
      return null;
    }

    final expiresAt = DateTime.parse(expiresAtStr);

    // Check if expired
    if (DateTime.now().isAfter(expiresAt)) {
      // Try to refresh
      return await refreshAccessToken();
    }

    return AuthResult.success(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  /// Save tokens to secure storage
  static Future<void> _saveTokens(
    String accessToken,
    String? refreshToken,
    DateTime expiresAt,
  ) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    await _storage.write(
      key: _expiresAtKey,
      value: expiresAt.toIso8601String(),
    );
  }

  /// Clear all stored tokens (logout)
  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _codeVerifierKey);
  }
}

/// Result of authentication attempt
class AuthResult {
  final bool isSuccess;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? errorMessage;

  const AuthResult._({
    required this.isSuccess,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.errorMessage,
  });

  factory AuthResult.success({
    required String accessToken,
    String? refreshToken,
    required DateTime expiresAt,
  }) => AuthResult._(
    isSuccess: true,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
  );

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
