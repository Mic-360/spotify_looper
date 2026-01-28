import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/repositories/spotify_api_client.dart';
import '../data/spotify_auth_repository.dart';

/// Provider for the Spotify Auth Repository.
final authRepositoryProvider = Provider<SpotifyAuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SpotifyAuthRepository(dio, prefs);
});

/// Provider for the authentication state.
final authStateProvider = StateProvider<bool>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.isLoggedIn;
});

/// Provider for the Dio instance.
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

/// Provider for SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});

/// Provider for the Spotify API Client.
final spotifyApiClientProvider = Provider<SpotifyApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return SpotifyApiClient(dio, authRepo);
});
