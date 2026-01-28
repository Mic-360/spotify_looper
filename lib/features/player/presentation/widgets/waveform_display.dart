import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/models/playback_mode.dart';

class WaveformDisplay extends StatelessWidget {
  final Duration duration;
  final Duration position;
  final SectionMarker? section;
  final PlaybackMode mode;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration>? onSectionStartChanged;
  final ValueChanged<Duration>? onSectionEndChanged;

  const WaveformDisplay({
    super.key,
    required this.duration,
    required this.position,
    this.section,
    required this.mode,
    required this.onSeek,
    this.onSectionStartChanged,
    this.onSectionEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Time Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              __TimeLabel(duration: position),
              __TimeLabel(duration: duration, isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Interactive Waveform
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final x = details.localPosition.dx.clamp(
                      0.0,
                      constraints.maxWidth,
                    );
                    final percent = x / constraints.maxWidth;
                    onSeek(duration * percent);
                  },
                  onTapDown: (details) {
                    final x = details.localPosition.dx.clamp(
                      0.0,
                      constraints.maxWidth,
                    );
                    final percent = x / constraints.maxWidth;
                    onSeek(duration * percent);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Base Waveform (inactive)
                      CustomPaint(
                        size: Size(constraints.maxWidth, 120),
                        painter: _WaveformPainter(
                          color: Colors.white.withValues(alpha: 0.1),
                          progress: 1.0,
                          mode: PlaybackMode.normal,
                        ),
                      ),
                      // Active Progress Waveform
                      CustomPaint(
                        size: Size(constraints.maxWidth, 120),
                        painter: _WaveformPainter(
                          color: _getModeColor(mode),
                          progress:
                              position.inMilliseconds / duration.inMilliseconds,
                          mode: mode,
                        ),
                      ),
                      // Section markers (if applicable)
                      if (section != null) ...[
                        _buildSectionShade(constraints.maxWidth),
                        _buildHandle(
                          constraints.maxWidth,
                          section!.startTime,
                          'T1',
                          onSectionStartChanged,
                        ),
                        _buildHandle(
                          constraints.maxWidth,
                          section!.endTime,
                          'T2',
                          onSectionEndChanged,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHandle(
    double width,
    Duration time,
    String label,
    ValueChanged<Duration>? onChanged,
  ) {
    if (duration.inMilliseconds == 0) return const SizedBox.shrink();
    final pos = (time.inMilliseconds / duration.inMilliseconds) * width;

    return Positioned(
      left: pos - 15,
      top: -10,
      bottom: -10,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (onChanged == null) return;
          final x = (pos + details.delta.dx).clamp(0.0, width);
          onChanged(duration * (x / width));
        },
        child: Container(
          width: 30,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HandleIndicator(label: label, color: _getModeColor(mode)),
              Container(
                width: 2,
                height: 80,
                decoration: BoxDecoration(
                  color: _getModeColor(mode),
                  boxShadow: [
                    BoxShadow(
                      color: _getModeColor(mode).withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionShade(double width) {
    if (duration.inMilliseconds == 0) return const SizedBox.shrink();
    final start =
        (section!.startTime.inMilliseconds / duration.inMilliseconds) * width;
    final end =
        (section!.endTime.inMilliseconds / duration.inMilliseconds) * width;

    return Positioned(
      left: start,
      width: (end - start).clamp(0, width),
      top: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: _getModeColor(mode).withValues(alpha: 0.1),
          border: Border.symmetric(
            vertical: BorderSide(
              color: _getModeColor(mode).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Color _getModeColor(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.normal:
        return const Color(0xFF1DB954);
      case PlaybackMode.loop:
        return const Color(0xFF10B981);
      case PlaybackMode.skip:
        return const Color(0xFFEF4444);
    }
  }
}

class __TimeLabel extends StatelessWidget {
  final Duration duration;
  final bool isTotal;

  const __TimeLabel({required this.duration, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return Text(
      "$minutes:$seconds",
      style: TextStyle(
        color: isTotal ? Colors.grey : Colors.white,
        fontSize: 12,
        fontWeight: isTotal ? FontWeight.normal : FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }
}

class _HandleIndicator extends StatelessWidget {
  final String label;
  final Color color;

  const _HandleIndicator({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  final double progress;
  final PlaybackMode mode;

  _WaveformPainter({
    required this.color,
    required this.progress,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barCount = 60;
    final spacing = size.width / barCount;
    final random = math.Random(42); // Seed for consistent waveform

    for (int i = 0; i < barCount; i++) {
      final x = i * spacing + spacing / 2;
      if (x / size.width > progress) continue;

      // Generate a "pseudo-random" height that looks like music
      final noise = random.nextDouble();
      final height = 20 + noise * 60 * (1 + math.sin(i * 0.2) * 0.5);

      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}
