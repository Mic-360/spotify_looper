/// App configuration for Spotify credentials and environment settings.
library;

import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  static AppConfig? _instance;

  final String spotifyClientId;
  final String spotifyClientSecret;

  AppConfig._({
    required this.spotifyClientId,
    required this.spotifyClientSecret,
  });

  static AppConfig get instance {
    if (_instance == null) {
      throw StateError(
        'AppConfig not initialized. Call AppConfig.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initialize configuration from .env.json
  static Future<void> initialize() async {
    if (_instance != null) return;

    try {
      final jsonString = await rootBundle.loadString('.env.json');
      final config = json.decode(jsonString) as Map<String, dynamic>;

      _instance = AppConfig._(
        spotifyClientId: config['SPOTIFY_CLIENT_ID'] as String? ?? '',
        spotifyClientSecret: config['SPOTIFY_CLIENT_SECRET'] as String? ?? '',
      );
    } catch (e) {
      // Fallback to environment variables or defaults
      _instance = AppConfig._(
        spotifyClientId: const String.fromEnvironment('SPOTIFY_CLIENT_ID'),
        spotifyClientSecret: const String.fromEnvironment(
          'SPOTIFY_CLIENT_SECRET',
        ),
      );
    }
  }

  // OAuth Configuration
  static const String redirectUriWeb = 'http://127.0.0.1:8000/callback';
  static const String redirectUriAndroid = 'spotify-looper://callback';

  /// Get the appropriate redirect URI based on platform
  static String get redirectUri {
    // Check if running on web
    if (identical(0, 0.0)) {
      return redirectUriWeb;
    }
    return redirectUriAndroid;
  }

  /// All Spotify OAuth scopes for maximum data extraction
  static const List<String> spotifyScopes = [
    'user-read-private',
    'user-read-email',
    'user-read-playback-state',
    'user-modify-playback-state',
    'user-read-currently-playing',
    'streaming',
    'playlist-read-private',
    'playlist-read-collaborative',
    'user-library-read',
    'user-top-read',
    'user-read-recently-played',
    'user-follow-read',
  ];

  /// Combined scopes string for OAuth URL
  static String get scopesString => spotifyScopes.join(' ');
}
