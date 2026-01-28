import 'dart:ui';

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
    final playbackState = ref.watch(playbackStateProvider);
    final playbackNotifier = ref.read(playbackStateProvider.notifier);
    final track = playbackState.currentTrack;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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

                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  const SizedBox(height: Spacing.m),
                                  // Album art
                                  _buildAlbumArt(track, playbackState.mode),
                                  const SizedBox(height: Spacing.xl),

                                  // Track info
                                  _buildTrackInfo(track),
                                  const SizedBox(height: Spacing.xl),

                                  // Mode selector
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Spacing.xl,
                                    ),
                                    child: ModeSelector(
                                      currentMode: playbackState.mode,
                                      onModeChanged: playbackNotifier.setMode,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

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
                                    onSectionStartChanged: (start) {
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
                                    onSectionEndChanged: (end) {
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

                                  const SizedBox(height: 40),

                                  // Playback controls
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Spacing.xl,
                                    ),
                                    child: PlaybackControls(
                                      isPlaying: playbackState.isPlaying,
                                      onPlayPause: playbackNotifier.togglePlay,
                                      onPrevious: () {},
                                      onNext: () {},
                                    ),
                                  ),

                                  const SizedBox(height: 32),
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

  Widget _buildAlbumArt(Track track, PlaybackMode mode) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background glow
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
            // Art
            Hero(
              tag: 'track-${track.id}',
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
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
            ),
            // Mode Badge
            if (mode != PlaybackMode.normal)
              Positioned(
                top: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getModeColor(mode),
                              boxShadow: [
                                BoxShadow(
                                  color: _getModeColor(
                                    mode,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mode == PlaybackMode.loop
                                ? 'LOOP ACTIVE'
                                : 'SKIP ACTIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.expand_more_rounded,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          const Column(
            children: [
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Cyber Collective',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
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
          Container(color: const Color(0xFF121212)),
          _GlowBlob(
            top: -100,
            left: -100,
            color: const Color(0xFF1DB954).withValues(alpha: 0.08),
            size: 500,
          ),
          _GlowBlob(
            bottom: 100,
            right: -150,
            color: Colors.blue.withValues(alpha: 0.05),
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

  Widget _buildTrackInfo(Track track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artistName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFF1DB954),
              size: 32,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Color _getModeColor(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.normal:
        return const Color(0xFF1DB954);
      case PlaybackMode.loop:
        return const Color(0xFF10B981);
      case PlaybackMode.skip:
        return const Color(0xFFEF4444);
    }
  }

  void _initializeTrack() {
    final mockTrack = Track(
      id: widget.trackId,
      name: 'Neon Nights',
      artistName: 'Cyber Collective',
      albumName: 'Abstract Shapes',
      albumCoverUrl: 'https://picsum.photos/seed/${widget.trackId}/600/600',
      duration: const Duration(minutes: 3, seconds: 45),
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
