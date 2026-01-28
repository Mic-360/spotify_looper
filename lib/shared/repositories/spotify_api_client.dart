import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../features/auth/data/spotify_auth_repository.dart';
import '../models/track.dart';

/// Client for interacting with the Spotify Web API.
class SpotifyApiClient {
  final Dio _dio;
  final SpotifyAuthRepository _authRepository;

  SpotifyApiClient(this._dio, this._authRepository) {
    _dio.options.baseUrl = AppConfig.spotifyApiUrl;

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authRepository.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token might be expired, try refreshing
            final token = await _authRepository.refreshToken();
            if (token != null) {
              // Retry the request with the new token
              final opts = e.requestOptions;
              opts.headers['Authorization'] = 'Bearer $token';
              final cloneReq = await _dio.request(
                opts.path,
                options: Options(method: opts.method, headers: opts.headers),
                data: opts.data,
                queryParameters: opts.queryParameters,
              );
              return handler.resolve(cloneReq);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Gets the current user's recently played tracks.
  Future<List<Track>> getRecentlyPlayed() async {
    try {
      final response = await _dio.get('/me/player/recently-played');
      final List items = response.data['items'];
      return items.map((item) => Track.fromJson(item['track'])).toList();
    } catch (e) {
      throw Exception('Failed to get recently played tracks: $e');
    }
  }

  /// Gets the current user's profile.
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/me');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Searches for tracks.
  Future<List<Track>> searchTracks(String query) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {'q': query, 'type': 'track', 'limit': 20},
      );

      final List items = response.data['tracks']['items'];
      return items.map((item) => Track.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to search tracks: $e');
    }
  }

  /// Skips to a position in the current track.
  Future<void> seekToPosition(int positionMs) async {
    try {
      await _dio.put(
        '/me/player/seek',
        queryParameters: {'position_ms': positionMs},
      );
    } catch (e) {
      throw Exception('Failed to seek: $e');
    }
  }

  /// Controls playback (play/pause).
  Future<void> setPlaybackState(bool play) async {
    try {
      final endpoint = play ? '/me/player/play' : '/me/player/pause';
      await _dio.put(endpoint);
    } catch (e) {
      // Might fail if no active device is found
      throw Exception('Failed to change playback state: $e');
    }
  }
}
