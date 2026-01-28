import 'package:flutter/material.dart';

import '../../../../core/constants/durations.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/models/playback_mode.dart';
import '../favorites_screen.dart';

/// List item for favorite tracks with mode indicator.
class FavoriteListItem extends StatefulWidget {
  final FavoriteTrackItem item;
  final int delay;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FavoriteListItem({
    super.key,
    required this.item,
    this.delay = 0,
    this.onTap,
    this.onDelete,
  });

  @override
  State<FavoriteListItem> createState() => _FavoriteListItemState();
}

class _FavoriteListItemState extends State<FavoriteListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final modeColor = _getModeColor(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Spacing.m),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.m),
                child: Row(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: widget.item.track.albumCoverUrl.isNotEmpty
                            ? Image.network(
                                widget.item.track.albumCoverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _albumPlaceholder(colorScheme),
                              )
                            : _albumPlaceholder(colorScheme),
                      ),
                    ),
                    const SizedBox(width: Spacing.m),

                    // Track info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.track.name,
                            style: textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            widget.item.track.artistName,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: Spacing.xs),
                          // Mode badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.s,
                                  vertical: Spacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: modeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getModeIcon(),
                                      size: 14,
                                      color: modeColor,
                                    ),
                                    const SizedBox(width: Spacing.xs),
                                    Text(
                                      widget.item.mode.displayName,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: modeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.item.section?.label != null) ...[
                                const SizedBox(width: Spacing.s),
                                Text(
                                  widget.item.section!.label!,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Delete button
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      onPressed: widget.onDelete,
                      tooltip: 'Remove from favorites',
                    ),
                  ],
                ),
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
      duration: AppDurations.medium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  Widget _albumPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Color _getModeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.item.mode) {
      case PlaybackMode.normal:
        return colorScheme.primary;
      case PlaybackMode.loop:
        return colorScheme.tertiary;
      case PlaybackMode.skip:
        return colorScheme.error.withOpacity(0.8);
    }
  }

  IconData _getModeIcon() {
    switch (widget.item.mode) {
      case PlaybackMode.normal:
        return Icons.play_circle_outline;
      case PlaybackMode.loop:
        return Icons.repeat_one;
      case PlaybackMode.skip:
        return Icons.skip_next;
    }
  }
}
