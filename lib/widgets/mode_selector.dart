import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';

class ModeSelector extends ConsumerWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              mode: PlayerMode.normal,
              icon: Icons.play_arrow_rounded,
              label: 'Normal',
              isSelected: playerState.mode == PlayerMode.normal,
              activeColor: colorScheme.primary,
            ),
          ),
          Expanded(
            child: _ModeButton(
              mode: PlayerMode.loop,
              icon: Icons.loop_rounded,
              label: 'Loop',
              isSelected: playerState.mode == PlayerMode.loop,
              activeColor: colorScheme.tertiary,
            ),
          ),
          Expanded(
            child: _ModeButton(
              mode: PlayerMode.skip,
              icon: Icons.skip_next_rounded,
              label: 'Skip',
              isSelected: playerState.mode == PlayerMode.skip,
              activeColor: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends ConsumerStatefulWidget {
  final PlayerMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;

  const _ModeButton({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
  });

  @override
  ConsumerState<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends ConsumerState<_ModeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
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
        ref.read(playerProvider.notifier).setMode(widget.mode);
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.elasticOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.activeColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: widget.isSelected
                ? Border.all(
                    color: widget.activeColor.withValues(alpha: 0.4),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  widget.icon,
                  key: ValueKey('${widget.mode}_${widget.isSelected}'),
                  size: 18,
                  color: widget.isSelected
                      ? widget.activeColor
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: widget.isSelected
                      ? widget.activeColor
                      : colorScheme.onSurfaceVariant,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
