import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/durations.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/models/playback_mode.dart';
import '../../../shared/models/track.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../data/player_repository.dart';
import 'widgets/mode_selector.dart';
import 'widgets/playback_controls.dart';
import 'widgets/section_selector.dart';
import 'widgets/waveform_display.dart';

/// Full-screen player with loop/skip mode selection.
class PlayerScreen extends ConsumerStatefulWidget {
  final String trackId;

  const PlayerScreen({super.key, required this.trackId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playbackState = ref.watch(playbackStateProvider);
    final playbackNotifier = ref.read(playbackStateProvider.notifier);

    final track = playbackState.currentTrack;

    return Scaffold(
      body: SafeArea(
        child: track == null
            ? _buildInitialLoading(context)
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // App bar
                      _buildAppBar(context),

                      // Main content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(Spacing.l),
                          child: Column(
                            children: [
                              // Album art
                              _buildAlbumArt(track),
                              const SizedBox(height: Spacing.xl),

                              // Track info
                              _buildTrackInfo(track, textTheme, colorScheme),
                              const SizedBox(height: Spacing.xxl),

                              // Mode selector
                              ModeSelector(
                                currentMode: playbackState.mode,
                                onModeChanged: playbackNotifier.setMode,
                              ),
                              const SizedBox(height: Spacing.xl),

                              // Section selector (only for loop/skip modes)
                              if (playbackState.mode != PlaybackMode.normal)
                                SectionSelector(
                                  totalDuration: track.duration,
                                  sectionStart:
                                      playbackState.section?.startTime,
                                  sectionEnd: playbackState.section?.endTime,
                                  onStartChanged: (start) {
                                    final currentSection =
                                        playbackState.section ??
                                        SectionMarker(
                                          startTime: start,
                                          endTime: track.duration,
                                        );
                                    playbackNotifier.setSection(
                                      currentSection.copyWith(startTime: start),
                                    );
                                  },
                                  onEndChanged: (end) {
                                    final currentSection =
                                        playbackState.section ??
                                        SectionMarker(
                                          startTime: Duration.zero,
                                          endTime: end,
                                        );
                                    playbackNotifier.setSection(
                                      currentSection.copyWith(endTime: end),
                                    );
                                  },
                                ),
                              if (playbackState.mode != PlaybackMode.normal)
                                const SizedBox(height: Spacing.xl),

                              // Waveform/Progress
                              WaveformDisplay(
                                duration: track.duration,
                                position: playbackState.position,
                                section:
                                    playbackState.mode != PlaybackMode.normal
                                    ? playbackState.section
                                    : null,
                                mode: playbackState.mode,
                                onSeek: playbackNotifier.seek,
                              ),
                              const SizedBox(height: Spacing.xl),

                              // Playback controls
                              PlaybackControls(
                                isPlaying: playbackState.isPlaying,
                                onPlayPause: playbackNotifier.togglePlay,
                                onPrevious: () {},
                                onNext: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // In a real app, we'd fetch the track data from Spotify first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTrack();
    });
  }

  Widget _buildAlbumArt(Track track) {
    final colorScheme = Theme.of(context).colorScheme;

    return Hero(
      tag: 'track-${track.id}',
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: track.albumCoverUrl.isNotEmpty == true
            ? Image.network(
                track.albumCoverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildAlbumPlaceholder(colorScheme),
              )
            : _buildAlbumPlaceholder(colorScheme),
      ),
    );
  }

  Widget _buildAlbumPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 80,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s,
        vertical: Spacing.s,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            tooltip: 'Back',
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: _onAddToFavorites,
            tooltip: 'Add to favorites',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoading(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [LoadingOverlay(message: 'Initializing player...')],
      ),
    );
  }

  Widget _buildTrackInfo(
    Track track,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Text(
          track.name,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s),
        Text(
          track.artistName,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _initializeTrack() {
    // This is still a bit mocky but it's now integrated with the state notifier
    final mockTrack = Track(
      id: widget.trackId,
      name: 'High Fidelity Track',
      artistName: 'Premium Artist',
      albumName: 'Expressive Album',
      albumCoverUrl: 'https://picsum.photos/seed/${widget.trackId}/600/600',
      duration: const Duration(minutes: 4, seconds: 20),
      spotifyUri: 'spotify:track:${widget.trackId}',
    );

    ref.read(playbackStateProvider.notifier).playTrack(mockTrack);
    ref
        .read(playbackStateProvider.notifier)
        .setSection(
          SectionMarker(
            startTime: const Duration(seconds: 45),
            endTime: const Duration(minutes: 1, seconds: 30),
            label: 'Chorus',
          ),
        );
  }

  void _onAddToFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added track to favorites'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setupAnimations() {
    _entranceController = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutBack,
          ),
        );

    _entranceController.forward();
  }
}
