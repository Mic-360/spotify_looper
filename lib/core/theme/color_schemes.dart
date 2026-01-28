import 'package:flutter/material.dart';

/// Color schemes for Spotify Looper following M3E guidelines.
///
/// Uses ColorScheme.fromSeed() with Spotify-inspired green.
///
/// Reference: M3E Guidelines - Color System section
class AppColorSchemes {
  /// Primary seed color (Spotify Green)
  static const Color _seedColor = Color(0xFF1DB954);

  /// Light color scheme generated from seed color
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  );

  /// Dark color scheme generated from seed color
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );

  /// Get dark scheme
  static ColorScheme get dark => darkColorScheme;

  /// Get light scheme
  static ColorScheme get light => lightColorScheme;

  AppColorSchemes._();

  // ══════════════════════════════════════════════════════════════════════════
  // Semantic Color Helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// Get color for Loop mode (cyan/teal)
  static Color loopModeColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  /// Get color for Normal mode (primary)
  static Color normalModeColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// Get color for Skip mode (orange/warning)
  static Color skipModeColor(BuildContext context) {
    return Theme.of(context).colorScheme.error.withValues(alpha: 0.8);
  }

  /// Get success color (for completed actions)
  static Color successColor(BuildContext context) {
    // Use tertiary container for success states
    return Theme.of(context).colorScheme.tertiaryContainer;
  }

  /// Get warning color
  static Color warningColor(BuildContext context) {
    // Orange-ish warning using error with lower opacity
    return Theme.of(context).colorScheme.errorContainer;
  }
}
