import 'package:flutter/material.dart';

import '../../../../core/constants/spacing.dart';
import '../../../../shared/models/playback_mode.dart';

/// Waveform/progress display with section visualization.
class WaveformDisplay extends StatelessWidget {
  final Duration duration;
  final Duration position;
  final SectionMarker? section;
  final PlaybackMode mode;
  final ValueChanged<Duration> onSeek;

  const WaveformDisplay({
    super.key,
    required this.duration,
    required this.position,
    this.section,
    this.mode = PlaybackMode.normal,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Waveform/Progress bar
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              final width = box.size.width;
              final position = details.localPosition.dx.clamp(0, width);
              final percent = position / width;
              final seekPosition = Duration(
                milliseconds: (duration.inMilliseconds * percent).round(),
              );
              onSeek(seekPosition);
            }
          },
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              final width = box.size.width;
              final position = details.localPosition.dx.clamp(0, width);
              final percent = position / width;
              final seekPosition = Duration(
                milliseconds: (duration.inMilliseconds * percent).round(),
              );
              onSeek(seekPosition);
            }
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                size: const Size(double.infinity, 48),
                painter: _WaveformPainter(
                  progress: duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0,
                  progressColor: colorScheme.primary,
                  waveformColor: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  section: section,
                  totalDuration: duration,
                  sectionColor: _getSectionColor(context),
                  mode: mode,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.s),

        // Time labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(position),
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (section != null && mode != PlaybackMode.normal) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.s,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getSectionColor(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  mode == PlaybackMode.loop
                      ? 'Loop: ${_formatDuration(section!.startTime)} - ${_formatDuration(section!.endTime)}'
                      : 'Skip: ${_formatDuration(section!.startTime)} - ${_formatDuration(section!.endTime)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: _getSectionColor(context),
                  ),
                ),
              ),
            ],
            Text(
              _formatDuration(duration),
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getSectionColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (mode) {
      case PlaybackMode.normal:
        return colorScheme.primary;
      case PlaybackMode.loop:
        return colorScheme.tertiary;
      case PlaybackMode.skip:
        return colorScheme.error.withOpacity(0.8);
    }
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color waveformColor;
  final SectionMarker? section;
  final Duration totalDuration;
  final Color sectionColor;
  final PlaybackMode mode;

  _WaveformPainter({
    required this.progress,
    required this.progressColor,
    required this.waveformColor,
    this.section,
    required this.totalDuration,
    required this.sectionColor,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waveformPaint = Paint()
      ..color = waveformColor
      ..style = PaintingStyle.fill;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.fill;

    // Draw section highlight if in loop/skip mode
    if (section != null &&
        mode != PlaybackMode.normal &&
        totalDuration.inMilliseconds > 0) {
      final sectionPaint = Paint()
        ..color = sectionColor.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final startX =
          (section!.startTime.inMilliseconds / totalDuration.inMilliseconds) *
          size.width;
      final endX =
          (section!.endTime.inMilliseconds / totalDuration.inMilliseconds) *
          size.width;

      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        sectionPaint,
      );

      // Draw section borders
      final borderPaint = Paint()
        ..color = sectionColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX, size.height),
        borderPaint,
      );
      canvas.drawLine(Offset(endX, 0), Offset(endX, size.height), borderPaint);
    }

    // Draw waveform bars
    final barCount = 50;
    final barWidth = size.width / barCount;
    final progressWidth = size.width * progress;

    for (int i = 0; i < barCount; i++) {
      // Generate pseudo-random heights based on position
      final seed = (i * 17 + 7) % 13;
      final heightPercent = 0.2 + (seed / 13) * 0.6;
      final barHeight = size.height * heightPercent;
      final x = i * barWidth;
      final y = (size.height - barHeight) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, y, barWidth - 2, barHeight),
        const Radius.circular(2),
      );

      // Use progress color for bars before current position
      if (x < progressWidth) {
        canvas.drawRRect(rect, progressPaint);
      } else {
        canvas.drawRRect(rect, waveformPaint);
      }
    }

    // Draw progress indicator
    if (progress > 0 && progress < 1) {
      final indicatorPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(progressWidth, size.height / 2),
        6,
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        section != oldDelegate.section ||
        mode != oldDelegate.mode;
  }
}
