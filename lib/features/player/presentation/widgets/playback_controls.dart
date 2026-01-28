import 'package:flutter/material.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: isShuffleEnabled ? const Color(0xFF1DB954) : Colors.white24,
            size: 24,
          ),
          onPressed: onShuffle,
        ),
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            color: Colors.white,
            size: 42,
          ),
          onPressed: onPrevious,
        ),
        // Glass Play/Pause Button
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 48,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            color: Colors.white,
            size: 42,
          ),
          onPressed: onNext,
        ),
        IconButton(
          icon: Icon(
            Icons.repeat_rounded,
            color: isRepeatEnabled ? const Color(0xFF1DB954) : Colors.white24,
            size: 24,
          ),
          onPressed: onRepeat,
        ),
      ],
    );
  }
}
