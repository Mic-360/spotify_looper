/// Track model for Spotify track data.
library;

class SpotifyTrack {
  final String id;
  final String name;
  final String uri;
  final int durationMs;
  final bool explicit;
  final int popularity;
  final String? previewUrl;
  final SpotifyAlbum album;
  final List<SpotifyArtist> artists;

  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.uri,
    required this.durationMs,
    required this.explicit,
    required this.popularity,
    this.previewUrl,
    required this.album,
    required this.artists,
  });

  /// Get formatted duration string (mm:ss)
  String get formattedDuration {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get artist names as comma-separated string
  String get artistNames => artists.map((a) => a.name).join(', ');

  /// Get album artwork URL (prefer medium size)
  String? get artworkUrl =>
      album.images.isNotEmpty ? album.images.first.url : null;

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Track',
      uri: json['uri'] as String? ?? '',
      durationMs: json['duration_ms'] as int? ?? 0,
      explicit: json['explicit'] as bool? ?? false,
      popularity: json['popularity'] as int? ?? 0,
      previewUrl: json['preview_url'] as String?,
      album: SpotifyAlbum.fromJson(
        json['album'] as Map<String, dynamic>? ?? {},
      ),
      artists:
          (json['artists'] as List<dynamic>?)
              ?.map((a) => SpotifyArtist.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'uri': uri,
    'duration_ms': durationMs,
    'explicit': explicit,
    'popularity': popularity,
    'preview_url': previewUrl,
    'album': album.toJson(),
    'artists': artists.map((a) => a.toJson()).toList(),
  };
}

class SpotifyAlbum {
  final String id;
  final String name;
  final String? albumType;
  final String? releaseDate;
  final List<SpotifyImage> images;

  const SpotifyAlbum({
    required this.id,
    required this.name,
    this.albumType,
    this.releaseDate,
    required this.images,
  });

  factory SpotifyAlbum.fromJson(Map<String, dynamic> json) {
    return SpotifyAlbum(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Album',
      albumType: json['album_type'] as String?,
      releaseDate: json['release_date'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((i) => SpotifyImage.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'album_type': albumType,
    'release_date': releaseDate,
    'images': images.map((i) => i.toJson()).toList(),
  };
}

class SpotifyArtist {
  final String id;
  final String name;
  final String? uri;

  const SpotifyArtist({required this.id, required this.name, this.uri});

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    return SpotifyArtist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Artist',
      uri: json['uri'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'uri': uri};
}

class SpotifyImage {
  final String url;
  final int? width;
  final int? height;

  const SpotifyImage({required this.url, this.width, this.height});

  factory SpotifyImage.fromJson(Map<String, dynamic> json) {
    return SpotifyImage(
      url: json['url'] as String? ?? '',
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'width': width,
    'height': height,
  };
}
