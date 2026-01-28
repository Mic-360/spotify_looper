import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/models/track.dart';
import '../data/home_repository.dart';
import 'widgets/animated_track_card.dart';
import 'widgets/section_header.dart';

/// Home screen with staggered grid of tracks.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);

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
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(recentlyPlayedProvider),
        child: CustomScrollView(
          slivers: [
            // Recent Section
            recentlyPlayed.when(
              data: (tracks) => SliverToBoxAdapter(
                child: Column(
                  children: [
                    SectionHeader(
                      title: 'Recently Played',
                      subtitle: 'Your listening history',
                      onSeeAll: () => context.go('/history'),
                    ),
                    _buildHorizontalList(tracks, context),
                  ],
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(Spacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Center(
                    child: Text('Playback Error: Make sure Spotify is active.'),
                  ),
                ),
              ),
            ),

            // Trending (Mock for now as Spotify doesn't have a simple trending endpoint without more scopes)
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Trending Now',
                subtitle: 'Popular tracks on Spotify',
                onSeeAll: () {},
              ),
            ),
            _buildTrendingGrid(_getMockTracks('trending'), context),

            // Favorites (Mock for now)
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Your Favorites',
                subtitle: 'Tracks with saved loops & skips',
                onSeeAll: () => context.go('/favorites'),
              ),
            ),
            _buildHorizontalList(_getMockTracks('favorites'), context),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: Spacing.xxxl)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Track> tracks, BuildContext context) {
    return SizedBox(
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
    );
  }

  Widget _buildTrendingGrid(List<Track> trendingTracks, BuildContext context) {
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
                track: trendingTracks[index],
                delay: index * 50,
                onTap: () => context.go('/player/${trendingTracks[index].id}'),
              );
            }, childCount: trendingTracks.length),
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
}
