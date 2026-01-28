import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/spacing.dart';
import '../../../shared/models/favorite_track_item.dart';
import '../../../shared/models/playback_mode.dart';
import '../../../shared/models/track.dart';

/// Favorites screen with high-fidelity Pulse Loop aesthetic and Grid/List toggle.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

enum FavoritesViewMode { grid, list }

class _FavoriteGridItem extends StatelessWidget {
  final FavoriteTrackItem item;
  final VoidCallback onTap;

  const _FavoriteGridItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      item.track.albumCoverUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.track.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.track.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item.curator ?? item.track.artistName,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFF1DB954),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.likes,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.grey,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.loopCount}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteListItem extends StatelessWidget {
  final FavoriteTrackItem item;
  final VoidCallback onTap;

  const _FavoriteListItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.track.albumCoverUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.track.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Curated by ',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      Text(
                        item.curator ?? item.track.artistName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1DB954,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.track.formattedDuration,
                          style: const TextStyle(
                            color: Color(0xFF1DB954),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFF1DB954),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.likes,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.loopCount} Loops',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  List<FavoriteTrackItem> _favorites = [];
  FavoritesViewMode _viewMode = FavoritesViewMode.grid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          _buildBackgroundGlows(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl,
                    Spacing.l,
                    Spacing.l,
                    Spacing.m,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Favorites',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Row(
                        children: [
                          _ViewToggleButton(
                            icon: Icons.grid_view_rounded,
                            isSelected: _viewMode == FavoritesViewMode.grid,
                            onTap: () => setState(
                              () => _viewMode = FavoritesViewMode.grid,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ViewToggleButton(
                            icon: Icons.view_list_rounded,
                            isSelected: _viewMode == FavoritesViewMode.list,
                            onTap: () => setState(
                              () => _viewMode = FavoritesViewMode.list,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1DB954),
                          ),
                        )
                      : _favorites.isEmpty
                      ? _buildEmptyState()
                      : _viewMode == FavoritesViewMode.grid
                      ? _buildGridView()
                      : _buildListView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Widget _buildBackgroundGlows() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: const Color(0xFF0F0F0F)),
          _GlowBlob(
            top: 150,
            right: -150,
            color: const Color(0xFF1DB954).withValues(alpha: 0.1),
            size: 400,
          ),
          _GlowBlob(
            bottom: 50,
            left: -100,
            color: Colors.blue.withValues(alpha: 0.08),
            size: 350,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_rounded, size: 64, color: Colors.white10),
          SizedBox(height: Spacing.m),
          Text('No favorites yet.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final item = _favorites[index];
        return _FavoriteGridItem(
          item: item,
          onTap: () => context.go('/player/${item.track.id}'),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      physics: const BouncingScrollPhysics(),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final item = _favorites[index];
        return _FavoriteListItem(
          item: item,
          onTap: () => context.go('/player/${item.track.id}'),
        );
      },
    );
  }

  Future<void> _loadFavorites() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _favorites = [
          FavoriteTrackItem(
            track: Track(
              id: 'fav_1',
              name: 'Deep House Mix 04',
              artistName: 'Alex Beats',
              albumName: 'Hurry Up, We\'re Dreaming',
              albumCoverUrl: 'https://picsum.photos/seed/fav1/400/400',
              duration: const Duration(minutes: 4, seconds: 20),
              spotifyUri: 'spotify:track:fav_1',
            ),
            mode: PlaybackMode.loop,
            likes: '2.4k',
            loopCount: 12,
            curator: '@alex_beats',
          ),
          FavoriteTrackItem(
            track: Track(
              id: 'fav_2',
              name: 'Ambient Rain',
              artistName: 'Nature Sounds',
              albumName: 'Soundscapes',
              albumCoverUrl: 'https://picsum.photos/seed/fav2/400/400',
              duration: const Duration(minutes: 5, seconds: 00),
              spotifyUri: 'spotify:track:fav_2',
            ),
            mode: PlaybackMode.normal,
            likes: '5.6k',
            loopCount: 22,
            curator: '@nature_sounds',
          ),
          FavoriteTrackItem(
            track: Track(
              id: 'fav_3',
              name: 'Synthwave Night',
              artistName: 'Neon Dreamer',
              albumName: 'Retro Waves',
              albumCoverUrl: 'https://picsum.photos/seed/fav3/400/400',
              duration: const Duration(minutes: 3, seconds: 45),
              spotifyUri: 'spotify:track:fav_3',
            ),
            mode: PlaybackMode.loop,
            likes: '1.8k',
            loopCount: 8,
            curator: '@neon_dreamer',
          ),
          FavoriteTrackItem(
            track: Track(
              id: 'fav_4',
              name: 'Lo-Fi Study Beats',
              artistName: 'Chill Vibes',
              albumName: 'Lofi Girl',
              albumCoverUrl: 'https://picsum.photos/seed/fav4/400/400',
              duration: const Duration(minutes: 2, seconds: 30),
              spotifyUri: 'spotify:track:fav_4',
            ),
            mode: PlaybackMode.loop,
            likes: '10.2k',
            loopCount: 45,
            curator: '@chill_vibes',
          ),
        ];
      });
    }
  }
}

class _GlowBlob extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Color color;
  final double size;

  const _GlowBlob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 20),
          ],
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1DB954) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[400],
          size: 20,
        ),
      ),
    );
  }
}
