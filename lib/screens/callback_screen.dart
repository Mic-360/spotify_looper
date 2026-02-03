/// OAuth callback screen for handling redirect on web.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/spotify_auth_service.dart';
import '../services/spotify_api_service.dart';

class CallbackScreen extends ConsumerStatefulWidget {
  const CallbackScreen({super.key});

  @override
  ConsumerState<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends ConsumerState<CallbackScreen> {
  String? _error;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    try {
      // Get the code from the GoRouter state
      final goRouterState = GoRouterState.of(context);
      final code = goRouterState.uri.queryParameters['code'];
      final error = goRouterState.uri.queryParameters['error'];

      if (error != null) {
        setState(() {
          _error = 'Authentication failed: $error';
          _isProcessing = false;
        });
        return;
      }

      if (code == null) {
        setState(() {
          _error = 'No authorization code received';
          _isProcessing = false;
        });
        return;
      }

      // Exchange code for tokens
      final result = await SpotifyAuthService.exchangeCodeFromCallback(code);

      if (result.isSuccess) {
        // Fetch user profile
        try {
          final api = SpotifyApiService(result.accessToken!);
          final user = await api.getCurrentUser();

          // Update auth state
          ref
              .read(authProvider.notifier)
              .setAuthenticated(
                accessToken: result.accessToken!,
                refreshToken: result.refreshToken,
                expiresAt: result.expiresAt!,
                user: user,
              );

          // Navigate to home
          if (mounted) {
            context.go('/home');
          }
        } catch (e) {
          setState(() {
            _error = 'Failed to fetch user profile: $e';
            _isProcessing = false;
          });
        }
      } else {
        setState(() {
          _error = result.errorMessage ?? 'Authentication failed';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Callback error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 24),
              Text(
                'Connecting to Spotify...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we complete the authentication',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (_error != null) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Authentication Failed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
