/// Login screen with Material 3 Expressive design and responsive layout.
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animations
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
          ),
        );

    // 2. Wave animation
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _entranceController.forward();

    // Check for auth code in URL on web (OAuth callback)
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleWebCallback();
      });
    }
  }

  void _handleWebCallback() {
    // Skip if already authenticated (callback screen may have handled it)
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) return;

    final baseUri = Uri.base;
    String? code;

    // Check fragment (hash part) for query parameters - common with GoRouter hash strategy
    final fragment = baseUri.fragment;
    if (fragment.contains('?')) {
      final fragmentUri = Uri.parse('http://x/$fragment');
      code = fragmentUri.queryParameters['code'];
    }

    // Fallback: check the base URI query parameters
    code ??= baseUri.queryParameters['code'];

    if (code != null && code.isNotEmpty) {
      ref.read(authProvider.notifier).handleCallback(code);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);

    // Redirect to home if authenticated
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go('/home');
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: colorScheme.error,
          ),
        );
        // Clear error after showing
        Future.microtask(() => ref.read(authProvider.notifier).clearError());
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Waves
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 240,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.6,
                  child: CustomPaint(
                    painter: _WavePainter(
                      animationValue: _waveController.value,
                      color: colorScheme.primary.withValues(
                        alpha: isDark ? 0.2 : 0.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Responsive Content
          SafeArea(
            child: ResponsiveLayout(
              compact: (context) => _buildCompactLayout(
                context,
                isDark,
                colorScheme,
                textTheme,
                authState,
              ),
              medium: (context) => _buildWideLayout(
                context,
                isDark,
                colorScheme,
                textTheme,
                authState,
              ),
              expanded: (context) => _buildWideLayout(
                context,
                isDark,
                colorScheme,
                textTheme,
                authState,
              ),
            ),
          ),

          // 3. Version Info (Fixed at bottom)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0 • Pulse Loop',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Layout (Single Column)
  Widget _buildCompactLayout(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AuthState authState,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(isDark, colorScheme),
                const SizedBox(height: 32),
                _buildHeader(textTheme, isDark),
                const SizedBox(height: 16),
                _buildTagline(textTheme, isDark),
                const SizedBox(height: 48),
                _buildSpotifyButton(colorScheme, authState),
                const SizedBox(height: 32),
                _buildFooterLinks(textTheme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Wide Layout (Double Column)
  Widget _buildWideLayout(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AuthState authState,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Row(
              children: [
                // Left Column: Branding & Illustration
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogo(isDark, colorScheme),
                        const SizedBox(height: 40),
                        _buildHeader(
                          textTheme,
                          isDark,
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 24),
                        _buildTagline(
                          textTheme,
                          isDark,
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 40),
                        _buildFeaturesList(textTheme, colorScheme),
                      ],
                    ),
                  ),
                ),

                // Right Column: Action Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Get Started',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sign in to synchronize your loops across devices.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildSpotifyButton(colorScheme, authState),
                            const SizedBox(height: 32),
                            _buildFooterLinks(textTheme, isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark, ColorScheme colorScheme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.primary.withValues(alpha: 0.15)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.library_music_rounded,
          size: 40,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildHeader(
    TextTheme textTheme,
    bool isDark, {
    TextAlign textAlign = TextAlign.center,
  }) {
    return Text(
      'Pulse Loop',
      textAlign: textAlign,
      style: textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
    );
  }

  Widget _buildTagline(
    TextTheme textTheme,
    bool isDark, {
    TextAlign textAlign = TextAlign.center,
  }) {
    return Text(
      'Your advanced playback utility for seamless audio experiences.',
      textAlign: textAlign,
      style: textTheme.bodyLarge?.copyWith(
        color: isDark ? Colors.white54 : Colors.black54,
        height: 1.5,
      ),
    );
  }

  Widget _buildFeaturesList(TextTheme textTheme, ColorScheme colorScheme) {
    final features = [
      (Icons.loop_rounded, 'Perfect A-B Looping'),
      (Icons.skip_next_rounded, 'Smart Segment Skipping'),
      (Icons.devices_rounded, 'Multi-Device Sync'),
    ];

    return Column(
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      f.$1,
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    f.$2,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSpotifyButton(ColorScheme colorScheme, AuthState authState) {
    final isLoading = authState.status == AuthStatus.loading;

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () => ref.read(authProvider.notifier).login(),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // M3E: Full rounding
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SpotifyIcon(),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Continue with Spotify',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooterLinks(TextTheme textTheme, bool isDark) {
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        children: [
          TextSpan(
            text: 'Terms',
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: textTheme.bodySmall?.copyWith(
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }
}

class _SpotifyIcon extends StatelessWidget {
  const _SpotifyIcon();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _SpotifyLogoPainter(color: colorScheme.onPrimary),
      ),
    );
  }
}

class _SpotifyLogoPainter extends CustomPainter {
  final Color color;
  _SpotifyLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Marks
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, 4),
        width: size.width * 0.7,
        height: size.height * 0.7,
      ),
      -2.4,
      1.6,
      false,
      paint,
    );
    paint.strokeWidth = 1.8;
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, 6),
        width: size.width * 0.55,
        height: size.height * 0.55,
      ),
      -2.4,
      1.6,
      false,
      paint,
    );
    paint.strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, 8),
        width: size.width * 0.4,
        height: size.height * 0.4,
      ),
      -2.4,
      1.6,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _WavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Wave 1
    path.moveTo(0, size.height * 0.5);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 +
            math.sin(
                  (i / size.width * 2 * math.pi) +
                      (animationValue * 2 * math.pi),
                ) *
                60,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Wave 2 (offset)
    final path2 = Path();
    paint.color = color.withValues(alpha: color.a * 0.5);
    path2.moveTo(0, size.height * 0.6);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.6 +
            math.sin(
                  (i / size.width * 2 * math.pi) -
                      (animationValue * 2 * math.pi) +
                      math.pi / 2,
                ) *
                40,
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
