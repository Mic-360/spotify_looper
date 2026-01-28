import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/durations.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/models/track.dart';
import '../data/search_repository.dart';

/// Search screen with real-time search functionality.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchResultItem extends StatefulWidget {
  final Track track;
  final int delay;
  final VoidCallback? onTap;

  const _SearchResultItem({required this.track, this.delay = 0, this.onTap});

  @override
  State<_SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<_SearchResultItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.s),
        child: ListTile(
          onTap: widget.onTap,
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: widget.track.albumCoverUrl.isNotEmpty
                  ? Image.network(
                      widget.track.albumCoverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.music_note,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.music_note,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          title: Text(
            widget.track.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${widget.track.artistName} • ${widget.track.formattedDuration}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: widget.onTap,
            tooltip: 'Play',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _currentQuery = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final searchResults = ref.watch(searchResultsProvider(_currentQuery));

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(Spacing.l),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (value) {
                setState(() => _currentQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search for songs, artists...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),

          // Results
          Expanded(
            child: searchResults.when(
              data: (tracks) =>
                  _buildResultsList(tracks, colorScheme, textTheme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildError(err, colorScheme, textTheme),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: Spacing.l),
          Text('Search for music', style: textTheme.titleLarge),
          const SizedBox(height: Spacing.s),
          Text(
            'Find songs to loop or skip sections',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    Object error,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: Spacing.l),
            Text('Playback Error', style: textTheme.titleLarge),
            const SizedBox(height: Spacing.s),
            Text(
              'Make sure you have an active Spotify session.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: Spacing.l),
          Text('No results found', style: textTheme.titleLarge),
          const SizedBox(height: Spacing.s),
          Text(
            'Try different keywords',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    List<Track> tracks,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState(colorScheme, textTheme);
    }

    if (tracks.isEmpty) {
      return _buildNoResults(colorScheme, textTheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _SearchResultItem(
          track: track,
          delay: index * 30,
          onTap: () => context.go('/player/${track.id}'),
        );
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
    });
    _focusNode.requestFocus();
  }
}
