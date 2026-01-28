import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/spacing.dart';
import '../../../shared/models/playback_mode.dart';
import '../../../shared/models/track.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'widgets/favorite_list_item.dart';

/// Favorites screen showing saved tracks with their modes.
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () => _showImportExportSheet(context),
            tooltip: 'Import/Export',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingOverlay(message: 'Loading favorites...')
          : Column(
              children: [
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.l,
                    vertical: Spacing.m,
                  ),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterMode == null,
                        onSelected: (_) => setState(() => _filterMode = null),
                      ),
                      const SizedBox(width: Spacing.s),
                      FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.repeat_one,
                              size: 16,
                              color: _filterMode == PlaybackMode.loop
                                  ? colorScheme.onSecondaryContainer
                                  : null,
                            ),
                            const SizedBox(width: Spacing.xs),
                            const Text('Loop'),
                          ],
                        ),
                        selected: _filterMode == PlaybackMode.loop,
                        onSelected: (_) => setState(() {
                          _filterMode = _filterMode == PlaybackMode.loop
                              ? null
                              : PlaybackMode.loop;
                        }),
                      ),
                      const SizedBox(width: Spacing.s),
                      FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.skip_next,
                              size: 16,
                              color: _filterMode == PlaybackMode.skip
                                  ? colorScheme.onSecondaryContainer
                                  : null,
                            ),
                            const SizedBox(width: Spacing.xs),
                            const Text('Skip'),
                          ],
                        ),
                        selected: _filterMode == PlaybackMode.skip,
                        onSelected: (_) => setState(() {
                          _filterMode = _filterMode == PlaybackMode.skip
                              ? null
                              : PlaybackMode.skip;
                        }),
                      ),
                    ],
                  ),
                ),

                // Favorites list
                Expanded(
                  child: _filteredFavorites.isEmpty
                      ? _buildEmptyState(colorScheme, textTheme)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.l,
                          ),
                          itemCount: _filteredFavorites.length,
                          itemBuilder: (context, index) {
                            return FavoriteListItem(
                              item: _filteredFavorites[index],
                              delay: index * 50,
                              onTap: () => context.go(
                                '/player/${_filteredFavorites[index].track.id}',
                              ),
                              onDelete: () => _deleteFavorite(index),
                            );
                          },
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

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.l),
          Text('No favorites yet', style: textTheme.titleLarge),
          const SizedBox(height: Spacing.s),
          Text(
            'Save tracks with loop or skip modes\nto see them here',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _deleteFavorite(int index) {
    setState(() {
      _favorites.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<FavoriteTrackItem> _getMockFavorites() {
    return [
      FavoriteTrackItem(
        track: Track(
          id: 'fav_1',
          name: 'Bohemian Rhapsody',
          artistName: 'Queen',
          albumName: 'A Night at the Opera',
          albumCoverUrl: 'https://picsum.photos/seed/fav1/300/300',
          duration: const Duration(minutes: 5, seconds: 55),
          spotifyUri: 'spotify:track:fav_1',
        ),
        mode: PlaybackMode.loop,
        section: SectionMarker(
          startTime: const Duration(minutes: 3, seconds: 30),
          endTime: const Duration(minutes: 4, seconds: 45),
          label: 'Guitar Solo',
        ),
      ),
      FavoriteTrackItem(
        track: Track(
          id: 'fav_2',
          name: 'Stairway to Heaven',
          artistName: 'Led Zeppelin',
          albumName: 'Led Zeppelin IV',
          albumCoverUrl: 'https://picsum.photos/seed/fav2/300/300',
          duration: const Duration(minutes: 8, seconds: 2),
          spotifyUri: 'spotify:track:fav_2',
        ),
        mode: PlaybackMode.skip,
        section: SectionMarker(
          startTime: Duration.zero,
          endTime: const Duration(minutes: 1, seconds: 30),
          label: 'Intro',
        ),
      ),
      FavoriteTrackItem(
        track: Track(
          id: 'fav_3',
          name: 'Hotel California',
          artistName: 'Eagles',
          albumName: 'Hotel California',
          albumCoverUrl: 'https://picsum.photos/seed/fav3/300/300',
          duration: const Duration(minutes: 6, seconds: 30),
          spotifyUri: 'spotify:track:fav_3',
        ),
        mode: PlaybackMode.loop,
        section: SectionMarker(
          startTime: const Duration(minutes: 4, seconds: 30),
          endTime: const Duration(minutes: 6, seconds: 20),
          label: 'Outro Solo',
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
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Import/Export',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.xl),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import favorites'),
              subtitle: const Text('Load from file'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement import
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export favorites'),
              subtitle: const Text('Save to file'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement export
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share favorites'),
              subtitle: const Text('Share with others'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
          ],
        ),
      ),
    );
  }
}
