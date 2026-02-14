/// Media Session Service Interface (Stub for Mobile)
library;

import 'dart:ui';
import '../models/track.dart';
import '../providers/player_provider.dart';

class MediaSessionService {
  MediaSessionService._();
  static final instance = MediaSessionService._();

  void updateMetadata(
    SpotifyTrack track, {
    PlayerMode mode = PlayerMode.normal,
  }) {}

  void updatePlaybackState({
    required bool isPlaying,
    required int positionMs,
    required int durationMs,
  }) {}

  void setActionHandlers({
    required VoidCallback onPlay,
    required VoidCallback onPause,
    required VoidCallback onNextTrack,
    required VoidCallback onPreviousTrack,
  }) {}

  void clear() {}
}
