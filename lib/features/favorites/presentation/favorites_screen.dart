import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/spacing.dart';
import '../../../shared/models/playback_mode.dart';
import '../../../shared/models/track.dart';

/// Favorites screen with Pulse Loop aesthetic.
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          _buildBackgroundGlows(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Favorites',
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.import_export_rounded,
                          color: Colors.grey,
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

                const SizedBox(height: Spacing.l),

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
            top: 200,
            right: -100,
            color: const Color(0xFF1DB954).withOpacity(0.05),
            size: 400,
          ),
          _GlowBlob(
            bottom: -50,
            left: 50,
            color: Colors.blue.withOpacity(0.08),
            size: 300,
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
      const SnackBar(
        backgroundColor: Color(0xFF1A1A1A),
        content: Text(
          'Removed from favorites',
          style: TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Backup',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            _SheetTile(
              icon: Icons.upload_rounded,
              title: 'Import Data',
              onTap: () => Navigator.pop(context),
            ),
            _SheetTile(
              icon: Icons.download_rounded,
              title: 'Export Data',
              onTap: () => Navigator.pop(context),
            ),
            _SheetTile(
              icon: Icons.share_rounded,
              title: 'Share List',
              onTap: () => Navigator.pop(context),
            ),
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
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.track.albumCoverUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.track.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.track.artistName,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      item.mode == PlaybackMode.loop
                          ? Icons.repeat_rounded
                          : Icons.skip_next_rounded,
                      size: 14,
                      color: const Color(0xFF1DB954),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.section?.label ??
                          (item.mode == PlaybackMode.loop ? 'Loop' : 'Skip'),
                      style: const TextStyle(
                        color: Color(0xFF1DB954),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white70),
            onPressed: onTap,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1DB954)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
