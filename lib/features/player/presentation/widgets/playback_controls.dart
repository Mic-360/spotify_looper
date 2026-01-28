import 'package:flutter/material.dart';

import '../../../../core/constants/durations.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/spring_button.dart';

/// Playback controls with play/pause, previous, and next buttons.
class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final bool isShuffleEnabled;
  final bool isRepeatEnabled;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    this.onShuffle,
    this.onRepeat,
    this.isShuffleEnabled = false,
    this.isRepeatEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle button
        if (onShuffle != null)
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: isShuffleEnabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: onShuffle,
            tooltip: 'Shuffle',
          ),
        if (onShuffle != null) const SizedBox(width: Spacing.m),

        // Previous button
        SpringIconButton(
          icon: Icons.skip_previous,
          onPressed: onPrevious,
          size: 36,
          tooltip: 'Previous',
          semanticLabel: 'Previous track',
        ),
        const SizedBox(width: Spacing.l),

        // Play/Pause button (larger with animation)
        _PlayPauseButton(isPlaying: isPlaying, onPressed: onPlayPause),
        const SizedBox(width: Spacing.l),

        // Next button
        SpringIconButton(
          icon: Icons.skip_next,
          onPressed: onNext,
          size: 36,
          tooltip: 'Next',
          semanticLabel: 'Next track',
        ),

        // Repeat button
        if (onRepeat != null) const SizedBox(width: Spacing.m),
        if (onRepeat != null)
          IconButton(
            icon: Icon(
              Icons.repeat,
              color: isRepeatEnabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: onRepeat,
            tooltip: 'Repeat',
          ),
      ],
    );
  }
}

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: widget.isPlaying ? 'Pause' : 'Play',
      button: true,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: AppDurations.mediumFast,
            curve: Curves.easeOutBack,
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                key: ValueKey(widget.isPlaying),
                color: colorScheme.onPrimary,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }
}
