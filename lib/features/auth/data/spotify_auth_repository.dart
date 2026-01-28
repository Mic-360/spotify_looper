import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';

/// Repository for handling Spotify OAuth 2.0 PKCE flow.
class SpotifyAuthRepository {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  static const String _tokenExpiryKey = 'token_expiry';

  static const String _codeVerifierKey = 'code_verifier';
  final Dio _dio;
  final SharedPreferences _prefs;
  SpotifyAuthRepository(this._dio, this._prefs);

  /// Checks if the user is currently logged in.
  bool get isLoggedIn => _prefs.containsKey(_accessTokenKey);

  /// Gets the current access token, refreshing it if necessary.
  Future<String?> getAccessToken() async {
    final token = _prefs.getString(_accessTokenKey);
    final expiryStr = _prefs.getString(_tokenExpiryKey);

    if (token == null || expiryStr == null) return null;

    final expiry = DateTime.parse(expiryStr);
    // Refresh if expiring in less than 5 minutes
    if (DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)))) {
      return await refreshToken();
    }

    return token;
  }

  /// Handles the callback from Spotify with the authorization code.
  Future<void> handleCallback(String code) async {
    final codeVerifier = _prefs.getString(_codeVerifierKey);
    if (codeVerifier == null) throw Exception('Code verifier not found');

    try {
      final response = await _dio.post(
        '${AppConfig.spotifyAuthUrl}/api/token',
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': AppConfig.redirectUri,
          'client_id': AppConfig.spotifyClientId,
          'code_verifier': codeVerifier,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      await _saveTokens(response.data);
    } catch (e) {
      throw Exception('Failed to exchange code for tokens: $e');
    }
  }

  /// Initiates the Spotify login flow via browser.
  Future<void> login() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    await _prefs.setString(_codeVerifierKey, codeVerifier);

    final authUrl = Uri.parse('${AppConfig.spotifyAuthUrl}/authorize').replace(
      queryParameters: {
        'client_id': AppConfig.spotifyClientId,
        'response_type': 'code',
        'redirect_uri': AppConfig.redirectUri,
        'scope': AppConfig.scopesString,
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
      },
    );

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch authorization URL');
    }
  }

  /// Logs out the user by clearing tokens.
  Future<void> logout() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_tokenExpiryKey);
    await _prefs.remove(_codeVerifierKey);
  }

  /// Refreshes the access token using the refresh token.
  Future<String?> refreshToken() async {
    final refreshToken = _prefs.getString(_refreshTokenKey);
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post(
        '${AppConfig.spotifyAuthUrl}/api/token',
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': AppConfig.spotifyClientId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      await _saveTokens(response.data);
      return response.data['access_token'];
    } catch (e) {
      // If refresh fails, log out the user
      await logout();
      return null;
    }
  }

  /// Generates a code challenge from the verifier.
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// Generates a code verifier for PKCE.
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url
        .encode(values)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final accessToken = data['access_token'];
    final refreshToken =
        data['refresh_token'] ?? _prefs.getString(_refreshTokenKey);
    final expiresIn = data['expires_in'] as int;

    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken!);

    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
    await _prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
  }
}
