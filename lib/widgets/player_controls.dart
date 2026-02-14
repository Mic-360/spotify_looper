/// Player controls widget with M3E pill-style player and expandable card.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';
import 'mode_selector.dart';
import 'springy_button.dart';

class PlayerControls extends ConsumerStatefulWidget {
  const PlayerControls({super.key});

  @override
  ConsumerState<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends ConsumerState<PlayerControls>
    with SingleTickerProviderStateMixin {
  void _showExpandedPlayer(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      builder: (context) => const _ExpandedPlayerCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);

    if (playerState.currentTrack == null) {
      return const SizedBox.shrink();
    }

    return _PillPlayer(onTap: () => _showExpandedPlayer(context));
  }
}

/// Pill-shaped mini player at the bottom
class _PillPlayer extends ConsumerWidget {
  final VoidCallback onTap;

  const _PillPlayer({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final track = playerState.currentTrack!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album art
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: track.artworkUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.artworkUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.music_note_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Track info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artistNames,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Play/pause button
            _MiniPlayPauseButton(
              isPlaying: playerState.isPlaying,
              onPressed: () =>
                  ref.read(playerProvider.notifier).togglePlayPause(),
            ),
            const SizedBox(width: 4),

            // Skip next
            IconButton(
              onPressed: () => ref.read(playerProvider.notifier).skipNext(),
              icon: Icon(Icons.skip_next_rounded, color: colorScheme.onSurface),
              visualDensity: VisualDensity.compact,
              iconSize: 22,
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _MiniPlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(isPlaying),
            color: colorScheme.onPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Expanded player card shown as modal bottom sheet
class _ExpandedPlayerCard extends ConsumerWidget {
  const _ExpandedPlayerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final track = playerState.currentTrack!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle — always at top
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Centered content fills remaining space
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Album art size scales with available height
                    final artSize = (constraints.maxHeight * 0.30).clamp(
                      120.0,
                      300.0,
                    );

                    return SingleChildScrollView(
                      controller: scrollController,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Album art
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: artSize,
                                    height: artSize,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: track.artworkUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: track.artworkUrl!,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color:
                                                  colorScheme.primaryContainer,
                                              child: Center(
                                                child: Icon(
                                                  Icons.music_note_rounded,
                                                  size: 64,
                                                  color: colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              // Track info
                              Text(
                                track.name,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                track.artistNames,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                track.album.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),

                              // Progress bar
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                child: _buildProgressBar(
                                  ref,
                                  playerState,
                                  colorScheme,
                                  context,
                                ),
                              ),

                              // Main controls
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      onPressed: () => ref
                                          .read(playerProvider.notifier)
                                          .skipPrevious(),
                                      icon: const Icon(
                                        Icons.skip_previous_rounded,
                                      ),
                                      iconSize: 36,
                                    ),
                                    _PlayPauseButton(
                                      isPlaying: playerState.isPlaying,
                                      onPressed: () => ref
                                          .read(playerProvider.notifier)
                                          .togglePlayPause(),
                                    ),
                                    IconButton(
                                      onPressed: () => ref
                                          .read(playerProvider.notifier)
                                          .skipNext(),
                                      icon: const Icon(Icons.skip_next_rounded),
                                      iconSize: 36,
                                    ),
                                  ],
                                ),
                              ),

                              // Mode selector
                              const SizedBox(height: 8),
                              const ModeSelector(),

                              // Range slider if looping/skipping
                              if (playerState.mode != PlayerMode.normal)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: _buildRangeSlider(
                                    ref,
                                    playerState,
                                    colorScheme,
                                    context,
                                  ),
                                ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(
    WidgetRef ref,
    PlaybackState state,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: state.progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final positionMs = (value * state.durationMs).round();
              ref.read(playerProvider.notifier).seek(positionMs);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.formattedPosition,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                state.formattedDuration,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSlider(
    WidgetRef ref,
    PlaybackState state,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final dur = state.durationMs.toDouble();
    if (dur <= 0) return const SizedBox.shrink();

    final loopStart = state.loopStartMs.toDouble().clamp(0.0, dur);
    var loopEnd = state.loopEndMs.toDouble().clamp(0.0, dur);
    if (loopEnd <= loopStart) {
      loopEnd = dur;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${_formatMs(loopStart.toInt())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                state.mode == PlayerMode.loop ? 'Loop Range' : 'Skip Range',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                'End: ${_formatMs(loopEnd.toInt())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            activeTrackColor: state.mode == PlayerMode.loop
                ? colorScheme.primary
                : colorScheme.error,
          ),
          child: RangeSlider(
            values: RangeValues(loopStart, loopEnd),
            min: 0,
            max: dur,
            onChanged: (values) {
              ref
                  .read(playerProvider.notifier)
                  .setLoopRange(values.start.round(), values.end.round());
            },
          ),
        ),
      ],
    );
  }

  String _formatMs(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Animated play/pause button for expanded player
class _PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({required this.isPlaying, required this.onPressed});

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Squircle when playing, circle when paused
    final borderRadius = widget.isPlaying
        ? BorderRadius.circular(20) // squircle
        : BorderRadius.circular(32); // circle

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(widget.isPlaying),
              color: colorScheme.onPrimary,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

/// Desktop/medium player controls (non-compact)
class DesktopPlayerControls extends ConsumerWidget {
  const DesktopPlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (playerState.currentTrack == null) {
      return const SizedBox.shrink();
    }

    final track = playerState.currentTrack!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Album art
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: track.artworkUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.artworkUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.music_note_rounded,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artistNames,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Controls
                  ExpressiveIconButton(
                    icon: Icons.skip_previous_rounded,
                    onPressed: () =>
                        ref.read(playerProvider.notifier).skipPrevious(),
                    size: 40,
                  ),
                  const SizedBox(width: 8),
                  _PlayPauseButton(
                    isPlaying: playerState.isPlaying,
                    onPressed: () =>
                        ref.read(playerProvider.notifier).togglePlayPause(),
                  ),
                  const SizedBox(width: 8),
                  ExpressiveIconButton(
                    icon: Icons.skip_next_rounded,
                    onPressed: () =>
                        ref.read(playerProvider.notifier).skipNext(),
                    size: 40,
                  ),
                ],
              ),

              // Progress bar
              const SizedBox(height: 12),
              _buildProgressBar(ref, playerState, colorScheme, context),

              // Mode selector
              const SizedBox(height: 16),
              const ModeSelector(),
              if (playerState.mode != PlayerMode.normal) ...[
                const SizedBox(height: 16),
                _buildRangeSlider(ref, playerState, colorScheme, context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    WidgetRef ref,
    PlaybackState state,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: state.progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final positionMs = (value * state.durationMs).round();
              ref.read(playerProvider.notifier).seek(positionMs);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.formattedPosition,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                state.formattedDuration,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSlider(
    WidgetRef ref,
    PlaybackState state,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final dur = state.durationMs.toDouble();
    if (dur <= 0) return const SizedBox.shrink();

    final loopStart = state.loopStartMs.toDouble().clamp(0.0, dur);
    var loopEnd = state.loopEndMs.toDouble().clamp(0.0, dur);
    if (loopEnd <= loopStart) {
      loopEnd = dur;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${_formatMs(loopStart.toInt())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                state.mode == PlayerMode.loop ? 'Loop Range' : 'Skip Range',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                'End: ${_formatMs(loopEnd.toInt())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            activeTrackColor: state.mode == PlayerMode.loop
                ? colorScheme.primary
                : colorScheme.error,
          ),
          child: RangeSlider(
            values: RangeValues(loopStart, loopEnd),
            min: 0,
            max: dur,
            onChanged: (values) {
              ref
                  .read(playerProvider.notifier)
                  .setLoopRange(values.start.round(), values.end.round());
            },
          ),
        ),
      ],
    );
  }

  String _formatMs(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Mini player for compact view (kept for backward compat)
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (playerState.currentTrack == null) {
      return const SizedBox.shrink();
    }

    final track = playerState.currentTrack!;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (track.artworkUrl != null)
            CachedNetworkImage(
              imageUrl: track.artworkUrl!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            )
          else
            Container(
              width: 64,
              height: 64,
              color: colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artistNames,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(playerProvider.notifier).togglePlayPause(),
            icon: Icon(playerState.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
