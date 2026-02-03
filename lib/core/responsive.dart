/// Responsive breakpoints and utilities for adaptive layouts.
library;

import 'package:flutter/material.dart';

/// Screen size breakpoints following M3 guidelines
enum ScreenSize { compact, medium, expanded }

/// Responsive breakpoint values
class Breakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

/// Extension on BuildContext for responsive utilities
extension ResponsiveExtension on BuildContext {
  /// Get the current screen size category
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < Breakpoints.compact) {
      return ScreenSize.compact;
    } else if (width < Breakpoints.expanded) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.expanded;
    }
  }

  /// Check if the screen is compact (phone)
  bool get isCompact => screenSize == ScreenSize.compact;

  /// Check if the screen is medium (tablet)
  bool get isMedium => screenSize == ScreenSize.medium;

  /// Check if the screen is expanded (desktop)
  bool get isExpanded => screenSize == ScreenSize.expanded;

  /// Get responsive padding based on screen size
  EdgeInsets get responsivePadding {
    switch (screenSize) {
      case ScreenSize.compact:
        return const EdgeInsets.all(16);
      case ScreenSize.medium:
        return const EdgeInsets.all(24);
      case ScreenSize.expanded:
        return const EdgeInsets.all(32);
    }
  }

  /// Get responsive horizontal padding
  double get horizontalPadding {
    switch (screenSize) {
      case ScreenSize.compact:
        return 16;
      case ScreenSize.medium:
        return 24;
      case ScreenSize.expanded:
        return 48;
    }
  }

  /// Check if animations should be reduced
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;
}

/// Responsive layout widget that builds different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? expanded;

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
        if (constraints.maxWidth >= Breakpoints.expanded && expanded != null) {
          return expanded!(context);
        } else if (constraints.maxWidth >= Breakpoints.compact &&
            medium != null) {
          return medium!(context);
        }
        return compact(context);
      },
    );
  }
}

/// Responsive grid layout
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = switch (context.screenSize) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 3,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1.5,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
