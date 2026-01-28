import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/spacing.dart';
import '../../../shared/models/track.dart';
import '../data/search_repository.dart';

/// Search screen with Pulse Loop aesthetic.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _GlowBlob extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Color color;
  final double size;

  const _GlowBlob({this.top, this.left, this.right, this.bottom, required this.color, required this.size});

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
            BoxShadow(
              color: color,
              blurRadius: 80,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Track track;
  final int index;
  final VoidCallback onTap;

  const _SearchResultTile({required this.track, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            track.albumCoverUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 50,
              height: 50,
              color: Colors.white10,
              child: const Icon(Icons.music_note, color: Colors.white24),
            ),
          ),
        ),
        title: Text(
          track.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${track.artistName} • ${track.formattedDuration}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ),
      ),
    );
  }
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _currentQuery = '';

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider(_currentQuery));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // Background Glows
          _buildBackgroundGlows(),

          SafeArea(
            child: Column(
              children: [
                // Header & Search Input
                Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search',
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spacing.l),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Colors.grey),
                            const SizedBox(width: Spacing.s),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                onChanged: (value) {
                                  setState(() => _currentQuery = value);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Artists, tracks, or vibes...',
                                  hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(color: Colors.white),
                                textInputAction: TextInputAction.search,
                              ),
                            ),
                            if (_currentQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                                onPressed: _clearSearch,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Results
                Expanded(
                  child: searchResults.when(
                    data: (tracks) => _buildResultsList(tracks),
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
                    error: (err, stack) => _buildError(err),
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
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Auto-focus search if navigation was triggered from FAB
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Widget _buildBackgroundGlows() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: const Color(0xFF0F0F0F)),
          _GlowBlob(
            top: 100,
            left: -100,
            color: Colors.blue.withOpacity(0.1),
            size: 400,
          ),
          _GlowBlob(
            bottom: -50,
            right: -50,
            color: const Color(0xFF1DB954).withOpacity(0.05),
            size: 300,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: Spacing.l),
          const Text(
            'Discover Music',
            style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.s),
          const Text(
            'Search for tracks to loop and remix',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(height: Spacing.m),
          const Text('Search failed. Check your connection.', style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () => ref.invalidate(searchResultsProvider(_currentQuery)),
            child: const Text('Retry', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Text('No tracks found.', style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildResultsList(List<Track> tracks) {
    if (_currentQuery.isEmpty) {
      return _buildEmptyState();
    }

    if (tracks.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        return _SearchResultTile(
          track: tracks[index],
          index: index,
          onTap: () => context.go('/player/${tracks[index].id}'),
        );
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _currentQuery = '');
  }
}
