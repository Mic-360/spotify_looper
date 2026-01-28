import 'package:flutter/material.dart';

/// Material 3 Expressive typography scale.
///
/// Reference: M3E Guidelines - Typography section
class AppTextTheme {
  /// Complete M3E text theme with all 15 roles
  static const TextTheme textTheme = TextTheme(
    // ════════════════════════════════════════════════════════════════════════
    // Display - Large, high-impact text (hero moments)
    // ════════════════════════════════════════════════════════════════════════
    displayLarge: TextStyle(
      fontSize: 57,
      height: 64 / 57,
      letterSpacing: -0.25,
      fontWeight: FontWeight.w400,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      height: 52 / 45,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      height: 44 / 36,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // Headline - Section headers and emphasis
    // ════════════════════════════════════════════════════════════════════════
    headlineLarge: TextStyle(
      fontSize: 32,
      height: 40 / 32,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 36 / 28,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 32 / 24,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // Title - Component headers and key labels
    // ════════════════════════════════════════════════════════════════════════
    titleLarge: TextStyle(
      fontSize: 22,
      height: 28 / 22,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0.15,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w500,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // Body - Primary content text
    // ════════════════════════════════════════════════════════════════════════
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.25,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0.4,
      fontWeight: FontWeight.w400,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // Label - Buttons, tabs, and metadata
    // ════════════════════════════════════════════════════════════════════════
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 16 / 11,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w500,
    ),
  );

  AppTextTheme._();
}
