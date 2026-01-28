import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/repositories/spotify_api_client.dart';
import '../../../shared/models/track.dart';

/// Provider for the Search Repository.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final apiClient = ref.watch(spotifyApiClientProvider);
  return SearchRepository(apiClient);
});

/// Provider for search results.
final searchResultsProvider = FutureProvider.family<List<Track>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(searchRepositoryProvider);
  return repo.search(query);
});

class SearchRepository {
  final SpotifyApiClient _apiClient;

  SearchRepository(this._apiClient);

  Future<List<Track>> search(String query) async {
    return await _apiClient.searchTracks(query);
  }
}
