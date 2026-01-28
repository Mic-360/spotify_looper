import 'package:flutter/material.dart';

/// Loading indicator following M3E guidelines.
///
/// Supports both circular and linear variants with
/// optional pulsing animation.
class LoadingIndicator extends StatefulWidget {
  final bool isLinear;
  final double? value;
  final Color? color;
  final double size;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.isLinear = false,
    this.value,
    this.color,
    this.size = 48,
    this.strokeWidth = 4,
  });

  const LoadingIndicator.circular({
    super.key,
    this.value,
    this.color,
    this.size = 48,
    this.strokeWidth = 4,
  }) : isLinear = false;

  const LoadingIndicator.linear({
    super.key,
    this.value,
    this.color,
    this.size = 4,
    this.strokeWidth = 4,
  }) : isLinear = true;

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingIndicator.circular(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indicatorColor = widget.color ?? colorScheme.primary;

    if (widget.isLinear) {
      return SizedBox(
        height: widget.size,
        child: widget.value != null
            ? LinearProgressIndicator(
                value: widget.value,
                color: indicatorColor,
                backgroundColor: colorScheme.surfaceContainerHighest,
              )
            : LinearProgressIndicator(
                color: indicatorColor,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
      );
    }

    return ScaleTransition(
      scale: _pulseAnimation,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: widget.value != null
            ? CircularProgressIndicator(
                value: widget.value,
                strokeWidth: widget.strokeWidth,
                color: indicatorColor,
                backgroundColor: colorScheme.surfaceContainerHighest,
              )
            : CircularProgressIndicator(
                strokeWidth: widget.strokeWidth,
                color: indicatorColor,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
}
