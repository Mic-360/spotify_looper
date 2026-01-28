import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/track.dart';
import '../data/search_repository.dart';

/// Search screen with Pulse Loop high-fidelity overlay aesthetic.
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

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _currentQuery = '';

  // Mock recent searches for UI completeness
  final List<Map<String, String>> _recentSearches = [
    {'title': 'After Hours - The Weeknd', 'subtitle': 'Track • Synthwave'},
    {'title': 'Neon Blade - MoonDeity', 'subtitle': 'Track • Phonk'},
  ];

  final List<String> _suggestedGenres = [
    'Techno',
    'Lo-Fi',
    'Deep House',
    'Phonk',
    'Ambient',
  ];

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider(_currentQuery));
    final textTheme = Theme.of(context).textTheme;
    const pulseGreen = Color(0xFF13EC5B);
    const backgroundDark = Color(0xFF102216);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: Stack(
        children: [
          // Background visual blobs
          _buildBackgroundGlows(),

          // Glass overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: backgroundDark.withValues(alpha: 0.85)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header & Search Bar
                _buildHeader(context, pulseGreen),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Suggested Genres
                        _buildSuggestedGenres(pulseGreen),

                        // Recent Searches
                        _buildRecentSearches(pulseGreen),

                        // Search Results (Quick Loop)
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Quick Loop Results',
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        searchResults.when(
                          data: (tracks) =>
                              _buildSearchResults(tracks, pulseGreen),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(
                                color: pulseGreen,
                              ),
                            ),
                          ),
                          error: (err, stack) => _buildError(err, pulseGreen),
                        ),

                        const SizedBox(
                          height: 100,
                        ), // Space for floating button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Close Button
          _buildFloatingCloseButton(context, pulseGreen),
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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Widget _buildBackgroundGlows() {
    return Stack(
      children: [
        _GlowBlob(
          top: 100,
          left: -100,
          color: Colors.blue.withValues(alpha: 0.1),
          size: 400,
        ),
        _GlowBlob(
          bottom: -50,
          right: -50,
          color: const Color(0xFF13EC5B).withValues(alpha: 0.05),
          size: 300,
        ),
      ],
    );
  }

  Widget _buildError(Object error, Color pulseGreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text(
            'Search failed. Check connection.',
            style: TextStyle(color: Colors.grey),
          ),
          TextButton(
            onPressed: () =>
                ref.invalidate(searchResultsProvider(_currentQuery)),
            child: Text('Retry', style: TextStyle(color: pulseGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCloseButton(BuildContext context, Color pulseGreen) {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: pulseGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: pulseGreen.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF102216),
              size: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color pulseGreen) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF23482F).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(Icons.search_rounded, color: pulseGreen),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: (value) =>
                          setState(() => _currentQuery = value),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search Pulse...',
                        hintStyle: TextStyle(
                          color: const Color(0xFF92C9A4).withValues(alpha: 0.8),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        isCollapsed: true,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_currentQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _searchController.clear();
                          _currentQuery = '';
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(Color pulseGreen) {
    if (_currentQuery.isNotEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: pulseGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._recentSearches.map(
          (item) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history_rounded, color: Colors.white70),
            ),
            title: Text(
              item['title']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              item['subtitle']!,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            trailing: const Icon(
              Icons.close_rounded,
              color: Colors.white24,
              size: 20,
            ),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<Track> tracks, Color pulseGreen) {
    if (tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                color: Colors.white.withValues(alpha: 0.1),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'No tracks found.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        // Mocking BPM and Energy for UI parity with HTML
        final mockBpm = 120 + (index * 13) % 65;
        final mockEnergy = ['High Energy', 'Moody', 'Pop', 'Vibe'][index % 4];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  track.albumCoverUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(color: Colors.grey[800], width: 64, height: 64),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artistName,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: pulseGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            mockEnergy.toUpperCase(),
                            style: TextStyle(
                              color: pulseGreen,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$mockBpm BPM',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/player/${track.id}'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? pulseGreen
                        : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: index != 0
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          )
                        : null,
                  ),
                  child: Icon(
                    index == 0
                        ? Icons.play_arrow_rounded
                        : Icons.add_circle_outline_rounded,
                    color: index == 0 ? const Color(0xFF102216) : pulseGreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestedGenres(Color pulseGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'SUGGESTED GENRES',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _suggestedGenres.map((genre) {
              final isFirst = genre == _suggestedGenres.first;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(genre),
                  backgroundColor: isFirst
                      ? pulseGreen
                      : Colors.white.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isFirst ? const Color(0xFF102216) : Colors.white,
                    fontSize: 13,
                    fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isFirst
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
