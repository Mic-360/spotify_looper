import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/spacing.dart';
import '../../../shared/models/track.dart';

/// Discover/Home screen with glassmorphism design and glow effects.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch(recentlyPlayedProvider); // Keep for potential use or remove if fully static branding
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // 1. Background Glow Blobs
          _buildBackgroundGlows(),

          // 2. Main Content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // StatusBar placeholder padding
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.s)),

                // Header: Discover + Profile
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xl,
                    vertical: Spacing.s,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discover',
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white10),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://lh3.googleusercontent.com/a/ACg8ocL-f_Xm_k_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T=s96-c',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xl,
                    vertical: Spacing.m,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.l,
                      ),
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
                              decoration: InputDecoration(
                                hintText: 'Artists, tracks, or vibes...',
                                hintStyle: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Category Chips
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xl,
                      vertical: Spacing.s,
                    ),
                    child: Row(
                      children: [
                        _CategoryChip(label: 'All', isSelected: true),
                        _CategoryChip(label: 'House'),
                        _CategoryChip(label: 'Techno'),
                        _CategoryChip(label: 'Lo-Fi'),
                        _CategoryChip(label: 'Drum & Bass'),
                        _CategoryChip(label: 'Ambient'),
                      ],
                    ),
                  ),
                ),

                // Section: Loop-Ready
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSectionHeader(
                        context,
                        'Loop-Ready',
                        onSeeAll: () {},
                      ),
                      SizedBox(
                        height: 240,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.xl,
                          ),
                          itemCount: 5,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: Spacing.l),
                          itemBuilder: (context, index) {
                            return _LoopReadyCard(
                              track: _getMockTrack(index, 'loop-ready'),
                              bpm: 120 + (index * 2),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Section: Top Community Loops
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSectionHeader(
                        context,
                        'Top Community Loops',
                        onAction: () {},
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.xl,
                        ),
                        child: Column(
                          children: [
                            _CommunityLoopTile(
                              title: 'Deep House Mix 04',
                              curator: '@alex_beats',
                              likes: '2.4k',
                              loopCount: 12,
                              duration: '4:20',
                              imageUrl:
                                  'https://picsum.photos/seed/mix1/200/200',
                            ),
                            _CommunityLoopTile(
                              title: 'Vinyl Scratch Loop',
                              curator: '@dj_smooth',
                              likes: '856',
                              loopCount: 4,
                              duration: '0:45',
                              imageUrl:
                                  'https://picsum.photos/seed/mix2/200/200',
                            ),
                            _CommunityLoopTile(
                              title: 'Synthwave Night',
                              curator: '@retro_future',
                              likes: '1.2k',
                              loopCount: 8,
                              duration: '2:10',
                              imageUrl:
                                  'https://picsum.photos/seed/mix3/200/200',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom padding for Navigation Bar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlows() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: const Color(0xFF0F0F0F)),
          _GlowBlob(
            top: -100,
            right: -100,
            color: Colors.purple.withOpacity(0.15),
            size: 400,
          ),
          _GlowBlob(
            top: 150,
            left: -150,
            color: Colors.blue.withOpacity(0.1),
            size: 350,
          ),
          _GlowBlob(
            bottom: -50,
            right: 100,
            color: const Color(0xFF1DB954).withOpacity(0.08),
            size: 300,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xl,
        Spacing.xl,
        Spacing.m,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'SEE ALL',
                style: TextStyle(
                  color: Color(0xFF1DB954),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (onAction != null)
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.grid_view_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.list_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Track _getMockTrack(int index, String type) {
    return Track(
      id: '${type}_$index',
      name: [
        'Midnight City',
        'Waves',
        'Neon Lights',
        'Stargazing',
        'Lost',
      ][index % 5],
      artistName: [
        'M83',
        'Kanye West',
        'Demi Lovato',
        'Travis Scott',
        'Frank Ocean',
      ][index % 5],
      albumName: 'Album',
      albumCoverUrl: 'https://picsum.photos/seed/${type}_$index/400/400',
      duration: const Duration(minutes: 3, seconds: 45),
      spotifyUri: 'spotify:track:$index',
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CategoryChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1DB954)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? null
            : Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.grey[300],
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

class _CommunityLoopTile extends StatelessWidget {
  final String title;
  final String curator;
  final String likes;
  final int loopCount;
  final String duration;
  final String imageUrl;

  const _CommunityLoopTile({
    required this.title,
    required this.curator,
    required this.likes,
    required this.loopCount,
    required this.duration,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.play_circle_filled_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Curated by $curator',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatItem(icon: Icons.favorite_rounded, label: likes),
                    const SizedBox(width: 12),
                    _StatItem(
                      icon: Icons.graphic_eq_rounded,
                      label: '$loopCount Loops',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              duration,
              style: const TextStyle(
                color: Color(0xFF1DB954),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert_rounded, color: Colors.grey),
        ],
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

class _LoopReadyCard extends StatelessWidget {
  final Track track;
  final int bpm;

  const _LoopReadyCard({required this.track, required this.bpm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 176,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(track.albumCoverUrl),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$bpm BPM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1DB954),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.s),
          Text(
            track.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${track.artistName} • Electronic',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
