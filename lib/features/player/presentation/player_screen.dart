import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/durations.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/models/playback_mode.dart';
import '../../../shared/models/track.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'widgets/mode_selector.dart';
import 'widgets/playback_controls.dart';
import 'widgets/section_selector.dart';
import 'widgets/waveform_display.dart';

/// Full-screen player with loop/skip mode selection.
class PlayerScreen extends StatefulWidget {
  final String trackId;

  const PlayerScreen({super.key, required this.trackId});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Playback state
  Track? _track;
  bool _isLoading = true;
  bool _isPlaying = false;
  PlaybackMode _currentMode = PlaybackMode.normal;
  SectionMarker? _section;
  Duration _currentPosition = Duration.zero;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const LoadingOverlay(message: 'Loading track...')
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
                              _buildAlbumArt(),
                              const SizedBox(height: Spacing.xl),

                              // Track info
                              _buildTrackInfo(textTheme, colorScheme),
                              const SizedBox(height: Spacing.xxl),

                              // Mode selector
                              ModeSelector(
                                currentMode: _currentMode,
                                onModeChanged: _onModeChanged,
                              ),
                              const SizedBox(height: Spacing.xl),

                              // Section selector (only for loop/skip modes)
                              if (_currentMode != PlaybackMode.normal &&
                                  _track != null)
                                SectionSelector(
                                  totalDuration: _track!.duration,
                                  sectionStart: _section?.startTime,
                                  sectionEnd: _section?.endTime,
                                  onStartChanged: _onSectionStartChanged,
                                  onEndChanged: _onSectionEndChanged,
                                ),
                              if (_currentMode != PlaybackMode.normal)
                                const SizedBox(height: Spacing.xl),

                              // Waveform/Progress
                              if (_track != null)
                                WaveformDisplay(
                                  duration: _track!.duration,
                                  position: _currentPosition,
                                  section: _currentMode != PlaybackMode.normal
                                      ? _section
                                      : null,
                                  mode: _currentMode,
                                  onSeek: _onSeek,
                                ),
                              const SizedBox(height: Spacing.xl),

                              // Playback controls
                              PlaybackControls(
                                isPlaying: _isPlaying,
                                onPlayPause: _togglePlayback,
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
    _loadTrack();
  }

  Widget _buildAlbumArt() {
    final colorScheme = Theme.of(context).colorScheme;

    return Hero(
      tag: 'track-${_track?.id}',
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
        child: _track?.albumCoverUrl.isNotEmpty == true
            ? Image.network(
                _track!.albumCoverUrl,
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

  Widget _buildTrackInfo(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          _track?.name ?? 'Unknown Track',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s),
        Text(
          _track?.artistName ?? 'Unknown Artist',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _loadTrack() async {
    // Simulate loading track data
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _track = Track(
          id: widget.trackId,
          name: 'Sample Track',
          artistName: 'Sample Artist',
          albumName: 'Sample Album',
          albumCoverUrl: 'https://picsum.photos/seed/${widget.trackId}/600/600',
          duration: const Duration(minutes: 3, seconds: 45),
          spotifyUri: 'spotify:track:${widget.trackId}',
        );
        // Set default section for loop/skip
        _section = SectionMarker(
          startTime: const Duration(seconds: 30),
          endTime: const Duration(minutes: 1, seconds: 15),
          label: 'Chorus',
        );
      });
    }
  }

  void _onAddToFavorites() {
    // TODO: Implement add to favorites
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${_track?.name}" to favorites'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onModeChanged(PlaybackMode mode) {
    setState(() => _currentMode = mode);
  }

  void _onSectionEndChanged(Duration end) {
    if (_section != null && end > _section!.startTime) {
      setState(() {
        _section = _section!.copyWith(endTime: end);
      });
    }
  }

  void _onSectionStartChanged(Duration start) {
    if (_section != null && start < _section!.endTime) {
      setState(() {
        _section = _section!.copyWith(startTime: start);
      });
    }
  }

  void _onSeek(Duration position) {
    setState(() => _currentPosition = position);
    // TODO: Implement actual seek
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

  void _togglePlayback() {
    setState(() => _isPlaying = !_isPlaying);
    // TODO: Implement actual playback control
  }
}
