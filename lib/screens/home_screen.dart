/// Home screen with M3E design — collapsing title, staggered grid, pill player.
library;

import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../models/track.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/search_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/player_controls.dart';
import '../widgets/track_card.dart';
import '../widgets/track_grid_card.dart';

enum ViewMode { grid, list }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  ViewMode _viewMode = ViewMode.grid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProvider.notifier).initializePlayer();
    });
  }

  String? _lastError;

  void _showErrorIfNeeded(String? error) {
    if (error != null && error != _lastError) {
      _lastError = error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlaybackState>(playerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        _showErrorIfNeeded(next.error);
      }
    });

    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: context.isCompact
            ? Stack(
                children: [
                  // Content fills entire area
                  Positioned.fill(
                    child: ResponsiveLayout(
                      compact: (context) => _buildCompactLayout(context),
                      medium: (context) => _buildMediumLayout(context),
                      expanded: (context) => _buildExpandedLayout(context),
                    ),
                  ),
                  // Pill player floats at bottom
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: PlayerControls(),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: ResponsiveLayout(
                      compact: (context) => _buildCompactLayout(context),
                      medium: (context) => _buildMediumLayout(context),
                      expanded: (context) => _buildExpandedLayout(context),
                    ),
                  ),
                  const DesktopPlayerControls(),
                ],
              ),
      ),
    );
  }

  // ===========================================================================
  // COMPACT LAYOUT (Mobile)
  // ===========================================================================

  Widget _buildCompactLayout(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final isSearching = searchState.query.isNotEmpty;

    return CustomScrollView(
      slivers: [
        _buildCollapsingAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),
              if (isSearching) ...[
                _buildSearchResults(context),
              ] else ...[
                _buildViewToggle(context),
                const SizedBox(height: 16),
                _buildTopTracks(context),
                const SizedBox(height: 24),
                _buildRecentlyPlayed(context),
                const SizedBox(height: 24),
                _buildUserCard(context),
              ],
              // Extra space so content isn't hidden behind floating pill player
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MEDIUM LAYOUT (Tablet)
  // ===========================================================================

  Widget _buildMediumLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 300, child: _buildSidePanel(context)),
        Expanded(
          child: CustomScrollView(
            slivers: [
              _buildCollapsingAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),
                    _buildSearchResults(context),
                    _buildViewToggle(context),
                    const SizedBox(height: 16),
                    _buildTopTracks(context),
                    const SizedBox(height: 24),
                    _buildRecentlyPlayed(context),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // EXPANDED LAYOUT (Desktop)
  // ===========================================================================

  Widget _buildExpandedLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 320, child: _buildSidePanel(context)),
        Expanded(
          flex: 2,
          child: CustomScrollView(
            slivers: [
              _buildCollapsingAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),
                    _buildSearchResults(context),
                    _buildViewToggle(context),
                    const SizedBox(height: 16),
                    _buildTopTracks(context),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 320, child: _buildRecentlyPlayedPanel(context)),
      ],
    );
  }

  // ===========================================================================
  // COLLAPSING APP BAR — Big "Pulse Loop" that shrinks on scroll
  // ===========================================================================

  Widget _buildCollapsingAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      floating: false,
      pinned: true,
      expandedHeight: 160,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 72),
        expandedTitleScale: 2.4,
        title: Text(
          'Pulse Loop',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildSearchBar(context),
        ),
      ),
    );
  }

  // ===========================================================================
  // SIDE PANEL (Medium / Expanded)
  // ===========================================================================

  Widget _buildSidePanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildUserCard(context),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildUserStats(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: Icon(Icons.logout, color: colorScheme.error),
                label: const Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // USER CARD — rich details from Spotify
  // ===========================================================================

  Widget _buildUserCard(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    ref.watch(userStatsProvider);
    final playlists = ref.watch(playlistsProvider);
    final followedArtists = ref.watch(followedArtistsProvider);

    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + Name + Badge row
            Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: user.imageUrl != null
                        ? CachedNetworkImageProvider(user.imageUrl!)
                        : null,
                    backgroundColor: colorScheme.primaryContainer,
                    child: user.imageUrl == null
                        ? Text(
                            user.displayName[0].toUpperCase(),
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Premium / Free badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: user.isPremium
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (user.isPremium)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.verified_rounded,
                                      size: 12,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                Text(
                                  user.isPremium ? 'Premium' : 'Free',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: user.isPremium
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Country
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            user.country,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Divider
            Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              height: 1,
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  context,
                  '${user.followers}',
                  'Followers',
                  Icons.people_outline_rounded,
                ),
                _buildStatColumn(
                  context,
                  playlists.valueOrNull?.length.toString() ?? '...',
                  'Playlists',
                  Icons.playlist_play_rounded,
                ),
                _buildStatColumn(
                  context,
                  followedArtists.valueOrNull?.length.toString() ?? '...',
                  'Following',
                  Icons.person_add_alt_rounded,
                ),
              ],
            ),

            // Logout button for compact layout
            if (context.isCompact) ...[
              const SizedBox(height: 16),
              SizedBox(
                // width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _handleLogout,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildUserStats(BuildContext context) {
    final playlists = ref.watch(playlistsProvider);
    final followedArtists = ref.watch(followedArtistsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Library',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildStatTile(
          context,
          icon: Icons.playlist_play_rounded,
          label: 'Playlists',
          value: playlists.valueOrNull?.length.toString() ?? '...',
        ),
        _buildStatTile(
          context,
          icon: Icons.person_rounded,
          label: 'Following',
          value: followedArtists.valueOrNull?.length.toString() ?? '...',
        ),
        _buildStatTile(
          context,
          icon: Icons.favorite_rounded,
          label: 'Liked Songs',
          value: '...',
        ),
      ],
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(label, style: textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SEARCH BAR — M3 Expressive style
  // ===========================================================================

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                ref.read(searchNotifierProvider.notifier).updateQuery(value);
                setState(() {}); // Rebuild for clear button
              },
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search songs, artists, albums...',
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Icon(Icons.search_rounded, color: colorScheme.primary),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(searchNotifierProvider.notifier)
                                .clearSearch();
                            setState(() {});
                          },
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // VIEW MODE TOGGLE — Grid / List
  // ===========================================================================

  Widget _buildViewToggle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      context,
                      icon: Icons.grid_view_rounded,
                      label: 'Grid',
                      isSelected: _viewMode == ViewMode.grid,
                      onTap: () => setState(() => _viewMode = ViewMode.grid),
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      context,
                      icon: Icons.view_list_rounded,
                      label: 'List',
                      isSelected: _viewMode == ViewMode.list,
                      onTap: () => setState(() => _viewMode = ViewMode.list),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SEARCH RESULTS — Always list view
  // ===========================================================================

  Widget _buildSearchResults(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final playerState = ref.watch(playerProvider);
    final textTheme = Theme.of(context).textTheme;

    if (searchState.query.isEmpty) {
      return const SizedBox.shrink();
    }

    if (searchState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (searchState.results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No results found for "${searchState.query}"',
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(
              2,
              6,
            );
            return MasonryGridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: searchState.results.length,
              itemBuilder: (context, index) {
                final track = searchState.results[index];
                return TrackGridCard(
                  track: track,
                  isPlaying: playerState.currentTrack?.id == track.id,
                  animationIndex: index,
                  onTap: () => _playTrack(track),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // TOP TRACKS — Grid or List with staggered grid view
  // ===========================================================================

  Widget _buildTopTracks(BuildContext context) {
    final topTracks = ref.watch(topTracksProvider);
    final playerState = ref.watch(playerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Top Tracks',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        topTracks.when(
          data: (tracks) => tracks.isEmpty
              ? _buildEmptyState(context, 'No top tracks yet')
              : _viewMode == ViewMode.grid
              ? _buildStaggeredGrid(tracks, playerState)
              : _buildTrackList(tracks, playerState),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(context, error.toString()),
        ),
      ],
    );
  }

  // ===========================================================================
  // RECENTLY PLAYED — Grid or List, with deduplication
  // ===========================================================================

  Widget _buildRecentlyPlayed(BuildContext context) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final playerState = ref.watch(playerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Played',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        recentlyPlayed.when(
          data: (tracks) {
            final deduplicated = _deduplicateTracks(tracks);
            return deduplicated.isEmpty
                ? _buildEmptyState(context, 'No recently played tracks')
                : _viewMode == ViewMode.grid
                ? _buildStaggeredGrid(deduplicated, playerState)
                : _buildTrackList(deduplicated, playerState);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(context, error.toString()),
        ),
      ],
    );
  }

  /// Deduplicate tracks by ID, keeping the first occurrence.
  List<SpotifyTrack> _deduplicateTracks(List<SpotifyTrack> tracks) {
    final seen = <String>{};
    return tracks.where((track) => seen.add(track.id)).toList();
  }

  // ===========================================================================
  // STAGGERED GRID — using flutter_staggered_grid_view
  // ===========================================================================

  Widget _buildStaggeredGrid(
    List<SpotifyTrack> tracks,
    PlaybackState playerState,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic column count based on width:
        // ~180px per card is a good target for M3E cards
        final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(2, 8);

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return TrackGridCard(
              track: track,
              isPlaying: playerState.currentTrack?.id == track.id,
              animationIndex: index,
              onTap: () => _playTrack(track),
            );
          },
        );
      },
    );
  }

  Widget _buildTrackList(List<SpotifyTrack> tracks, PlaybackState playerState) {
    return Column(
      children: tracks
          .map(
            (track) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TrackCard(
                track: track,
                isPlaying: playerState.currentTrack?.id == track.id,
                onTap: () => _playTrack(track),
              ),
            ),
          )
          .toList(),
    );
  }

  // ===========================================================================
  // RECENTLY PLAYED PANEL (Desktop expanded layout)
  // ===========================================================================

  Widget _buildRecentlyPlayedPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final playerState = ref.watch(playerProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Recently Played',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: recentlyPlayed.when(
              data: (tracks) {
                final deduplicated = _deduplicateTracks(tracks);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: deduplicated.length,
                  itemBuilder: (context, index) {
                    final track = deduplicated[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TrackCard(
                        track: track,
                        isPlaying: playerState.currentTrack?.id == track.id,
                        onTap: () => _playTrack(track),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Widget _buildEmptyState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Error: $error',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
    );
  }

  void _playTrack(SpotifyTrack track) {
    ref.read(playerProvider.notifier).playTrack(track);
  }

  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }
}
