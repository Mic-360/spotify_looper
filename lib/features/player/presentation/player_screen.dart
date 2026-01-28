import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/durations.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/models/playback_mode.dart';
import '../../../shared/models/track.dart';
import '../data/player_repository.dart';
import 'widgets/mode_selector.dart';
import 'widgets/playback_controls.dart';
import 'widgets/section_selector.dart';
import 'widgets/waveform_display.dart';

/// Full-screen player with Pulse Loop aesthetic and glows.
class PlayerScreen extends ConsumerStatefulWidget {
  final String trackId;

  const PlayerScreen({super.key, required this.trackId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
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

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final playbackState = ref.watch(playbackStateProvider);
    final playbackNotifier = ref.read(playbackStateProvider.notifier);

    final track = playbackState.currentTrack;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          _buildBackgroundGlows(),
          SafeArea(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.xl,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: Spacing.xl),
                                  // Album art
                                  _buildAlbumArt(track),
                                  const SizedBox(height: Spacing.xxl),

                                  // Track info
                                  _buildTrackInfo(track, textTheme),
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
                                      sectionEnd:
                                          playbackState.section?.endTime,
                                      onStartChanged: (start) {
                                        final currentSection =
                                            playbackState.section ??
                                            SectionMarker(
                                              startTime: start,
                                              endTime: track.duration,
                                            );
                                        playbackNotifier.setSection(
                                          currentSection.copyWith(
                                            startTime: start,
                                          ),
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
                                        playbackState.mode !=
                                            PlaybackMode.normal
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
                                  const SizedBox(height: Spacing.xxxl),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTrack();
    });
  }

  Widget _buildAlbumArt(Track track) {
    return Hero(
      tag: 'track-${track.id}',
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: track.albumCoverUrl.isNotEmpty
            ? Image.network(
                track.albumCoverUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildAlbumPlaceholder(),
              )
            : _buildAlbumPlaceholder(),
      ),
    );
  }

  Widget _buildAlbumPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: const Center(
        child: Icon(Icons.music_note_rounded, size: 80, color: Colors.white24),
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
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () => context.pop(),
            tooltip: 'Close',
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: Colors.white70,
            ),
            onPressed: _onAddToFavorites,
            tooltip: 'Add to favorites',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            onPressed: () {},
            tooltip: 'Share',
          ),
          const SizedBox(width: Spacing.s),
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
            left: -100,
            color: Colors.blue.withValues(alpha: 0.1),
            size: 500,
          ),
          _GlowBlob(
            bottom: 100,
            right: -150,
            color: const Color(0xFF1DB954).withValues(alpha: 0.05),
            size: 400,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1DB954)),
    );
  }

  Widget _buildTrackInfo(Track track, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          track.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s),
        Text(
          track.artistName,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
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
