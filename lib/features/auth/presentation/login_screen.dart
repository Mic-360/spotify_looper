import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated waves layer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(
                    animationValue: _waveController.value,
                    color: const Color(
                      0xFF1DB954,
                    ).withOpacity(isDark ? 0.15 : 0.25),
                  ),
                );
              },
            ),
          ),
          // 2. Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo box
                        _buildLogo(isDark, colorScheme),
                        const SizedBox(height: Spacing.xl),

                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isDark
                                ? [Colors.white, Colors.white.withOpacity(0.6)]
                                : [
                                    const Color(0xFF111827),
                                    const Color(0xFF4B5563),
                                  ],
                          ).createShader(bounds),
                          child: Text(
                            'Pulse Loop',
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacing.m),

                        // Tagline
                        Text(
                          'Your advanced playback utility for seamless audio experiences.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Login Button
                        _buildSpotifyButton(colorScheme),

                        const SizedBox(height: 48),

                        // Footer links
                        Text.rich(
                          TextSpan(
                            text: 'By continuing, you agree to our ',
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Version info & Home Indicator
          Positioned(
            bottom: Spacing.m,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'v1.0.0 • Made with 🐱 by bhaumic',
                  style: textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.white24 : Colors.black26,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 120,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Entrance animations
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

    // Wave animation
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _entranceController.forward();
  }

  Widget _buildLogo(bool isDark, ColorScheme colorScheme) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1DB954).withAlpha(50) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DB954).withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withAlpha(25),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.library_music_rounded,
            size: 48,
            color: Color(0xFF1DB954),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifyButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: const Color(0xFF1DB954).withAlpha(102),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _SpotifyIcon(),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Spotify',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    // Simulate Spotify OAuth
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      context.go('/');
    }
  }
}

class _SpotifyIcon extends StatelessWidget {
  const _SpotifyIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _SpotifyLogoPainter()),
    );
  }
}

class _SpotifyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    // Marks
    paint.color = const Color(0xFF1DB954);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Top arc
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
    // Mid arc
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
    // bottom arc
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
                80,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Wave 2 (offset)
    final path2 = Path();
    paint.color = color.withOpacity(color.opacity * 0.5);
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
