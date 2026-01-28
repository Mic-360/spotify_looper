import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/spacing.dart';

/// Spotify login screen with M3E design.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.onSecondaryContainer),
        ),
        const SizedBox(width: Spacing.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo/icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.music_note,
                          size: 64,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: Spacing.xxl),

                      // App name
                      Text(
                        'Spotify Looper',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Spacing.m),

                      // Tagline
                      Text(
                        'Loop & skip sections of your favorite songs',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Spacing.xxxl),

                      // Feature highlights
                      _FeatureItem(
                        icon: Icons.repeat_one,
                        title: 'Loop Mode',
                        description: 'Repeat your favorite sections',
                      ),
                      const SizedBox(height: Spacing.l),
                      _FeatureItem(
                        icon: Icons.skip_next,
                        title: 'Skip Mode',
                        description: 'Skip intros, outros, or any part',
                      ),
                      const SizedBox(height: Spacing.l),
                      _FeatureItem(
                        icon: Icons.favorite,
                        title: 'Save Favorites',
                        description: 'Keep your custom configurations',
                      ),
                      const SizedBox(height: Spacing.xxxl),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _handleLogin,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            _isLoading ? 'Connecting...' : 'Login with Spotify',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF1DB954,
                            ), // Spotify green
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.l,
                              horizontal: Spacing.xl,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.l),

                      // Terms
                      Text(
                        'By logging in, you agree to our Terms of Service\nand Privacy Policy',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    // TODO: Implement actual Spotify OAuth login
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      context.go('/');
    }
  }
}
