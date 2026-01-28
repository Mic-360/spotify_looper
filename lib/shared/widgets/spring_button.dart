import 'package:flutter/material.dart';

import '../../core/constants/durations.dart';

/// Animated button with spring physics on press.
///
/// Features:
/// - Scale animation with overshoot (Curves.easeOutBack)
/// - Customizable animation parameters
/// - Reduced motion support
class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleOnPress;
  final Duration animationDuration;
  final bool enabled;

  const SpringButton({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleOnPress = 0.92,
    this.animationDuration = AppDurations.mediumFast,
    this.enabled = true,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

/// Icon button with spring animation
class SpringIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;
  final String? semanticLabel;

  const SpringIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = SpringButton(
      onPressed: onPressed,
      enabled: onPressed != null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.onSurface,
          size: size,
        ),
      ),
    );

    if (semanticLabel != null) {
      button = Semantics(label: semanticLabel, button: true, child: button);
    }

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

class _SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: widget.child,
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
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleOnPress)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOut,
            reverseCurve: Curves.easeOutBack, // Spring on release
          ),
        );
  }

  void _onTapCancel() {
    if (!_shouldReduceMotion(context)) {
      _controller.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled && !_shouldReduceMotion(context)) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled) {
      if (!_shouldReduceMotion(context)) {
        _controller.reverse();
      }
      widget.onPressed?.call();
    }
  }

  bool _shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}
