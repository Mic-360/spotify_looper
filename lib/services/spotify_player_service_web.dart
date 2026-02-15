/// Spotify Player Service for Web
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import '../models/player_state.dart';

/// Service for managing Spotify Web Playback SDK
class SpotifyPlayerService {
  static SpotifyPlayerService? _instance;

  String? _deviceId;
  bool _isReady = false;

  final _stateController = StreamController<PlayerState>.broadcast();
  final _readyController = StreamController<bool>.broadcast();

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

  /// Initialize the Spotify Web Playback SDK
  Future<void> initialize(String accessToken) async {
    // Web-only check is implicit since this file is only imported on web
    debugPrint('SpotifyPlayerService (Web): Initializing with token');

    try {
      final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
      if (spotifyLooper == null) {
        debugPrint(
          'SpotifyPlayerService (Web): window.spotifyLooper not found',
        );
        return;
      }

      // 1. Set the access token
      spotifyLooper['accessToken'] = accessToken.toJS;

      // 2. Set the callbacks
      spotifyLooper['onReadyCallback'] = ((JSString deviceId) {
        _onPlayerReady(deviceId.toDart);
      }).toJS;

      spotifyLooper['onStateChangedCallback'] = ((JSObject? state) {
        _onPlayerStateChanged(state);
      }).toJS;

      spotifyLooper['onErrorCallback'] = ((JSString message) {
        _onPlayerError(message.toDart);
      }).toJS;

      // 3. Initialize or Trigger initialization
      if (globalContext['Spotify'] != null) {
        debugPrint(
          'SpotifyPlayerService (Web): Spotify SDK found, calling _initPlayer',
        );
        spotifyLooper.callMethod(
          '_initPlayer'.toJS,
          'Pulse Loop'.toJS,
          accessToken.toJS,
        );
      } else {
        debugPrint(
          'SpotifyPlayerService (Web): Waiting for Spotify SDK (onSpotifyWebPlaybackSDKReady)',
        );
      }
    } catch (e) {
      debugPrint('SpotifyPlayerService (Web): Error initializing: $e');
    }
  }

  /// Update the access token used by the SDK
  void updateToken(String token) {
    try {
      final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
      if (spotifyLooper != null) {
        spotifyLooper['accessToken'] = token.toJS;
        debugPrint('SpotifyPlayerService (Web): Token updated');
      }
    } catch (e) {
      debugPrint('SpotifyPlayerService (Web): Error updating token: $e');
    }
  }

  void _onPlayerReady(String deviceId) {
    _deviceId = deviceId;
    _isReady = true;
    _readyController.add(true);
    debugPrint(
      'SpotifyPlayerService (Web): Player ready with device ID: $deviceId',
    );
  }

  void _onPlayerStateChanged(JSObject? state) {
    if (state == null) {
      _currentState = PlayerState.initial;
      _stateController.add(_currentState);
      return;
    }

    try {
      // Parse state object
      final paused = state['paused'] as JSBoolean?;
      final isPaused = paused?.toDart ?? false;

      final position = state['position'] as JSNumber?;
      final positionMs = position?.toDartDouble.toInt() ?? 0;

      final duration = state['duration'] as JSNumber?;
      final durationMs = duration?.toDartDouble.toInt() ?? 0;

      // Track info
      String? trackName;
      String? artistName;
      String? trackUri;
      String? albumArtUrl;

      final trackWindow = state['track_window'] as JSObject?;
      if (trackWindow != null) {
        final currentTrack = trackWindow['current_track'] as JSObject?;
        if (currentTrack != null) {
          trackName = (currentTrack['name'] as JSString?)?.toDart;
          trackUri = (currentTrack['uri'] as JSString?)?.toDart;

          final artists = currentTrack['artists'] as JSArray?;
          if (artists != null && artists.length > 0) {
            final artistsList = artists.toDart;
            final firstArtist = artistsList[0] as JSObject?;
            artistName = (firstArtist?['name'] as JSString?)?.toDart;
          }

          final album = currentTrack['album'] as JSObject?;
          if (album != null) {
            final images = album['images'] as JSArray?;
            if (images != null && images.length > 0) {
              final imagesList = images.toDart;
              final firstImage = imagesList[0] as JSObject?;
              albumArtUrl = (firstImage?['url'] as JSString?)?.toDart;
            }
          }
        }
      }

      _currentState = PlayerState(
        isPlaying: !isPaused,
        isPaused: isPaused,
        positionMs: positionMs,
        durationMs: durationMs,
        trackName: trackName,
        artistName: artistName,
        trackUri: trackUri,
        albumArtUrl: albumArtUrl,
      );

      _stateController.add(_currentState);
      debugPrint(
        'SpotifyPlayerService (Web): State updated: ${!isPaused ? 'Playing' : 'Paused'} - $trackName',
      );
    } catch (e) {
      debugPrint('SpotifyPlayerService (Web): Error parsing state: $e');
    }
  }

  void _onPlayerError(String message) {
    debugPrint('SpotifyPlayerService (Web): SDK Error: $message');
    // If it's a "Device went offline" error, we should probably reset state
    if (message.contains('offline')) {
      _isReady = false;
      _readyController.add(false);
    }
  }

  /// Play a track by URI
  Future<void> play(String uri) async {
    if (!_isReady || _deviceId == null) {
      debugPrint('SpotifyPlayerService (Web): Player not ready');
      return;
    }

    debugPrint('SpotifyPlayerService (Web): Playing $uri on device $_deviceId');

    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    if (spotifyLooper != null) {
      spotifyLooper.callMethod('play'.toJS, _deviceId!.toJS, uri.toJS);
    }
  }

  /// Resume playback
  Future<void> resume() async {
    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    spotifyLooper?.callMethod('resume'.toJS);
  }

  /// Pause playback
  Future<void> pause() async {
    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    spotifyLooper?.callMethod('pause'.toJS);
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    spotifyLooper?.callMethod('togglePlayPause'.toJS);
  }

  /// Seek to position
  Future<void> seek(int positionMs) async {
    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    if (spotifyLooper != null) {
      spotifyLooper.callMethod('seek'.toJS, positionMs.toJS);
    }
  }

  /// Skip to next track
  Future<void> skipNext() async {
    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    if (spotifyLooper != null) {
      spotifyLooper.callMethod('skipNext'.toJS);
    }
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    if (spotifyLooper != null) {
      spotifyLooper.callMethod('skipPrevious'.toJS);
    }
  }

  /// Set repeat mode
  Future<void> setRepeatMode(SpotifyRepeatMode mode) async {
    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    if (spotifyLooper != null) {
      spotifyLooper.callMethod('setRepeatMode'.toJS, mode.name.toJS);
    }
  }

  /// Set shuffle mode
  Future<void> setShuffle(bool enabled) async {
    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    if (spotifyLooper != null) {
      spotifyLooper.callMethod('setShuffle'.toJS, enabled.toJS);
    }
  }

  /// Disconnect and cleanup
  void dispose() {
    final spotifyLooper = globalContext['spotifyLooper'] as JSObject?;
    spotifyLooper?.callMethod('disconnect'.toJS);
    _stateController.close();
    _readyController.close();
  }
}
