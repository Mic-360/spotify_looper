/// Spotify Player Service for Mobile
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:spotify_sdk/spotify_sdk.dart' hide RepeatMode;
import 'package:spotify_sdk/models/player_state.dart' as sdk;
import 'package:spotify_sdk/models/player_options.dart' as sdk_opt;
import 'package:spotify_sdk/enums/repeat_mode_enum.dart' as sdk_enum;
import '../models/player_state.dart';

import '../core/app_config.dart';

/// Service for managing Spotify SDK on Mobile
class SpotifyPlayerService {
  static SpotifyPlayerService? _instance;

  String?
  _deviceId; // Not strictly used in local playback but kept for API compatibility
  bool _isReady = false;

  final _stateController = StreamController<PlayerState>.broadcast();
  final _readyController = StreamController<bool>.broadcast();
  StreamSubscription<sdk.PlayerState>? _playerSubscription;

  PlayerState _currentState = PlayerState.initial;

  SpotifyPlayerService._();

  static SpotifyPlayerService get instance {
    _instance ??= SpotifyPlayerService._();
    return _instance!;
  }

  String? get deviceId => _deviceId;
  bool get isReady => _isReady;
  Stream<PlayerState> get stateStream => _stateController.stream;
  Stream<bool> get readyStream => _readyController.stream;
  PlayerState get currentState => _currentState;

  /// Initialize the Spotify Mobile SDK
  Future<void> initialize(String accessToken) async {
    debugPrint('SpotifyPlayerService (Mobile): Initializing...');

    try {
      final config = AppConfig.instance;
      // Connect to Spotify App Remote
      // Note: We don't need the token for App Remote connection usually if we use `connectToSpotifyRemote`
      // But we might need to handle the connection result.
      final result = await SpotifySdk.connectToSpotifyRemote(
        clientId: config.spotifyClientId,
        redirectUrl: AppConfig.redirectUriAndroid,
      );

      if (result) {
        _isReady = true;
        _readyController.add(true);
        debugPrint(
          'SpotifyPlayerService (Mobile): Connected to Spotify App Remote',
        );
        _subscribeToPlayerState();
      } else {
        debugPrint(
          'SpotifyPlayerService (Mobile): Failed to connect to Spotify App Remote',
        );
        _isReady = false;
        _readyController.add(false);
      }
    } on PlatformException catch (e) {
      debugPrint(
        'SpotifyPlayerService (Mobile): Error connecting: ${e.message}, code: ${e.code}',
      );
      if (e.code == 'NotLoggedInException') {
        debugPrint(
          'SpotifyPlayerService (Mobile): User not logged in to Spotify App',
        );
      }
      _isReady = false;
      _readyController.add(false);
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): Error initializing: $e');
      _isReady = false;
      _readyController.add(false);
    }
  }

  /// Update the access token used by the SDK
  void updateToken(String token) {
    // Mobile SDK manages its own auth/token via the Spotify App usually,
    // but if we used the web api token, we don't strictly update it here for the App Remote.
    // Kept for interface compatibility.
  }

  void _subscribeToPlayerState() {
    _playerSubscription?.cancel();
    try {
      _playerSubscription = SpotifySdk.subscribePlayerState().listen(
        (sdkState) {
          _onPlayerStateChanged(sdkState);
        },
        onError: (e) {
          debugPrint(
            'SpotifyPlayerService (Mobile): Player state subscription error: $e',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'SpotifyPlayerService (Mobile): Error subscribing to player state: $e',
      );
    }
  }

  void _onPlayerStateChanged(sdk.PlayerState state) {
    try {
      final track = state.track;

      String? trackName;
      String? artistName;
      String? trackUri;
      // String? albumArtUrl; // Unused for now

      if (track != null) {
        trackName = track.name;
        trackUri = track.uri;
        artistName = track.artist.name;
        // Spotify SDK mobile doesn't always give the image URL directly in the track object
        // effectively like the Web SDK. It gives an ImageUri which needs to be converted.
        // For simplicity/speed in this pass, we might miss the album art or need to fetch it separately
        // via the generic API if it's not readily available as a URL string.
        // checking spotify_sdk docs: track.imageUri.raw is a string identifier.
        // We can use SpotifySdk.getImage(imageUri: track.imageUri) to get a Uint8List,
        // but our PlayerState expects a URL string.
        // We might need to rely on the metadata from the Web API in the player provider
        // if this is missing. Or use a placeholder.
        // For now, let's leave valid-looking dummy or try to construct a URL if possible,
        // or just leave null and let Provider fill it from API if needed.
        // Actually, the provider usually has the full track object from API when it starts playing.
      }

      final options = state.playbackOptions;

      // Map repeat mode
      SpotifyRepeatMode repeatMode = SpotifyRepeatMode.off;
      switch (options.repeatMode) {
        case sdk_opt.RepeatMode.off:
          repeatMode = SpotifyRepeatMode.off;
          break;
        case sdk_opt.RepeatMode.track:
          repeatMode = SpotifyRepeatMode.track;
          break;
        case sdk_opt.RepeatMode.context:
          repeatMode = SpotifyRepeatMode.context;
          break;
      }

      _currentState = PlayerState(
        isPlaying: !state.isPaused,
        isPaused: state.isPaused,
        positionMs: state.playbackPosition,
        durationMs: track?.duration ?? 0,
        trackName: trackName,
        artistName: artistName,
        trackUri: trackUri,
        repeatMode: repeatMode,
        shuffleEnabled: options.isShuffling,
      );

      _stateController.add(_currentState);
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): Error parsing state: $e');
    }
  }

  /// Play a track by URI
  Future<void> play(String uri) async {
    try {
      await SpotifySdk.play(spotifyUri: uri);
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): Play error: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await SpotifySdk.resume();
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): Resume error: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await SpotifySdk.pause();
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): Pause error: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    // Determine state and toggle
    if (_currentState.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Seek to position
  Future<void> seek(int positionMs) async {
    try {
      await SpotifySdk.seekTo(positionedMilliseconds: positionMs);
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): Seek error: $e');
    }
  }

  /// Skip to next track
  Future<void> skipNext() async {
    try {
      await SpotifySdk.skipNext();
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): SkipNext error: $e');
    }
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    try {
      await SpotifySdk.skipPrevious();
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): SkipPrevious error: $e');
    }
  }

  /// Set repeat mode
  Future<void> setRepeatMode(SpotifyRepeatMode mode) async {
    try {
      late sdk_enum.RepeatMode sdkMode;
      switch (mode) {
        case SpotifyRepeatMode.off:
          sdkMode = sdk_enum.RepeatMode.off;
          break;
        case SpotifyRepeatMode.track:
          sdkMode = sdk_enum.RepeatMode.track;
          break;
        case SpotifyRepeatMode.context:
          sdkMode = sdk_enum.RepeatMode.context;
          break;
      }
      await SpotifySdk.setRepeatMode(repeatMode: sdkMode);
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): SetRepeatMode error: $e');
    }
  }

  /// Set shuffle
  Future<void> setShuffle(bool enabled) async {
    try {
      await SpotifySdk.setShuffle(shuffle: enabled);
    } catch (e) {
      debugPrint('SpotifyPlayerService (Mobile): SetShuffle error: $e');
    }
  }

  /// Disconnect and cleanup
  void dispose() {
    _playerSubscription?.cancel();
    // SpotifySdk.disconnect(); // Not always needed/exposed depending on version
    _stateController.close();
    _readyController.close();
  }
}
