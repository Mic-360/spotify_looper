/// Track grid card widget for staggered grid view with M3E styling.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/track.dart';

class TrackGridCard extends StatefulWidget {
  final SpotifyTrack track;
  final VoidCallback? onTap;
  final bool isPlaying;
  final bool isTall;

  const TrackGridCard({
    super.key,
    required this.track,
    this.onTap,
    this.isPlaying = false,
    this.isTall = false,
  });

  @override
  State<TrackGridCard> createState() => _TrackGridCardState();
}

class _TrackGridCardState extends State<TrackGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
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
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: widget.isPlaying
                  ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : _isHovered
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: widget.isPlaying
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 1,
                    ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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
                          top: Radius.circular(20),
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
                                      color: colorScheme.onSurfaceVariant,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      color: colorScheme.onSurfaceVariant,
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
                                    color: colorScheme.onSurfaceVariant,
                                    size: 40,
                                  ),
                                ),
                              ),
                      ),

                      // Play button overlay
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: AnimatedOpacity(
                          opacity: _isHovered || widget.isPlaying ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: AnimatedSlide(
                            offset: _isHovered || widget.isPlaying
                                ? Offset.zero
                                : const Offset(0, 0.3),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
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

                      // Playing indicator
                      if (widget.isPlaying)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
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
                                    fontWeight: FontWeight.w600,
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
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.isPlaying
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.track.artistNames,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
