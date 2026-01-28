import 'package:flutter/material.dart';

/// Expressive card with spring animation on tap.
///
/// Features:
/// - Scale animation with Curves.easeOutBack
/// - Customizable elevation and shape
/// - Accessibility support with semantic labels
/// - Reduced motion support
class ExpressiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String? semanticLabel;

  const ExpressiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.elevation,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.semanticLabel,
  });

  @override
  State<ExpressiveCard> createState() => _ExpressiveCardState();
}

class _ExpressiveCardState extends State<ExpressiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget card = Card(
      elevation: widget.elevation ?? 0,
      color: widget.color ?? colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      margin: widget.margin ?? EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        child: widget.padding != null
            ? Padding(padding: widget.padding!, child: widget.child)
            : widget.child,
      ),
    );

    if (widget.onTap != null && !_shouldReduceMotion(context)) {
      card = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(scale: _scaleAnimation, child: card),
      );
    }

    if (widget.semanticLabel != null) {
      card = Semantics(
        label: widget.semanticLabel,
        button: widget.onTap != null,
        child: card,
      );
    }

    return card;
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
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _onTapCancel() {
    if (!_shouldReduceMotion(context)) {
      _controller.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!_shouldReduceMotion(context)) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!_shouldReduceMotion(context)) {
      _controller.reverse();
    }
    widget.onTap?.call();
  }

  bool _shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}
