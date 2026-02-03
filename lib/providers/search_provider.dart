/// Search provider for Spotify track search.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import '../services/spotify_api_service.dart';
import 'auth_provider.dart';

/// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search results provider with debouncing
final searchResultsProvider = FutureProvider<List<SpotifyTrack>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final token = ref.watch(accessTokenProvider);

  if (query.isEmpty || token == null) {
    return [];
  }

  // Debounce by waiting a bit before searching
  await Future.delayed(const Duration(milliseconds: 300));

  // Check if query changed during debounce
  if (ref.read(searchQueryProvider) != query) {
    return [];
  }

  try {
    final api = SpotifyApiService(token);
    return await api.searchTracks(query, limit: 20);
  } catch (e) {
    return [];
  }
});

/// Search loading state
final isSearchingProvider = Provider<bool>((ref) {
  final query = ref.watch(searchQueryProvider);
  final results = ref.watch(searchResultsProvider);

  return query.isNotEmpty && results.isLoading;
});

/// Search state notifier for more complex search management
class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  Timer? _debounceTimer;

  SearchNotifier(this._ref) : super(SearchState.initial);

  void updateQuery(String query) {
    state = state.copyWith(query: query, isLoading: query.isNotEmpty);

    _debounceTimer?.cancel();

    if (query.isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final token = _ref.read(accessTokenProvider);

    if (token == null) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }

    try {
      final api = SpotifyApiService(token);
      final results = await api.searchTracks(query, limit: 20);

      // Only update if query hasn't changed
      if (state.query == query) {
        state = state.copyWith(results: results, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = SearchState.initial;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

class SearchState {
  final String query;
  final List<SpotifyTrack> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  static const SearchState initial = SearchState();

  SearchState copyWith({
    String? query,
    List<SpotifyTrack>? results,
    bool? isLoading,
    String? error,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
      return SearchNotifier(ref);
    });
