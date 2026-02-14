/// Track grid card widget with M3 Expressive styling.
/// Features: album art glow shadow, spring animations, staggered entrance.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/track.dart';

class TrackGridCard extends StatefulWidget {
  final SpotifyTrack track;
  final VoidCallback? onTap;
  final bool isPlaying;
  final bool isTall;
  final int animationIndex;

  const TrackGridCard({
    super.key,
    required this.track,
    this.onTap,
    this.isPlaying = false,
    this.isTall = false,
    this.animationIndex = 0,
  });

  @override
  State<TrackGridCard> createState() => _TrackGridCardState();
}

class _TrackGridCardState extends State<TrackGridCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late AnimationController _entranceController;
  late Animation<double> _entranceSlide;
  late Animation<double> _entranceOpacity;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    // Hover / press spring animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.elasticOut),
    );

    // Staggered entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _entranceSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Cubic(0.34, 1.56, 0.64, 1), // M3E spring curve
      ),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Stagger the entrance based on index
    Future.delayed(Duration(milliseconds: 60 * widget.animationIndex), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _entranceSlide.value),
          child: Opacity(opacity: _entranceOpacity.value, child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: widget.isPlaying
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : _isHovered
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: widget.isPlaying
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.7),
                        width: 2,
                      )
                    : Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.2,
                        ),
                        width: 1,
                      ),
                boxShadow: [
                  // Album art color glow
                  if (widget.isPlaying)
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    )
                  else if (_isHovered)
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album art
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: widget.track.artworkUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.track.artworkUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: Icon(
                                        Icons.music_note_rounded,
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.5,
                                        ),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: Center(
                                          child: Icon(
                                            Icons.music_note_rounded,
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.5),
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      size: 40,
                                    ),
                                  ),
                                ),
                        ),

                        // Play button overlay with spring
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: AnimatedOpacity(
                            opacity: _isHovered || widget.isPlaying ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            child: AnimatedSlide(
                              offset: _isHovered || widget.isPlaying
                                  ? Offset.zero
                                  : const Offset(0, 0.3),
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.elasticOut,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: colorScheme.onPrimary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Playing indicator pill
                        if (widget.isPlaying)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.equalizer_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Playing',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Track info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.track.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.isPlaying
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (widget.track.explicit)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.explicit_rounded,
                                  size: 14,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                widget.track.artistNames,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ),
        ),
      ),
    );
  }
}
