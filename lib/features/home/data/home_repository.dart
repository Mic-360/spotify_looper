import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/track.dart';
import '../../../shared/repositories/spotify_api_client.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider for the Home Repository.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final apiClient = ref.watch(spotifyApiClientProvider);
  return HomeRepository(apiClient);
});

/// Future provider for recently played tracks.
final recentlyPlayedProvider = FutureProvider<List<Track>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getRecentlyPlayed();
});

class HomeRepository {
  final SpotifyApiClient _apiClient;

  HomeRepository(this._apiClient);

  Future<List<Track>> getRecentlyPlayed() async {
    return await _apiClient.getRecentlyPlayed();
  }
}
