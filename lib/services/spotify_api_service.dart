/// Spotify Web API service for fetching user data and searching.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../models/user_profile.dart';

class SpotifyPlayback {
  final int progressMs;
  final bool isPlaying;
  final String? trackUri;

  SpotifyPlayback({
    required this.progressMs,
    required this.isPlaying,
    this.trackUri,
  });

  factory SpotifyPlayback.fromJson(Map<String, dynamic> json) {
    return SpotifyPlayback(
      progressMs: json['progress_ms'] as int? ?? 0,
      isPlaying: json['is_playing'] as bool? ?? false,
      trackUri: ((json['item'] as Map<String, dynamic>?)?['uri']) as String?,
    );
  }
}

class SpotifyApiService {
  static const String _baseUrl = 'https://api.spotify.com/v1';

  final String accessToken;

  SpotifyApiService(this.accessToken);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  /// Get current user's profile
  Future<SpotifyUserProfile> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw SpotifyApiException('Failed to get user profile: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return SpotifyUserProfile.fromJson(data);
  }

  /// Search for tracks
  Future<List<SpotifyTrack>> searchTracks(
    String query, {
    int limit = 20,
  }) async {
    if (query.isEmpty) return [];

    final response = await http.get(
      Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': query,
          'type': 'track',
          'limit': limit.toString(),
        },
      ),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw SpotifyApiException('Search failed: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final tracks = data['tracks']['items'] as List<dynamic>;

    return tracks
        .map((t) => SpotifyTrack.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// Get user's top tracks
  Future<List<SpotifyTrack>> getTopTracks({
    int limit = 20,
    String timeRange = 'medium_term',
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me/top/tracks').replace(
        queryParameters: {'limit': limit.toString(), 'time_range': timeRange},
      ),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw SpotifyApiException('Failed to get top tracks: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    return items
        .map((t) => SpotifyTrack.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// Get user's recently played tracks
  Future<List<SpotifyTrack>> getRecentlyPlayed({int limit = 20}) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/me/player/recently-played',
      ).replace(queryParameters: {'limit': limit.toString()}),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw SpotifyApiException(
        'Failed to get recently played: ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    return items
        .map(
          (item) =>
              SpotifyTrack.fromJson(item['track'] as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get user's saved tracks (library)
  Future<List<SpotifyTrack>> getSavedTracks({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me/tracks').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      ),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw SpotifyApiException('Failed to get saved tracks: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    return items
        .map(
          (item) =>
              SpotifyTrack.fromJson(item['track'] as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get user's playlists
  Future<List<Map<String, dynamic>>> getPlaylists({int limit = 20}) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/me/playlists',
      ).replace(queryParameters: {'limit': limit.toString()}),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw SpotifyApiException('Failed to get playlists: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Get user's followed artists
  Future<List<Map<String, dynamic>>> getFollowedArtists({
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/me/following',
      ).replace(queryParameters: {'type': 'artist', 'limit': limit.toString()}),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw SpotifyApiException(
        'Failed to get followed artists: ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return (data['artists']['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  /// Get current playback state
  Future<Map<String, dynamic>?> getCurrentPlayback() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me/player'),
      headers: _headers,
    );

    if (response.statusCode == 204) {
      return null; // No active playback
    }

    if (response.statusCode != 200) {
      throw SpotifyApiException(
        'Failed to get playback state: ${response.body}',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Get simplified playback state
  Future<SpotifyPlayback?> getPlaybackState() async {
    final data = await getCurrentPlayback();
    if (data == null) return null;
    return SpotifyPlayback.fromJson(data);
  }

  /// Get available devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me/player/devices'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw SpotifyApiException('Failed to get devices: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return (data['devices'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Start/resume playback
  Future<void> play({
    String? deviceId,
    String? contextUri,
    List<String>? uris,
  }) async {
    final uri = Uri.parse('$_baseUrl/me/player/play').replace(
      queryParameters: deviceId != null ? {'device_id': deviceId} : null,
    );

    Map<String, dynamic>? body;
    if (contextUri != null) {
      body = {'context_uri': contextUri};
    } else if (uris != null && uris.isNotEmpty) {
      body = {'uris': uris};
    }

    final response = await http.put(
      uri,
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw SpotifyApiException('Failed to start playback: ${response.body}');
    }
  }

  /// Pause playback
  Future<void> pause({String? deviceId}) async {
    final uri = Uri.parse('$_baseUrl/me/player/pause').replace(
      queryParameters: deviceId != null ? {'device_id': deviceId} : null,
    );

    final response = await http.put(uri, headers: _headers);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw SpotifyApiException('Failed to pause playback: ${response.body}');
    }
  }

  /// Skip to next track
  Future<void> skipToNext({String? deviceId}) async {
    final uri = Uri.parse('$_baseUrl/me/player/next').replace(
      queryParameters: deviceId != null ? {'device_id': deviceId} : null,
    );

    final response = await http.post(uri, headers: _headers);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw SpotifyApiException('Failed to skip to next: ${response.body}');
    }
  }

  /// Skip to previous track
  Future<void> skipToPrevious({String? deviceId}) async {
    final uri = Uri.parse('$_baseUrl/me/player/previous').replace(
      queryParameters: deviceId != null ? {'device_id': deviceId} : null,
    );

    final response = await http.post(uri, headers: _headers);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw SpotifyApiException('Failed to skip to previous: ${response.body}');
    }
  }

  /// Transfer playback to a device
  Future<void> transferPlayback(String deviceId, {bool play = true}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/me/player'),
      headers: _headers,
      body: json.encode({
        'device_ids': [deviceId],
        'play': play,
      }),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw SpotifyApiException(
        'Failed to transfer playback: ${response.body}',
      );
    }
  }

  /// Seek to position
  Future<void> seek(int positionMs, {String? deviceId}) async {
    final uri = Uri.parse('$_baseUrl/me/player/seek').replace(
      queryParameters: {
        'position_ms': positionMs.toString(),
        if (deviceId != null) 'device_id': deviceId,
      },
    );

    final response = await http.put(uri, headers: _headers);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw SpotifyApiException('Failed to seek: ${response.body}');
    }
  }
}

class SpotifyApiException implements Exception {
  final String message;

  SpotifyApiException(this.message);

  @override
  String toString() => 'SpotifyApiException: $message';
}
