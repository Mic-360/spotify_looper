import 'package:flutter/material.dart';

import '../../core/constants/breakpoints.dart';

/// Responsive layout widget that adapts to screen size.
///
/// Provides different layouts for:
/// - Compact: < 600dp (phones)
/// - Medium: 600-840dp (tablets)
/// - Expanded: > 840dp (desktops)
class ResponsiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (Breakpoints.isExpanded(width) && expanded != null) {
          return expanded!;
        } else if (Breakpoints.isMedium(width) && medium != null) {
          return medium!;
        }
        return compact;
      },
    );
  }

  /// Check if current context is compact
  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.compact;
  }

  /// Check if current context is expanded
  static bool isExpanded(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.expanded;
  }

  /// Check if current context is medium
  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.compact && width < Breakpoints.expanded;
  }
}
