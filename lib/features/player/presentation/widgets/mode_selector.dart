import 'package:flutter/material.dart';

import '../../../../shared/models/playback_mode.dart';

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
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: 'NORMAL',
            isActive: currentMode == PlaybackMode.normal,
            activeColor: const Color(0xFF1DB954),
            onTap: () => onModeChanged(PlaybackMode.normal),
          ),
          _ModeTab(
            label: 'LOOP',
            isActive: currentMode == PlaybackMode.loop,
            activeColor: const Color(0xFF10B981),
            onTap: () => onModeChanged(PlaybackMode.loop),
          ),
          _ModeTab(
            label: 'SKIP',
            isActive: currentMode == PlaybackMode.skip,
            activeColor: const Color(0xFFEF4444),
            onTap: () => onModeChanged(PlaybackMode.skip),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
