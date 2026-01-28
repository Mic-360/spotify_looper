import 'package:flutter/material.dart';

import '../../../../core/constants/durations.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/models/playback_mode.dart';

/// Playback mode selector widget.
///
/// Allows switching between Normal, Loop, and Skip modes
/// with animated chip selection.
class ModeSelector extends StatelessWidget {
  final PlaybackMode currentMode;
  final ValueChanged<PlaybackMode> onModeChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Playback Mode', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Spacing.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ModeChip(
              mode: PlaybackMode.normal,
              icon: Icons.play_circle_outline,
              isSelected: currentMode == PlaybackMode.normal,
              onTap: () => onModeChanged(PlaybackMode.normal),
            ),
            const SizedBox(width: Spacing.s),
            _ModeChip(
              mode: PlaybackMode.loop,
              icon: Icons.repeat_one,
              isSelected: currentMode == PlaybackMode.loop,
              onTap: () => onModeChanged(PlaybackMode.loop),
            ),
            const SizedBox(width: Spacing.s),
            _ModeChip(
              mode: PlaybackMode.skip,
              icon: Icons.skip_next,
              isSelected: currentMode == PlaybackMode.skip,
              onTap: () => onModeChanged(PlaybackMode.skip),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeChip extends StatefulWidget {
  final PlaybackMode mode;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.mode,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ModeChip> createState() => _ModeChipState();
}

class _ModeChipState extends State<_ModeChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final modeColor = _getModeColor(context);

    return Semantics(
      label: '${widget.mode.displayName} mode: ${widget.mode.description}',
      selected: widget.isSelected,
      button: true,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppDurations.mediumFast,
          curve: Curves.easeOutBack,
          child: FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.xs),
                Text(widget.mode.displayName),
              ],
            ),
            selected: widget.isSelected,
            onSelected: (selected) => widget.onTap(),
            backgroundColor: colorScheme.surfaceContainerHighest,
            selectedColor: widget.isSelected
                ? modeColor.withValues(alpha: 0.2)
                : null,
            checkmarkColor: modeColor,
            side: widget.isSelected
                ? BorderSide(color: modeColor, width: 2)
                : null,
            labelStyle: TextStyle(
              color: widget.isSelected
                  ? modeColor
                  : colorScheme.onSurfaceVariant,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _ModeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward().then((_) => _controller.reverse());
    }
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
      duration: AppDurations.mediumFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  Color _getModeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.mode) {
      case PlaybackMode.normal:
        return colorScheme.primary;
      case PlaybackMode.loop:
        return colorScheme.tertiary;
      case PlaybackMode.skip:
        return colorScheme.error.withValues(alpha: 0.8);
    }
  }
}
