import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import '../services/media_session_service.dart';
import '../services/spotify_api_service.dart';
import '../services/spotify_player_service.dart';
import 'auth_provider.dart';

enum PlayerMode { normal, loop, skip }

/// Player state
class PlaybackState {
  final bool isPlaying;
  final bool isPaused;
  final SpotifyTrack? currentTrack;
  final int positionMs;
  final int durationMs;
  final String? deviceId;
  final bool isWebPlayer;
  final String? error;
  final PlayerMode mode;
  final int loopStartMs;
  final int loopEndMs;
  final SpotifyRepeatMode repeatMode;
  final bool shuffleEnabled;

  const PlaybackState({
    this.isPlaying = false,
    this.isPaused = false,
    this.currentTrack,
    this.positionMs = 0,
    this.durationMs = 0,
    this.deviceId,
    this.isWebPlayer = false,
    this.error,
    this.mode = PlayerMode.normal,
    this.loopStartMs = 0,
    this.loopEndMs = 0,
    this.repeatMode = SpotifyRepeatMode.off,
    this.shuffleEnabled = false,
  });

  double get progress => durationMs > 0 ? positionMs / durationMs : 0;

  String get formattedPosition {
    final minutes = positionMs ~/ 60000;
    final seconds = (positionMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDuration {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  PlaybackState copyWith({
    bool? isPlaying,
    bool? isPaused,
    SpotifyTrack? currentTrack,
    int? positionMs,
    int? durationMs,
    String? deviceId,
    bool? isWebPlayer,
    String? error,
    PlayerMode? mode,
    int? loopStartMs,
    int? loopEndMs,
    SpotifyRepeatMode? repeatMode,
    bool? shuffleEnabled,
  }) => PlaybackState(
    isPlaying: isPlaying ?? this.isPlaying,
    isPaused: isPaused ?? this.isPaused,
    currentTrack: currentTrack ?? this.currentTrack,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    deviceId: deviceId ?? this.deviceId,
    isWebPlayer: isWebPlayer ?? this.isWebPlayer,
    error: error ?? this.error,
    mode: mode ?? this.mode,
    loopStartMs: loopStartMs ?? this.loopStartMs,
    loopEndMs: loopEndMs ?? this.loopEndMs,
    repeatMode: repeatMode ?? this.repeatMode,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
  );

  static const PlaybackState initial = PlaybackState();
}

class PlayerNotifier extends StateNotifier<PlaybackState> {
  final Ref _ref;
  Timer? _playbackTimer;
  DateTime? _lastStateUpdateTime;
  int _statePositionAtUpdate = 0;

  PlayerNotifier(this._ref) : super(PlaybackState.initial) {
    _initializeServiceListeners();
    _setupMediaSessionHandlers();
  }

  /// Set up lock screen media controls
  void _setupMediaSessionHandlers() {
    if (!kIsWeb) return;
    MediaSessionService.instance.setActionHandlers(
      onPlay: () => togglePlayPause(),
      onPause: () => togglePlayPause(),
      onNextTrack: () => skipNext(),
      onPreviousTrack: () => skipPrevious(),
    );
  }

  void _initializeServiceListeners() {
    // Listen to token changes and update service
    _ref.listen<String?>(accessTokenProvider, (previous, next) {
      if (next != null && next != previous) {
        SpotifyPlayerService.instance.updateToken(next);
      }
    });

    // Listen to player state changes
    SpotifyPlayerService.instance.stateStream.listen((playerState) {
      _lastStateUpdateTime = DateTime.now();
      _statePositionAtUpdate = playerState.positionMs;

      // Handle track change from external source (e.g. Spotify app)
      if (playerState.trackUri != null &&
          playerState.trackUri != state.currentTrack?.uri) {
        _handleTrackChange(playerState.trackUri!);
      }

      state = state.copyWith(
        isPlaying: playerState.isPlaying,
        isPaused: playerState.isPaused,
        positionMs: playerState.positionMs,
        durationMs: playerState.durationMs > 0
            ? playerState.durationMs
            : state.durationMs,
        repeatMode: playerState.repeatMode,
        shuffleEnabled: playerState.shuffleEnabled,
        // We consider it "web player" mode if driven by SDK,
        // to avoid polling API. Maybe rename isWebPlayer to isSdkPlayer later.
        isWebPlayer: true,
      );

      _updateTimer();
      _handlePlaybackLogic();
    });

    // Listen for device ID (Web) or general readiness (Mobile)
    SpotifyPlayerService.instance.readyStream.listen((isReady) async {
      if (isReady) {
        final deviceId = SpotifyPlayerService.instance.deviceId;
        if (deviceId != null) {
          state = state.copyWith(deviceId: deviceId, isWebPlayer: true);

          // Transfer playback to this new device (mainly for Web)
          final token = _ref.read(accessTokenProvider);
          if (kIsWeb && token != null) {
            // Only transfer on web automatically for now
            try {
              final api = SpotifyApiService(token);
              await api.transferPlayback(deviceId, play: false);
              debugPrint(
                'PlayerProvider: Transferred playback to web player: $deviceId',
              );
            } catch (e) {
              debugPrint('PlayerProvider: Failed to transfer playback: $e');
            }
          }
        } else {
          // Mobile SDK doesn't expose device ID easily, but isReady means we can play
          state = state.copyWith(isWebPlayer: true);
        }
      }
    });
  }

  /// Initialize playback SDK (Web or Mobile)
  Future<void> initializePlayer() async {
    final token = _ref.read(accessTokenProvider);
    if (token == null) return;

    await SpotifyPlayerService.instance.initialize(token);

    if (SpotifyPlayerService.instance.isReady) {
      final deviceId = SpotifyPlayerService.instance.deviceId;
      state = state.copyWith(
        deviceId: deviceId,
        isWebPlayer:
            true, // Treating SDK controlled as "isWebPlayer" for visual logic
      );
    }
  }

  /// Play a track
  Future<void> playTrack(SpotifyTrack track) async {
    final token = _ref.read(accessTokenProvider);
    final user = _ref.read(currentUserProvider);

    if (token == null) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    // Check if user is Premium (required for playback)
    if (user != null && !user.isPremium) {
      state = state.copyWith(
        currentTrack: track,
        error: 'Spotify Premium is required for playback',
      );
      debugPrint('Playback requires Spotify Premium');
      return;
    }

    // Clear any previous error and reset loop range
    // If in Skip mode, start with an empty range to avoid skipping the whole track
    final isSkipMode = state.mode == PlayerMode.skip;
    state = state.copyWith(
      currentTrack: track,
      isPlaying: true,
      isPaused: false,
      error: null,
      loopStartMs: 0,
      durationMs: track.durationMs,
      loopEndMs: isSkipMode ? 0 : track.durationMs,
    );

    // Update lock screen metadata
    MediaSessionService.instance.updateMetadata(track, mode: state.mode);

    if (SpotifyPlayerService.instance.isReady) {
      // Use SDK
      debugPrint('Playing via Spotify SDK');
      await SpotifyPlayerService.instance.play(track.uri);
    } else {
      // Use Spotify Connect API
      debugPrint('Playing via Spotify Connect API');
      try {
        final api = SpotifyApiService(token);
        await api.play(uris: [track.uri], deviceId: state.deviceId);
      } catch (e) {
        debugPrint('Failed to play track: $e');
        final errorMsg = e.toString();
        if (errorMsg.contains('403') || errorMsg.contains('Premium')) {
          state = state.copyWith(
            isPlaying: false,
            error: 'Spotify Premium is required for playback',
          );
        } else if (errorMsg.contains('No active device')) {
          state = state.copyWith(
            isPlaying: false,
            error:
                'No active Spotify device. Open Spotify on another device first.',
          );
        } else {
          state = state.copyWith(isPlaying: false, error: 'Playback error: $e');
        }
      }
    }
    _updateTimer();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    final token = _ref.read(accessTokenProvider);
    if (token == null) return;

    if (SpotifyPlayerService.instance.isReady) {
      await SpotifyPlayerService.instance.togglePlayPause();
    } else {
      final api = SpotifyApiService(token);
      if (state.isPlaying) {
        await api.pause(deviceId: state.deviceId);
        state = state.copyWith(isPlaying: false, isPaused: true);
      } else {
        await api.play(deviceId: state.deviceId);
        state = state.copyWith(isPlaying: true, isPaused: false);
      }
    }
    _updateTimer();
  }

  /// Skip to next track
  Future<void> skipNext() async {
    final token = _ref.read(accessTokenProvider);
    if (token == null) return;

    if (SpotifyPlayerService.instance.isReady) {
      await SpotifyPlayerService.instance.skipNext();
    } else {
      try {
        final api = SpotifyApiService(token);
        await api.skipToNext(deviceId: state.deviceId);
      } catch (e) {
        debugPrint('Failed to skip: $e');
      }
    }
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    final token = _ref.read(accessTokenProvider);
    if (token == null) return;

    if (SpotifyPlayerService.instance.isReady) {
      await SpotifyPlayerService.instance.skipPrevious();
    } else {
      try {
        final api = SpotifyApiService(token);
        await api.skipToPrevious(deviceId: state.deviceId);
      } catch (e) {
        debugPrint('Failed to skip: $e');
      }
    }
  }

  /// Seek to position
  Future<void> seek(int positionMs) async {
    _statePositionAtUpdate = positionMs;
    _lastStateUpdateTime = DateTime.now();
    state = state.copyWith(positionMs: positionMs);

    if (SpotifyPlayerService.instance.isReady) {
      await SpotifyPlayerService.instance.seek(positionMs);
    } else {
      final token = _ref.read(accessTokenProvider);
      if (token != null) {
        try {
          final api = SpotifyApiService(token);
          await api.seek(positionMs, deviceId: state.deviceId);
        } catch (e) {
          debugPrint('PlayerProvider: API seek failed: $e');
        }
      }
    }
  }

  /// Update current track
  void setCurrentTrack(SpotifyTrack track) {
    state = state.copyWith(currentTrack: track);
    MediaSessionService.instance.updateMetadata(track, mode: state.mode);
  }

  /// Handle track change from SDK
  Future<void> _handleTrackChange(String trackUri) async {
    final token = _ref.read(accessTokenProvider);
    if (token == null) return;

    try {
      final api = SpotifyApiService(token);
      final trackId = trackUri.split(':').last;
      final track = await api.getTrack(trackId);
      final isSkipMode = state.mode == PlayerMode.skip;

      state = state.copyWith(
        currentTrack: track,
        durationMs: track.durationMs,
        // If switching to a new track, reset loopEnd if it was the full old track
        loopEndMs: isSkipMode ? state.loopEndMs : track.durationMs,
      );
      MediaSessionService.instance.updateMetadata(track, mode: state.mode);
    } catch (e) {
      debugPrint('PlayerProvider: Failed to fetch track on change: $e');
    }
  }

  /// Set player mode
  void setMode(PlayerMode mode) {
    int startMs = state.loopStartMs;
    int endMs = state.loopEndMs;

    // Handle initial range for different modes
    if (mode == PlayerMode.skip) {
      // When switching to Skip mode, if the range covers the whole track,
      // reset it to 0-0 so it doesn't skip everything immediately.
      if (startMs == 0 && endMs == state.durationMs) {
        startMs = 0;
        endMs = 0;
      }
    } else if (mode == PlayerMode.loop) {
      // When switching to Loop mode, if the range is empty (usually from Skip mode),
      // reset it to the full track.
      if (startMs == endMs) {
        startMs = 0;
        endMs = state.durationMs;
      }
    }

    state = state.copyWith(mode: mode, loopStartMs: startMs, loopEndMs: endMs);

    debugPrint('PlayerProvider: Mode set to $mode (Range: $startMs-$endMs)');
    // Update lock screen to show current mode
    if (state.currentTrack != null) {
      MediaSessionService.instance.updateMetadata(
        state.currentTrack!,
        mode: mode,
      );
    }
  }

  /// Toggle repeat mode
  Future<void> cycleRepeatMode() async {
    SpotifyRepeatMode nextMode;
    switch (state.repeatMode) {
      case SpotifyRepeatMode.off:
        nextMode = SpotifyRepeatMode.context;
        break;
      case SpotifyRepeatMode.context:
        nextMode = SpotifyRepeatMode.track;
        break;
      case SpotifyRepeatMode.track:
        nextMode = SpotifyRepeatMode.off;
        break;
    }

    state = state.copyWith(repeatMode: nextMode);
    await SpotifyPlayerService.instance.setRepeatMode(nextMode);
  }

  /// Toggle shuffle
  Future<void> toggleShuffle() async {
    final nextShuffle = !state.shuffleEnabled;
    state = state.copyWith(shuffleEnabled: nextShuffle);
    await SpotifyPlayerService.instance.setShuffle(nextShuffle);
  }

  /// Set loop range
  void setLoopRange(int startMs, int endMs) {
    state = state.copyWith(loopStartMs: startMs, loopEndMs: endMs);
    debugPrint('PlayerProvider: Loop range set to $startMs - $endMs');
  }

  /// Handle looping and skipping logic
  void _handlePlaybackLogic() {
    if (!state.isPlaying || state.isPaused || state.currentTrack == null) {
      return;
    }

    final pos = state.positionMs;
    final dur = state.durationMs;
    final mode = state.mode;

    // 1. Normal Mode: Loop at the end
    if (mode == PlayerMode.normal) {
      if (dur > 0 && pos >= dur - 500) {
        debugPrint('PlayerProvider: Normal loop trigger at $pos ms / $dur ms');
        seek(0);
      }
    }
    // 2. Loop Mode: Loop between start and end
    else if (mode == PlayerMode.loop) {
      final start = state.loopStartMs;
      final end = state.loopEndMs;

      if (end > start && pos >= end) {
        debugPrint('PlayerProvider: Loop trigger at $pos ms (End was $end ms)');
        seek(start);
      }
    }
    // 3. Skip Mode: Skip between start and end
    else if (mode == PlayerMode.skip) {
      final start = state.loopStartMs;
      final end = state.loopEndMs;

      if (pos >= start && pos < end) {
        debugPrint(
          'PlayerProvider: Skip trigger at $pos ms (Range $start-$end ms)',
        );
        seek(end);
      } else if (dur > 0 && pos >= dur - 500) {
        debugPrint('PlayerProvider: Skip mode end loop at $pos ms / $dur ms');
        seek(0);
      }
    }
  }

  void _updateTimer() {
    _playbackTimer?.cancel();
    if (state.isPlaying && !state.isPaused) {
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (state.isWebPlayer) {
          _estimatePosition();
        } else {
          // Poll API every 2 seconds if not on web player
          if (timer.tick % 20 == 0) {
            _pollPosition();
          } else {
            _estimatePosition();
          }
        }
        _handlePlaybackLogic();
      });
    }
  }

  Future<void> _pollPosition() async {
    final token = _ref.read(accessTokenProvider);
    if (token == null) return;

    try {
      final api = SpotifyApiService(token);
      final playback = await api.getPlaybackState();
      if (playback != null) {
        _lastStateUpdateTime = DateTime.now();
        _statePositionAtUpdate = playback.progressMs;

        state = state.copyWith(
          positionMs: playback.progressMs,
          isPlaying: playback.isPlaying,
        );
        debugPrint('PlayerProvider: Polled position: ${playback.progressMs}ms');
      }
    } catch (e) {
      debugPrint('PlayerProvider: Failed to poll position: $e');
    }
  }

  void _estimatePosition() {
    if (_lastStateUpdateTime == null || state.isPaused || !state.isPlaying) {
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastStateUpdateTime!).inMilliseconds;
    final estimatedPos = _statePositionAtUpdate + elapsed;

    state = state.copyWith(positionMs: estimatedPos);

    // Update lock screen playback position (throttle to every ~2s)
    if (elapsed % 2000 < 150) {
      MediaSessionService.instance.updatePlaybackState(
        isPlaying: state.isPlaying,
        positionMs: estimatedPos,
        durationMs: state.durationMs,
      );
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlaybackState>((
  ref,
) {
  return PlayerNotifier(ref);
});

/// Provider for player ready state
final playerReadyProvider = StreamProvider<bool>((ref) {
  return SpotifyPlayerService.instance.readyStream;
});
