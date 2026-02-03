/// Player controls widget with M3E styling.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive.dart';
import '../providers/player_provider.dart';
import 'mode_selector.dart';
import 'springy_button.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = context.isCompact;

    if (playerState.currentTrack == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
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
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Track info and controls
              Row(
                children: [
                  // Album art
                  _buildAlbumArt(playerState, colorScheme),
                  const SizedBox(width: 12),

                  // Track info
                  Expanded(child: _buildTrackInfo(playerState, context)),

                  // Controls
                  _buildControls(ref, playerState, colorScheme, isCompact),
                ],
              ),

              // Progress bar
              const SizedBox(height: 12),
              _buildProgressBar(ref, playerState, colorScheme, context),

              // Mode selector and Range slider (only for loop/skip)
              if (!isCompact) ...[
                const SizedBox(height: 16),
                const ModeSelector(),
                if (playerState.mode != PlayerMode.normal) ...[
                  const SizedBox(height: 16),
                  _buildRangeSlider(ref, playerState, colorScheme, context),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(PlaybackState state, ColorScheme colorScheme) {
    final track = state.currentTrack!;

    return Hero(
      tag: 'player-album-art',
      child: Container(
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
            ? CachedNetworkImage(imageUrl: track.artworkUrl!, fit: BoxFit.cover)
            : Container(
                color: colorScheme.primaryContainer,
                child: Icon(
                  Icons.music_note,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
      ),
    );
  }

  Widget _buildTrackInfo(PlaybackState state, BuildContext context) {
    final track = state.currentTrack!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          track.name,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
    );
  }

  Widget _buildControls(
    WidgetRef ref,
    PlaybackState state,
    ColorScheme colorScheme,
    bool isCompact,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCompact)
          ExpressiveIconButton(
            icon: Icons.skip_previous,
            onPressed: () => ref.read(playerProvider.notifier).skipPrevious(),
            size: 40,
          ),
        const SizedBox(width: 8),
        _PlayPauseButton(
          isPlaying: state.isPlaying,
          onPressed: () => ref.read(playerProvider.notifier).togglePlayPause(),
        ),
        const SizedBox(width: 8),
        if (!isCompact)
          ExpressiveIconButton(
            icon: Icons.skip_next,
            onPressed: () => ref.read(playerProvider.notifier).skipNext(),
            size: 40,
          ),
      ],
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
    // Initialize loop range if not set
    final dur = state.durationMs.toDouble();
    if (dur <= 0) return const SizedBox.shrink();

    // Ensure loopEndMs is valid
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

/// Animated play/pause button
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
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              widget.isPlaying ? Icons.pause : Icons.play_arrow,
              key: ValueKey(widget.isPlaying),
              color: colorScheme.onPrimary,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini player for compact view
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
          // Album art
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

          // Track info
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

          // Play/pause button
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
