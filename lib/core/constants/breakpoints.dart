/// Responsive breakpoints for adaptive layouts.
///
/// Reference: M3E Guidelines - Spacing & Layout section
class Breakpoints {
  /// Compact: phones in portrait (< 600dp)
  static const double compact = 600;

  /// Medium: tablets, foldables, phones in landscape (600-840dp)
  static const double medium = 840;

  /// Expanded: larger tablets, desktops (> 840dp)
  static const double expanded = 1200;

  Breakpoints._();

  /// Get the number of grid columns based on width
  static int getGridColumns(double width) {
    if (width >= expanded) return 4;
    if (width >= medium) return 3;
    if (width >= compact) return 2;
    return 1;
  }

  /// Check if width is compact
  static bool isCompact(double width) => width < compact;

  /// Check if width is expanded
  static bool isExpanded(double width) => width >= expanded;

  /// Check if width is medium
  static bool isMedium(double width) => width >= compact && width < expanded;
}
