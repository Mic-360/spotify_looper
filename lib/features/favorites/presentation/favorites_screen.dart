import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/spacing.dart';
import '../../../shared/models/playback_mode.dart';
import '../../../shared/models/track.dart';

/// Favorites screen with high-fidelity Pulse Loop aesthetic.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class FavoriteTrackItem {
  final Track track;
  final PlaybackMode mode;
  final SectionMarker? section;

  const FavoriteTrackItem({
    required this.track,
    required this.mode,
    this.section,
  });
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  List<FavoriteTrackItem> _favorites = [];
  PlaybackMode? _filterMode;

  List<FavoriteTrackItem> get _filteredFavorites {
    if (_filterMode == null) return _favorites;
    return _favorites.where((f) => f.mode == _filterMode).toList();
  }

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
                      IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => _showImportExportSheet(context),
                      ),
                    ],
                  ),
                ),

                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _filterMode == null,
                        onTap: () => setState(() => _filterMode = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Loops',
                        isSelected: _filterMode == PlaybackMode.loop,
                        onTap: () =>
                            setState(() => _filterMode = PlaybackMode.loop),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Skips',
                        isSelected: _filterMode == PlaybackMode.skip,
                        onTap: () =>
                            setState(() => _filterMode = PlaybackMode.skip),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1DB954),
                          ),
                        )
                      : _filteredFavorites.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.xl,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredFavorites.length,
                          itemBuilder: (context, index) {
                            final item = _filteredFavorites[index];
                            return _FavoriteTile(
                              item: item,
                              onTap: () =>
                                  context.go('/player/${item.track.id}'),
                              onDelete: () => _deleteFavorite(index),
                            );
                          },
                        ),
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

  void _deleteFavorite(int index) {
    setState(() => _favorites.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A1A),
        content: const Text(
          'Removed from favorites',
          style: TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<FavoriteTrackItem> _getMockFavorites() {
    return [
      FavoriteTrackItem(
        track: Track(
          id: 'fav_1',
          name: 'Midnight City',
          artistName: 'M83',
          albumName: 'Hurry Up, We\'re Dreaming',
          albumCoverUrl: 'https://picsum.photos/seed/fav1/300/300',
          duration: const Duration(minutes: 4, seconds: 03),
          spotifyUri: 'spotify:track:fav_1',
        ),
        mode: PlaybackMode.loop,
        section: SectionMarker(
          startTime: const Duration(minutes: 1, seconds: 30),
          endTime: const Duration(minutes: 2, seconds: 05),
          label: 'Chorus Loop',
        ),
      ),
      FavoriteTrackItem(
        track: Track(
          id: 'fav_2',
          name: 'Stargazing',
          artistName: 'Travis Scott',
          albumName: 'Astroworld',
          albumCoverUrl: 'https://picsum.photos/seed/fav2/300/300',
          duration: const Duration(minutes: 4, seconds: 30),
          spotifyUri: 'spotify:track:fav_2',
        ),
        mode: PlaybackMode.skip,
        section: SectionMarker(
          startTime: Duration.zero,
          endTime: const Duration(minutes: 0, seconds: 45),
          label: 'Skit',
        ),
      ),
      FavoriteTrackItem(
        track: Track(
          id: 'fav_3',
          name: 'Blinding Lights',
          artistName: 'The Weeknd',
          albumName: 'After Hours',
          albumCoverUrl: 'https://picsum.photos/seed/fav3/300/300',
          duration: const Duration(minutes: 3, seconds: 20),
          spotifyUri: 'spotify:track:fav_3',
        ),
        mode: PlaybackMode.loop,
        section: SectionMarker(
          startTime: const Duration(minutes: 0, seconds: 40),
          endTime: const Duration(minutes: 1, seconds: 20),
          label: 'Intro Beat',
        ),
      ),
    ];
  }

  Future<void> _loadFavorites() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _favorites = _getMockFavorites();
      });
    }
  }

  void _showImportExportSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Manage Favorites',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _SheetTile(
              icon: Icons.upload_rounded,
              title: 'Import backup',
              onTap: () => Navigator.pop(context),
            ),
            _SheetTile(
              icon: Icons.download_rounded,
              title: 'Export backup',
              onTap: () => Navigator.pop(context),
            ),
            _SheetTile(
              icon: Icons.share_rounded,
              title: 'Share list',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final FavoriteTrackItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FavoriteTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              item.track.albumCoverUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.track.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.track.artistName,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.mode == PlaybackMode.loop
                            ? Icons.repeat_rounded
                            : Icons.skip_next_rounded,
                        size: 12,
                        color: const Color(0xFF1DB954),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.section?.label ??
                            (item.mode == PlaybackMode.loop ? 'Loop' : 'Skip'),
                        style: const TextStyle(
                          color: Color(0xFF1DB954),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.play_circle_fill_rounded,
              color: Color(0xFF1DB954),
              size: 32,
            ),
            onPressed: onTap,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white24,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1DB954)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1DB954)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
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

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
