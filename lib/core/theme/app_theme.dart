import 'package:flutter/material.dart';

import 'component_themes.dart';
import 'text_theme.dart';

/// Material 3 Expressive theme configuration for Spotify Looper.
///
/// Uses Spotify-inspired green as the seed color with dynamic color support.
///
/// Reference: M3E Guidelines - Color System & Implementation Guide
class AppTheme {
  /// Spotify-inspired seed color (Spotify Green)
  static const Color seedColor = Color(0xFF1DB954);

  /// Alternative seed colors for theme customization
  static const Color secondarySeed = Color(0xFF191414); // Spotify Black

  static const Color accentSeed = Color(0xFF1ED760); // Spotify Bright Green
  AppTheme._();

  // ══════════════════════════════════════════════════════════════════════════
  // Light Theme
  // ══════════════════════════════════════════════════════════════════════════

  /// Create dark theme with optional dynamic color scheme
  static ThemeData dark(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: AppTextTheme.textTheme,

      // Component themes
      filledButtonTheme: ComponentThemes.filledButtonTheme(colorScheme),
      elevatedButtonTheme: ComponentThemes.elevatedButtonTheme(colorScheme),
      outlinedButtonTheme: ComponentThemes.outlinedButtonTheme(colorScheme),
      textButtonTheme: ComponentThemes.textButtonTheme(colorScheme),
      iconButtonTheme: ComponentThemes.iconButtonTheme(colorScheme),
      cardTheme: ComponentThemes.cardTheme(colorScheme),
      navigationBarTheme: ComponentThemes.navigationBarTheme(colorScheme),
      navigationRailTheme: ComponentThemes.navigationRailTheme(colorScheme),
      chipTheme: ComponentThemes.chipTheme(colorScheme),
      inputDecorationTheme: ComponentThemes.inputDecorationTheme(colorScheme),
      appBarTheme: ComponentThemes.appBarTheme(colorScheme),
      floatingActionButtonTheme: ComponentThemes.fabTheme(colorScheme),
      dialogTheme: ComponentThemes.dialogTheme(colorScheme),
      bottomSheetTheme: ComponentThemes.bottomSheetTheme(colorScheme),
      sliderTheme: ComponentThemes.sliderTheme(colorScheme),

      // Visual density for better touch targets
      visualDensity: VisualDensity.standard,

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Dark Theme
  // ══════════════════════════════════════════════════════════════════════════

  /// Create light theme with optional dynamic color scheme
  static ThemeData light(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: AppTextTheme.textTheme,

      // Component themes
      filledButtonTheme: ComponentThemes.filledButtonTheme(colorScheme),
      elevatedButtonTheme: ComponentThemes.elevatedButtonTheme(colorScheme),
      outlinedButtonTheme: ComponentThemes.outlinedButtonTheme(colorScheme),
      textButtonTheme: ComponentThemes.textButtonTheme(colorScheme),
      iconButtonTheme: ComponentThemes.iconButtonTheme(colorScheme),
      cardTheme: ComponentThemes.cardTheme(colorScheme),
      navigationBarTheme: ComponentThemes.navigationBarTheme(colorScheme),
      navigationRailTheme: ComponentThemes.navigationRailTheme(colorScheme),
      chipTheme: ComponentThemes.chipTheme(colorScheme),
      inputDecorationTheme: ComponentThemes.inputDecorationTheme(colorScheme),
      appBarTheme: ComponentThemes.appBarTheme(colorScheme),
      floatingActionButtonTheme: ComponentThemes.fabTheme(colorScheme),
      dialogTheme: ComponentThemes.dialogTheme(colorScheme),
      bottomSheetTheme: ComponentThemes.bottomSheetTheme(colorScheme),
      sliderTheme: ComponentThemes.sliderTheme(colorScheme),

      // Visual density for better touch targets
      visualDensity: VisualDensity.standard,

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
