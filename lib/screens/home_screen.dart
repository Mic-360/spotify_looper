/// Home screen with user data display and search.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../models/track.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/search_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/player_controls.dart';
import '../widgets/track_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize web player
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
    // Listen for playback errors
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
        child: Column(
          children: [
            Expanded(
              child: ResponsiveLayout(
                compact: (context) => _buildCompactLayout(context),
                medium: (context) => _buildMediumLayout(context),
                expanded: (context) => _buildExpandedLayout(context),
              ),
            ),
            // Player controls at bottom
            const PlayerControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildUserCard(context),
              const SizedBox(height: 24),
              _buildSearchBar(context),
              const SizedBox(height: 24),
              _buildSearchResults(context),
              _buildTopTracks(context),
              const SizedBox(height: 24),
              _buildRecentlyPlayed(context),
              const SizedBox(height: 100), // Space for player
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMediumLayout(BuildContext context) {
    return Row(
      children: [
        // Side panel with user info
        SizedBox(width: 300, child: _buildSidePanel(context)),
        // Main content
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSearchBar(context),
                    const SizedBox(height: 24),
                    _buildSearchResults(context),
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

  Widget _buildExpandedLayout(BuildContext context) {
    return Row(
      children: [
        // Left panel - user info and stats
        SizedBox(width: 320, child: _buildSidePanel(context)),
        // Center - search and results
        Expanded(
          flex: 2,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSearchBar(context),
                    const SizedBox(height: 24),
                    _buildSearchResults(context),
                    _buildTopTracks(context),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
        // Right panel - recently played
        SizedBox(width: 320, child: _buildRecentlyPlayedPanel(context)),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      floating: true,
      title: const Text('Spotify Looper'),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showUserMenu(context),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: user.imageUrl != null
                    ? CachedNetworkImageProvider(user.imageUrl!)
                    : null,
                backgroundColor: colorScheme.primaryContainer,
                child: user.imageUrl == null
                    ? Text(
                        user.displayName[0].toUpperCase(),
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

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
          // User card
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildUserCard(context),
          ),
          const Divider(),
          // Stats
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildUserStats(context),
            ),
          ),
          // Logout button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: user.isPremium
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.isPremium ? 'Premium' : 'Free',
                          style: textTheme.labelSmall?.copyWith(
                            color: user.isPremium
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on,
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
      ),
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
          icon: Icons.playlist_play,
          label: 'Playlists',
          value: playlists.valueOrNull?.length.toString() ?? '...',
        ),
        _buildStatTile(
          context,
          icon: Icons.person,
          label: 'Following',
          value: followedArtists.valueOrNull?.length.toString() ?? '...',
        ),
        _buildStatTile(
          context,
          icon: Icons.favorite,
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

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: (value) {
        ref.read(searchNotifierProvider.notifier).updateQuery(value);
      },
      decoration: InputDecoration(
        hintText: 'Search for songs, artists, or albums...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(searchNotifierProvider.notifier).clearSearch();
                },
              )
            : null,
      ),
    );
  }

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
        ...searchState.results.map(
          (track) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TrackCard(
              track: track,
              isPlaying: playerState.currentTrack?.id == track.id,
              onTap: () => _playTrack(track),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

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
              : Column(
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
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(context, error.toString()),
        ),
      ],
    );
  }

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
          data: (tracks) => tracks.isEmpty
              ? _buildEmptyState(context, 'No recently played tracks')
              : Column(
                  children: tracks
                      .take(5)
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
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(context, error.toString()),
        ),
      ],
    );
  }

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
              data: (tracks) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TrackCard(
                      track: track,
                      isPlaying: playerState.currentTrack?.id == track.id,
                      onTap: () => _playTrack(track),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

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

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final user = ref.read(currentUserProvider);
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              if (user != null) ...[
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.imageUrl != null
                      ? CachedNetworkImageProvider(user.imageUrl!)
                      : null,
                  backgroundColor: colorScheme.primaryContainer,
                  child: user.imageUrl == null
                      ? Text(
                          user.displayName[0].toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: colorScheme.onPrimaryContainer),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
