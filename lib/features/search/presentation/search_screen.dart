import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/durations.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/models/track.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Search screen with real-time search functionality.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
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

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isSearching = false;
  List<Track> _results = [];
  String _lastQuery = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              onChanged: _onSearch,
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
              onSubmitted: _onSearch,
            ),
          ),

          // Results
          Expanded(child: _buildContent(colorScheme, textTheme)),
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

  Widget _buildContent(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isSearching) {
      return const LoadingOverlay(message: 'Searching...');
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState(colorScheme, textTheme);
    }

    if (_results.isEmpty) {
      return _buildNoResults(colorScheme, textTheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final track = _results[index];
        return _SearchResultItem(
          track: track,
          delay: index * 30,
          onTap: () => context.go('/player/${track.id}'),
        );
      },
    );
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _results = [];
      _lastQuery = '';
    });
    _focusNode.requestFocus();
  }

  List<Track> _getMockResults(String query) {
    return List.generate(10, (index) {
      return Track(
        id: 'search_${query}_$index',
        name: '$query Result ${index + 1}',
        artistName: 'Artist ${(index % 3) + 1}',
        albumName: 'Album ${(index % 2) + 1}',
        albumCoverUrl: 'https://picsum.photos/seed/search$query$index/300/300',
        duration: Duration(minutes: 3 + (index % 3), seconds: 20 + index * 3),
        spotifyUri: 'spotify:track:search_${query}_$index',
      );
    });
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
      });
      return;
    }

    if (query == _lastQuery) return;

    setState(() => _isSearching = true);

    // Debounce - wait a bit before searching
    await Future.delayed(const Duration(milliseconds: 300));

    if (_searchController.text != query) return;

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted && _searchController.text == query) {
      setState(() {
        _isSearching = false;
        _lastQuery = query;
        _results = _getMockResults(query);
      });
    }
  }
}
