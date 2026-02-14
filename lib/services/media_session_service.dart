/// Media Session API service for lock screen / OS media controls.
///
/// Sets track metadata (title, artist, album art) so the lock screen
/// shows proper song info instead of "Spotify Embedded Player".
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
    if (!kIsWeb) return;

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

      // Build artwork array
      final artworkList = <JSObject>[];
      if (track.artworkUrl != null) {
        // Create artwork metadata object
        final artwork = _createJsObject({
          'src': track.artworkUrl!,
          'sizes': '300x300',
          'type': 'image/jpeg',
        });
        artworkList.add(artwork);
      }

      // Create MediaMetadata
      final metadataInit = _createJsObject({
        'title': title,
        'artist': track.artistNames,
        'album': track.album.name,
      });

      // Set artwork property separately using JS array
      if (artworkList.isNotEmpty) {
        metadataInit['artwork'] = artworkList.toJS;
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
    if (!kIsWeb) return;

    try {
      final navigator = globalContext['navigator'] as JSObject?;
      if (navigator == null) return;

      final mediaSession = navigator['mediaSession'] as JSObject?;
      if (mediaSession == null) return;

      // Set playback state
      mediaSession['playbackState'] = (isPlaying ? 'playing' : 'paused').toJS;

      // Try to set position state if available
      try {
        final positionState = _createJsObject({
          'duration': durationMs / 1000.0,
          'position': positionMs / 1000.0,
          'playbackRate': 1.0,
        });
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
    if (!kIsWeb) return;

    try {
      final navigator = globalContext['navigator'] as JSObject?;
      if (navigator == null) return;

      final mediaSession = navigator['mediaSession'] as JSObject?;
      if (mediaSession == null) return;

      mediaSession.callMethod(
        'setActionHandler'.toJS,
        'play'.toJS,
        (() {
          onPlay();
        }).toJS,
      );

      mediaSession.callMethod(
        'setActionHandler'.toJS,
        'pause'.toJS,
        (() {
          onPause();
        }).toJS,
      );

      mediaSession.callMethod(
        'setActionHandler'.toJS,
        'nexttrack'.toJS,
        (() {
          onNextTrack();
        }).toJS,
      );

      mediaSession.callMethod(
        'setActionHandler'.toJS,
        'previoustrack'.toJS,
        (() {
          onPreviousTrack();
        }).toJS,
      );

      debugPrint('MediaSession: Action handlers set');
    } catch (e) {
      debugPrint('MediaSession: Error setting action handlers: $e');
    }
  }

  /// Clear metadata
  void clear() {
    if (!kIsWeb) return;

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

  /// Helper to create a plain JS object with given properties
  JSObject _createJsObject(Map<String, dynamic> properties) {
    final obj = globalContext.callMethod('Object'.toJS) as JSObject;
    for (final entry in properties.entries) {
      final value = entry.value;
      if (value is String) {
        obj[entry.key] = value.toJS;
      } else if (value is int) {
        obj[entry.key] = value.toJS;
      } else if (value is double) {
        obj[entry.key] = value.toJS;
      } else if (value is bool) {
        obj[entry.key] = value.toJS;
      }
    }
    return obj;
  }
}
