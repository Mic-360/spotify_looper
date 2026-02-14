/// Media Session API service for lock screen / OS media controls (Web Implementation).
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

import '../models/track.dart';
import '../providers/player_provider.dart';

class MediaSessionService {
  MediaSessionService._();
  static final instance = MediaSessionService._();

  /// Update lock screen / OS media session with current track info and mode
  void updateMetadata(
    SpotifyTrack track, {
    PlayerMode mode = PlayerMode.normal,
  }) {
    // implicit kIsWeb check by file import
    try {
      final navigator = globalContext['navigator'] as JSObject?;
      if (navigator == null) return;

      final mediaSession = navigator['mediaSession'] as JSObject?;
      if (mediaSession == null) return;

      // Build the mode label
      final modeLabel = switch (mode) {
        PlayerMode.loop => 'Looping',
        PlayerMode.skip => 'Skipping',
        PlayerMode.normal => '',
      };

      // Build title: "Song Name" or "Song Name • Looping"
      final title = modeLabel.isNotEmpty
          ? '${track.name} • $modeLabel'
          : track.name;

      // Create MediaMetadata
      final metadataInit = JSObject();
      metadataInit['title'] = title.toJS;
      metadataInit['artist'] = track.artistNames.toJS;
      metadataInit['album'] = track.album.name.toJS;

      // Build artwork array
      final artworkList = JSArray();
      if (track.artworkUrl != null) {
        final artwork = JSObject();
        artwork['src'] = track.artworkUrl!.toJS;
        artwork['sizes'] = '300x300'.toJS;
        artwork['type'] = 'image/jpeg'.toJS;
        artworkList.add(artwork);
      }

      if (artworkList.length > 0) {
        metadataInit['artwork'] = artworkList;
      }

      // Create new MediaMetadata instance
      final mediaMetadataConstructor =
          globalContext['MediaMetadata'] as JSFunction?;
      if (mediaMetadataConstructor != null) {
        final metadata = mediaMetadataConstructor.callAsConstructor(
          metadataInit,
        );
        mediaSession['metadata'] = metadata;
        debugPrint(
          'MediaSession: Updated metadata - $title by ${track.artistNames}',
        );
      }
    } catch (e) {
      debugPrint('MediaSession: Error updating metadata: $e');
    }
  }

  /// Update playback state (position, duration, playback rate)
  void updatePlaybackState({
    required bool isPlaying,
    required int positionMs,
    required int durationMs,
  }) {
    try {
      final navigator = globalContext['navigator'] as JSObject?;
      if (navigator == null) return;

      final mediaSession = navigator['mediaSession'] as JSObject?;
      if (mediaSession == null) return;

      // Set playback state
      mediaSession['playbackState'] = (isPlaying ? 'playing' : 'paused').toJS;

      // Try to set position state if available
      try {
        final positionState = JSObject();
        positionState['duration'] = (durationMs / 1000.0).toJS;
        positionState['position'] = (positionMs / 1000.0).toJS;
        positionState['playbackRate'] = 1.0.toJS;

        mediaSession.callMethod('setPositionState'.toJS, positionState);
      } catch (_) {
        // setPositionState may not be supported in all browsers
      }
    } catch (e) {
      debugPrint('MediaSession: Error updating playback state: $e');
    }
  }

  /// Set action handlers for media session controls
  void setActionHandlers({
    required VoidCallback onPlay,
    required VoidCallback onPause,
    required VoidCallback onNextTrack,
    required VoidCallback onPreviousTrack,
  }) {
    try {
      final navigator = globalContext['navigator'] as JSObject?;
      if (navigator == null) return;

      final mediaSession = navigator['mediaSession'] as JSObject?;
      if (mediaSession == null) return;

      _setActionHandler(mediaSession, 'play', onPlay);
      _setActionHandler(mediaSession, 'pause', onPause);
      _setActionHandler(mediaSession, 'nexttrack', onNextTrack);
      _setActionHandler(mediaSession, 'previoustrack', onPreviousTrack);

      debugPrint('MediaSession: Action handlers set');
    } catch (e) {
      debugPrint('MediaSession: Error setting action handlers: $e');
    }
  }

  void _setActionHandler(
    JSObject mediaSession,
    String action,
    VoidCallback callback,
  ) {
    mediaSession.callMethod(
      'setActionHandler'.toJS,
      action.toJS,
      (() {
        callback();
      }).toJS,
    );
  }

  /// Clear metadata
  void clear() {
    try {
      final navigator = globalContext['navigator'] as JSObject?;
      if (navigator == null) return;

      final mediaSession = navigator['mediaSession'] as JSObject?;
      if (mediaSession == null) return;

      mediaSession['metadata'] = null;
    } catch (e) {
      debugPrint('MediaSession: Error clearing metadata: $e');
    }
  }
}
