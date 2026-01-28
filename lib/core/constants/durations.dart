/// Animation durations following M3E motion guidelines.
///
/// Reference: M3E Guidelines - Motion & Animation section
class AppDurations {
  /// Micro interactions - 100ms (hover states, ripples)
  static const Duration micro = Duration(milliseconds: 100);

  /// Fast - 200ms (button presses, simple transitions)
  static const Duration fast = Duration(milliseconds: 200);

  /// Medium fast - 300ms (quick transitions)
  static const Duration mediumFast = Duration(milliseconds: 300);

  /// Medium - 600ms (shape morphs, expansions, hero animations)
  /// This is the recommended default for M3E spring animations
  static const Duration medium = Duration(milliseconds: 600);

  /// Slow - 800ms (page transitions)
  static const Duration slow = Duration(milliseconds: 800);

  /// Extra slow - 1000ms (complex choreography)
  static const Duration extraSlow = Duration(milliseconds: 1000);

  AppDurations._();
}
