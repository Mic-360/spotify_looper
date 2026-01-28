import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/playback_mode.dart';
import '../../../shared/models/track.dart';
import '../../../shared/repositories/spotify_api_client.dart';
import '../../auth/providers/auth_provider.dart';

/// State notifier provider for playback state.
final playbackStateProvider = StateNotifierProvider<PlaybackStateNotifier, PlaybackState>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return PlaybackStateNotifier(repo);
});

/// Provider for the Player Repository.
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final apiClient = ref.watch(spotifyApiClientProvider);
  return PlayerRepository(apiClient);
});

class PlaybackState {
  final Track? currentTrack;
  final bool isPlaying;
  final Duration position;
  final PlaybackMode mode;
  final SectionMarker? section;

  PlaybackState({
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.mode = PlaybackMode.normal,
    this.section,
  });

  PlaybackState copyWith({
    Track? currentTrack,
    bool? isPlaying,
    Duration? position,
    PlaybackMode? mode,
    SectionMarker? section,
  }) {
    return PlaybackState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      mode: mode ?? this.mode,
      section: section ?? this.section,
    );
  }
}

class PlaybackStateNotifier extends StateNotifier<PlaybackState> {
  final PlayerRepository _repo;
  Timer? _positionTimer;

  PlaybackStateNotifier(this._repo) : super(PlaybackState());

  @override
  void dispose() {
    _stopPositionTimer();
    super.dispose();
  }

  Future<void> playTrack(Track track) async {
    state = state.copyWith(currentTrack: track, isPlaying: true, position: Duration.zero);
    await _repo.play(track.spotifyUri);
    _startPositionTimer();
  }

  void seek(Duration position) async {
    state = state.copyWith(position: position);
    await _repo.seek(position.inMilliseconds);
  }

  void setMode(PlaybackMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setSection(SectionMarker section) {
    state = state.copyWith(section: section);
  }

  void togglePlay() async {
    final newState = !state.isPlaying;
    state = state.copyWith(isPlaying: newState);
    await _repo.setPlayback(newState);
    if (newState) {
      _startPositionTimer();
    } else {
      _stopPositionTimer();
    }
  }

  void _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPlaying && state.currentTrack != null) {
        final nextPosition = state.position + const Duration(seconds: 1);

        // Handle Loop Mode
        if (state.mode == PlaybackMode.loop && state.section != null) {
          if (nextPosition >= state.section!.endTime) {
            seek(state.section!.startTime);
            return;
          }
        }

        // Handle Skip Mode
        if (state.mode == PlaybackMode.skip && state.section != null) {
          if (nextPosition >= state.section!.startTime && nextPosition < state.section!.endTime) {
            seek(state.section!.endTime);
            return;
          }
        }

        if (nextPosition <= state.currentTrack!.duration) {
          state = state.copyWith(position: nextPosition);
        } else {
          _stopPositionTimer();
          state = state.copyWith(isPlaying: false, position: Duration.zero);
        }
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
  }
}

class PlayerRepository {
  final SpotifyApiClient _apiClient;

  PlayerRepository(this._apiClient);

  Future<void> play(String uri) async {
    // This requires an active device. In a real app, we'd transfer playback first.
    await _apiClient.setPlaybackState(true);
  }

  Future<void> seek(int positionMs) async {
    await _apiClient.seekToPosition(positionMs);
  }

  Future<void> setPlayback(bool play) async {
    await _apiClient.setPlaybackState(play);
  }
}
