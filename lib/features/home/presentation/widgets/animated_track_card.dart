import 'package:flutter/material.dart';

import '../../../../core/constants/durations.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/models/track.dart';

/// Animated track card with entrance and tap animations.
///
/// Features:
/// - Staggered entrance animation with fade and scale
/// - Spring-based tap feedback (Curves.easeOutBack)
/// - Hero animation support for transitions
/// - Accessibility labels
class AnimatedTrackCard extends StatefulWidget {
  final Track track;
  final int delay;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AnimatedTrackCard({
    super.key,
    required this.track,
    this.delay = 0,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedTrackCard> createState() => _AnimatedTrackCardState();
}

class _AlbumPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AnimatedTrackCardState extends State<AnimatedTrackCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Tap animation state
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = _shouldReduceMotion(context);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return FadeTransition(
          opacity: reduceMotion
              ? const AlwaysStoppedAnimation(1.0)
              : _fadeAnimation,
          child: ScaleTransition(
            scale: reduceMotion
                ? const AlwaysStoppedAnimation(1.0)
                : _scaleAnimation,
            child: child,
          ),
        );
      },
      child: Semantics(
        label: 'Play ${widget.track.name} by ${widget.track.artistName}',
        button: true,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isTapped = true),
          onTapUp: (_) {
            setState(() => _isTapped = false);
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _isTapped = false),
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: _isTapped && !reduceMotion ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: _isTapped ? Curves.easeIn : Curves.easeOutBack,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album cover with Hero animation
                  Expanded(
                    child: Hero(
                      tag: 'track-${widget.track.id}',
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        child: widget.track.albumCoverUrl.isNotEmpty
                            ? Image.network(
                                widget.track.albumCoverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _AlbumPlaceholder(),
                              )
                            : _AlbumPlaceholder(),
                      ),
                    ),
                  ),

                  // Track info
                  Padding(
                    padding: const EdgeInsets.all(Spacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.track.name,
                          style: textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          widget.track.artistName,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          widget.track.formattedDuration,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
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

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );

    // Spring-like scale animation for entrance
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack, // M3E spring curve
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start entrance animation with stagger delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _entranceController.forward();
    });
  }

  bool _shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}
