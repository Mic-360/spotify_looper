/// Repeat modes for playback
enum SpotifyRepeatMode { off, track, context }

/// Player state for tracking playback from Spotify SDK
class PlayerState {
  final bool isPlaying;
  final bool isPaused;
  final String? trackUri;
  final String? trackName;
  final String? artistName;
  final String? albumArtUrl;
  final int positionMs;
  final int durationMs;
  final SpotifyRepeatMode repeatMode;
  final bool shuffleEnabled;

  const PlayerState({
    this.isPlaying = false,
    this.isPaused = false,
    this.trackUri,
    this.trackName,
    this.artistName,
    this.albumArtUrl,
    this.positionMs = 0,
    this.durationMs = 0,
    this.repeatMode = SpotifyRepeatMode.off,
    this.shuffleEnabled = false,
  });

  double get progress => durationMs > 0 ? positionMs / durationMs : 0;

  PlayerState copyWith({
    bool? isPlaying,
    bool? isPaused,
    String? trackUri,
    String? trackName,
    String? artistName,
    String? albumArtUrl,
    int? positionMs,
    int? durationMs,
    SpotifyRepeatMode? repeatMode,
    bool? shuffleEnabled,
  }) => PlayerState(
    isPlaying: isPlaying ?? this.isPlaying,
    isPaused: isPaused ?? this.isPaused,
    trackUri: trackUri ?? this.trackUri,
    trackName: trackName ?? this.trackName,
    artistName: artistName ?? this.artistName,
    albumArtUrl: albumArtUrl ?? this.albumArtUrl,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    repeatMode: repeatMode ?? this.repeatMode,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
  );

  static const PlayerState initial = PlayerState();
}
