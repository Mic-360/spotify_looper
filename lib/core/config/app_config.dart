/// Application configuration for Spotify Looper
///
/// Contains API keys, endpoints, and environment-specific settings.
class AppConfig {
  AppConfig._();

  // ══════════════════════════════════════════════════════════════════════════
  // Spotify Configuration
  // ══════════════════════════════════════════════════════════════════════════

  /// Spotify Client ID - Set via environment variable in production
  static const String spotifyClientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
    defaultValue: 'YOUR_CLIENT_ID_HERE', // Replace in development
  );

  /// Spotify Client Secret - Set via environment variable in production
  static const String spotifyClientSecret = String.fromEnvironment(
    'SPOTIFY_CLIENT_SECRET',
    defaultValue: 'YOUR_CLIENT_SECRET_HERE', // Replace in development
  );

  /// Development redirect URI
  static const String devRedirectUri = 'http://localhost:5000/callback';

  /// Production redirect URI
  static const String prodRedirectUri =
      'https://spotify-looper-cc1ad.web.app/callback';

  /// Get the appropriate redirect URI based on environment
  static String get redirectUri {
    return const bool.fromEnvironment('dart.vm.product')
        ? prodRedirectUri
        : devRedirectUri;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // API Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// Spotify Authorization URL
  static const String spotifyAuthUrl = 'https://accounts.spotify.com';

  /// Spotify Web API base URL
  static const String spotifyApiUrl = 'https://api.spotify.com/v1';

  // ══════════════════════════════════════════════════════════════════════════
  // OAuth Scopes
  // ══════════════════════════════════════════════════════════════════════════

  /// Required OAuth scopes for Spotify API access
  static const List<String> scopes = [
    'user-read-email',
    'user-read-private',
    'user-library-read',
    'user-library-modify',
    'user-read-playback-state',
    'user-modify-playback-state',
    'user-read-currently-playing',
    'streaming',
    'user-read-recently-played',
    'playlist-read-private',
  ];

  /// Scopes as a space-separated string for OAuth URL
  static String get scopesString => scopes.join(' ');

  // ══════════════════════════════════════════════════════════════════════════
  // App Info
  // ══════════════════════════════════════════════════════════════════════════

  /// App name
  static const String appName = 'Spotify Looper';

  /// App version
  static const String appVersion = '1.0.0';
}
