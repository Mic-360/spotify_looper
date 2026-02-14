/// Track grid card widget with M3 Expressive styling inspired by modern glassmorphism.
/// Features: pedestal artwork containers, atmospheric glow shadows, spring animations.
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.elasticOut),
    );

    // Staggered entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _entranceSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Cubic(0.34, 1.56, 0.64, 1), // M3E spring curve
      ),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Stagger the entrance based on index
    Future.delayed(Duration(milliseconds: 50 * widget.animationIndex), () {
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

  // Get a pedestal/glow color based on the animation index to mimic the variety in the image
  Color _getExpressiveColor(ColorScheme colorScheme) {
    final colors = [
      const Color(0xFF64B5F6), // Blue
      const Color(0xFFFFB74D), // Amber
      const Color(0xFF81C784), // Green
      const Color(0xFFBA68C8), // Purple
      const Color(0xFFE57373), // Red
    ];
    return colors[widget.animationIndex % colors.length];
  }

  // Get a pedestal background color (soft/muted)
  Color _getPedestalColor(ColorScheme colorScheme) {
    final colors = [
      const Color(0xFFCEC8BC), // Clay
      const Color(0xFFEBDCCB), // Peach-nude
      const Color(0xFFD1DCD1), // Sage
      const Color(0xFFDCD1DC), // Muted Purple
      const Color(0xFFDCD1D1), // Muted Rose
    ];
    return colors[widget.animationIndex % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final expressiveColor = _getExpressiveColor(colorScheme);
    final pedestalColor = _getPedestalColor(colorScheme);

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
            child: Container(
              decoration: BoxDecoration(
                color: widget.isPlaying
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: widget.isPlaying
                      ? expressiveColor.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  // Atmospheric glow shadow
                  BoxShadow(
                    color: widget.isPlaying
                        ? expressiveColor.withValues(alpha: 0.3)
                        : _isHovered
                        ? expressiveColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    blurRadius: 32,
                    spreadRadius: -4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artwork Pedestal
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: pedestalColor,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Main Album Art (slightly smaller, floating)
                            Positioned.fill(
                              left: 14,
                              right: 14,
                              top: 14,
                              bottom: 14,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: widget.track.artworkUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: widget.track.artworkUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              _buildPlaceholder(colorScheme),
                                          errorWidget: (context, url, err) =>
                                              _buildPlaceholder(colorScheme),
                                        )
                                      : _buildPlaceholder(colorScheme),
                                ),
                              ),
                            ),

                            // Floating Play Button (as in image)
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: AnimatedOpacity(
                                opacity: _isHovered || widget.isPlaying
                                    ? 1.0
                                    : 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: widget.isPlaying
                                            ? expressiveColor
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        widget.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: widget.isPlaying
                                            ? Colors.white
                                            : Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Playing Label (Pedestal style)
                            if (widget.isPlaying)
                              Positioned(
                                top: -6,
                                left: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: expressiveColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: expressiveColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'NOW PLAYING',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.track.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.track.explicit)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.explicit_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                widget.track.artistNames,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
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

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.white.withValues(alpha: 0.2),
          size: 40,
        ),
      ),
    );
  }
}
