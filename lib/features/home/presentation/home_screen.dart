import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/models/track.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'widgets/animated_track_card.dart';
import 'widgets/section_header.dart';

/// Home screen with staggered grid of tracks.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Track> _trendingTracks = [];
  List<Track> _favoriteTracks = [];
  List<Track> _recentTracks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingOverlay(message: 'Loading your music...')
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                slivers: [
                  // Trending Section
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Trending Now',
                      subtitle: 'Popular tracks on Spotify',
                      onSeeAll: () {},
                    ),
                  ),
                  _buildTrendingGrid(),

                  // Favorites Section
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Your Favorites',
                      subtitle: 'Tracks with saved loops & skips',
                      onSeeAll: () => context.go('/favorites'),
                    ),
                  ),
                  _buildHorizontalList(_favoriteTracks),

                  // Recent Section
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Recently Played',
                      subtitle: 'Your listening history',
                      onSeeAll: () => context.go('/history'),
                    ),
                  ),
                  _buildHorizontalList(_recentTracks),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: Spacing.xxxl),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Widget _buildHorizontalList(List<Track> tracks) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
          itemCount: tracks.length,
          separatorBuilder: (_, __) => const SizedBox(width: Spacing.m),
          itemBuilder: (context, index) {
            return SizedBox(
              width: 150,
              child: AnimatedTrackCard(
                track: tracks[index],
                delay: index * 50,
                onTap: () => context.go('/player/${tracks[index].id}'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrendingGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns = Breakpoints.getGridColumns(
            constraints.crossAxisExtent,
          );

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: Spacing.m,
              crossAxisSpacing: Spacing.m,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return AnimatedTrackCard(
                track: _trendingTracks[index],
                delay: index * 50,
                onTap: () => context.go('/player/${_trendingTracks[index].id}'),
              );
            }, childCount: _trendingTracks.length),
          );
        },
      ),
    );
  }

  List<Track> _getMockTracks(String type) {
    return List.generate(
      type == 'trending' ? 8 : 6,
      (index) => Track(
        id: '${type}_$index',
        name: 'Track ${index + 1}',
        artistName: 'Artist ${index + 1}',
        albumName: 'Album ${index + 1}',
        albumCoverUrl: 'https://picsum.photos/seed/$type$index/300/300',
        duration: Duration(minutes: 3, seconds: 30 + index * 5),
        spotifyUri: 'spotify:track:${type}_$index',
      ),
    );
  }

  Future<void> _loadData() async {
    // Simulate loading data
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isLoading = false;
        // Mock data - replace with actual Spotify API calls
        _trendingTracks = _getMockTracks('trending');
        _favoriteTracks = _getMockTracks('favorites');
        _recentTracks = _getMockTracks('recent');
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await _loadData();
  }
}
