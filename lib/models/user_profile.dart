/// User profile model for Spotify user data.
library;

class SpotifyUserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? imageUrl;
  final String country;
  final String product; // premium, free, etc.
  final int followers;
  final String? spotifyUri;
  final String? externalUrl;

  const SpotifyUserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.imageUrl,
    required this.country,
    required this.product,
    required this.followers,
    this.spotifyUri,
    this.externalUrl,
  });

  /// Check if user has premium subscription
  bool get isPremium => product == 'premium';

  /// Create from Spotify API JSON response
  factory SpotifyUserProfile.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      // Get the largest image
      imageUrl = images.first['url'] as String?;
    }

    return SpotifyUserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Spotify User',
      email: json['email'] as String? ?? '',
      imageUrl: imageUrl,
      country: json['country'] as String? ?? 'Unknown',
      product: json['product'] as String? ?? 'free',
      followers:
          (json['followers'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
      spotifyUri: json['uri'] as String?,
      externalUrl:
          (json['external_urls'] as Map<String, dynamic>?)?['spotify']
              as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'email': email,
    'images': imageUrl != null
        ? [
            {'url': imageUrl},
          ]
        : [],
    'country': country,
    'product': product,
    'followers': {'total': followers},
    'uri': spotifyUri,
    'external_urls': externalUrl != null ? {'spotify': externalUrl} : null,
  };

  @override
  String toString() {
    return 'SpotifyUserProfile(id: $id, displayName: $displayName, email: $email, isPremium: $isPremium)';
  }
}
