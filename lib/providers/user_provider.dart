/// User data providers for fetching Spotify user information.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import '../services/spotify_api_service.dart';
import 'auth_provider.dart';

/// Provider for Spotify API service
final spotifyApiProvider = Provider<SpotifyApiService?>((ref) {
  final token = ref.watch(accessTokenProvider);
  if (token == null) return null;
  return SpotifyApiService(token);
});

/// Provider for user's top tracks
final topTracksProvider = FutureProvider<List<SpotifyTrack>>((ref) async {
  final api = ref.watch(spotifyApiProvider);
  if (api == null) return [];

  try {
    return await api.getTopTracks(limit: 10);
  } catch (e) {
    return [];
  }
});

/// Provider for recently played tracks
final recentlyPlayedProvider = FutureProvider<List<SpotifyTrack>>((ref) async {
  final api = ref.watch(spotifyApiProvider);
  if (api == null) return [];

  try {
    return await api.getRecentlyPlayed(limit: 10);
  } catch (e) {
    return [];
  }
});

/// Provider for saved tracks (library)
final savedTracksProvider = FutureProvider<List<SpotifyTrack>>((ref) async {
  final api = ref.watch(spotifyApiProvider);
  if (api == null) return [];

  try {
    return await api.getSavedTracks(limit: 20);
  } catch (e) {
    return [];
  }
});

/// Provider for user's playlists
final playlistsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.watch(spotifyApiProvider);
  if (api == null) return [];

  try {
    return await api.getPlaylists(limit: 10);
  } catch (e) {
    return [];
  }
});

/// Provider for followed artists
final followedArtistsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.watch(spotifyApiProvider);
  if (api == null) return [];

  try {
    return await api.getFollowedArtists(limit: 10);
  } catch (e) {
    return [];
  }
});

/// Provider for available devices
final devicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(spotifyApiProvider);
  if (api == null) return [];

  try {
    return await api.getDevices();
  } catch (e) {
    return [];
  }
});

/// Provider for current playback state
final currentPlaybackProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final api = ref.watch(spotifyApiProvider);
  if (api == null) return null;

  try {
    return await api.getCurrentPlayback();
  } catch (e) {
    return null;
  }
});

/// Stats provider for user statistics
final userStatsProvider = Provider<UserStats>((ref) {
  final topTracks = ref.watch(topTracksProvider);
  final recentlyPlayed = ref.watch(recentlyPlayedProvider);
  final playlists = ref.watch(playlistsProvider);
  final followedArtists = ref.watch(followedArtistsProvider);

  return UserStats(
    topTracksCount: topTracks.valueOrNull?.length ?? 0,
    recentlyPlayedCount: recentlyPlayed.valueOrNull?.length ?? 0,
    playlistsCount: playlists.valueOrNull?.length ?? 0,
    followedArtistsCount: followedArtists.valueOrNull?.length ?? 0,
  );
});

class UserStats {
  final int topTracksCount;
  final int recentlyPlayedCount;
  final int playlistsCount;
  final int followedArtistsCount;

  const UserStats({
    this.topTracksCount = 0,
    this.recentlyPlayedCount = 0,
    this.playlistsCount = 0,
    this.followedArtistsCount = 0,
  });
}
