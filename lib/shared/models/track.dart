/// Track model representing a Spotify track.
class Track {
  final String id;
  final String name;
  final String artistName;
  final String albumName;
  final String albumCoverUrl;
  final Duration duration;
  final String? previewUrl;
  final String spotifyUri;

  const Track({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumName,
    required this.albumCoverUrl,
    required this.duration,
    this.previewUrl,
    required this.spotifyUri,
  });

  /// Create Track from Spotify API JSON response
  factory Track.fromJson(Map<String, dynamic> json) {
    final album = json['album'] as Map<String, dynamic>? ?? {};
    final artists = json['artists'] as List? ?? [];
    final images = album['images'] as List? ?? [];

    return Track(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Track',
      artistName: artists.isNotEmpty
          ? (artists.first as Map<String, dynamic>)['name'] as String? ??
                'Unknown Artist'
          : 'Unknown Artist',
      albumName: album['name'] as String? ?? 'Unknown Album',
      albumCoverUrl: images.isNotEmpty
          ? (images.first as Map<String, dynamic>)['url'] as String? ?? ''
          : '',
      duration: Duration(milliseconds: json['duration_ms'] as int? ?? 0),
      previewUrl: json['preview_url'] as String?,
      spotifyUri: json['uri'] as String? ?? '',
    );
  }

  /// Format duration as mm:ss
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  Track copyWith({
    String? id,
    String? name,
    String? artistName,
    String? albumName,
    String? albumCoverUrl,
    Duration? duration,
    String? previewUrl,
    String? spotifyUri,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      albumCoverUrl: albumCoverUrl ?? this.albumCoverUrl,
      duration: duration ?? this.duration,
      previewUrl: previewUrl ?? this.previewUrl,
      spotifyUri: spotifyUri ?? this.spotifyUri,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artistName': artistName,
    'albumName': albumName,
    'albumCoverUrl': albumCoverUrl,
    'duration_ms': duration.inMilliseconds,
    'preview_url': previewUrl,
    'uri': spotifyUri,
  };
}
