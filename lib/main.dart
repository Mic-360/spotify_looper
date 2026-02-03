/// Spotify Looper - A Material 3 Expressive Spotify client.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/app_config.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URLs instead of hash-based (required for OAuth callback)
  usePathUrlStrategy();

  // Initialize app configuration
  await AppConfig.initialize();

  runApp(const ProviderScope(child: SpotifyLooperApp()));
}

class SpotifyLooperApp extends ConsumerStatefulWidget {
  const SpotifyLooperApp({super.key});

  @override
  ConsumerState<SpotifyLooperApp> createState() => _SpotifyLooperAppState();
}

class _SpotifyLooperAppState extends ConsumerState<SpotifyLooperApp> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return DynamicThemeBuilder(
      builder: (lightTheme, darkTheme) {
        return MaterialApp.router(
          title: 'Spotify Looper',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
