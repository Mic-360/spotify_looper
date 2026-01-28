import 'package:flutter/material.dart';

import '../../../../core/constants/durations.dart';
import '../../../../core/constants/spacing.dart';

/// Section selector for defining loop/skip regions.
class SectionSelector extends StatefulWidget {
  final Duration totalDuration;
  final Duration? sectionStart;
  final Duration? sectionEnd;
  final ValueChanged<Duration> onStartChanged;
  final ValueChanged<Duration> onEndChanged;

  const SectionSelector({
    super.key,
    required this.totalDuration,
    this.sectionStart,
    this.sectionEnd,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  State<SectionSelector> createState() => _SectionSelectorState();
}

class _Handle extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;

  const _Handle({
    required this.label,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? color : color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_indicator,
              size: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionSelectorState extends State<SectionSelector> {
  late double _startValue;
  late double _endValue;
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Section', style: textTheme.titleMedium),
        const SizedBox(height: Spacing.m),

        // Range selector
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.m),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Selected range highlight
                  Positioned(
                    left: constraints.maxWidth * _startValue,
                    width: constraints.maxWidth * (_endValue - _startValue),
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Start handle
                  Positioned(
                    left: constraints.maxWidth * _startValue - 12,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        setState(() => _isDraggingStart = true);
                      },
                      onHorizontalDragUpdate: (details) {
                        final newPos =
                            (details.localPosition.dx +
                                constraints.maxWidth * _startValue) /
                            constraints.maxWidth;
                        _onStartChanged(newPos.clamp(0, 1));
                      },
                      onHorizontalDragEnd: (_) {
                        setState(() => _isDraggingStart = false);
                      },
                      child: AnimatedScale(
                        scale: _isDraggingStart ? 1.2 : 1.0,
                        duration: AppDurations.fast,
                        curve: Curves.easeOutBack,
                        child: _Handle(
                          label: 'Start',
                          color: colorScheme.tertiary,
                          isActive: _isDraggingStart,
                        ),
                      ),
                    ),
                  ),

                  // End handle
                  Positioned(
                    left: constraints.maxWidth * _endValue - 12,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        setState(() => _isDraggingEnd = true);
                      },
                      onHorizontalDragUpdate: (details) {
                        final newPos =
                            (details.localPosition.dx +
                                constraints.maxWidth * _endValue) /
                            constraints.maxWidth;
                        _onEndChanged(newPos.clamp(0, 1));
                      },
                      onHorizontalDragEnd: (_) {
                        setState(() => _isDraggingEnd = false);
                      },
                      child: AnimatedScale(
                        scale: _isDraggingEnd ? 1.2 : 1.0,
                        duration: AppDurations.fast,
                        curve: Curves.easeOutBack,
                        child: _Handle(
                          label: 'End',
                          color: colorScheme.tertiary,
                          isActive: _isDraggingEnd,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: Spacing.s),

        // Time labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Start: ${_formatDuration(widget.sectionStart ?? Duration.zero)}',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.tertiary,
              ),
            ),
            Text(
              'Duration: ${_formatDuration((widget.sectionEnd ?? widget.totalDuration) - (widget.sectionStart ?? Duration.zero))}',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'End: ${_formatDuration(widget.sectionEnd ?? widget.totalDuration)}',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant SectionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionStart != widget.sectionStart ||
        oldWidget.sectionEnd != widget.sectionEnd) {
      _updateValues();
    }
  }

  @override
  void initState() {
    super.initState();
    _updateValues();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _onEndChanged(double value) {
    if (value > _startValue + 0.05) {
      setState(() => _endValue = value);
      final newDuration = Duration(
        milliseconds: (widget.totalDuration.inMilliseconds * value).round(),
      );
      widget.onEndChanged(newDuration);
    }
  }

  void _onStartChanged(double value) {
    if (value < _endValue - 0.05) {
      setState(() => _startValue = value);
      final newDuration = Duration(
        milliseconds: (widget.totalDuration.inMilliseconds * value).round(),
      );
      widget.onStartChanged(newDuration);
    }
  }

  void _updateValues() {
    final totalMs = widget.totalDuration.inMilliseconds.toDouble();
    if (totalMs > 0) {
      _startValue = (widget.sectionStart?.inMilliseconds ?? 0) / totalMs;
      _endValue =
          (widget.sectionEnd?.inMilliseconds ?? totalMs.toInt()) / totalMs;
    } else {
      _startValue = 0;
      _endValue = 1;
    }
  }
}
