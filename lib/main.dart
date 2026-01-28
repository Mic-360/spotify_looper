import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/color_schemes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SpotifyLooperApp()));
}

/// Root application widget with Material 3 Expressive theming.
class SpotifyLooperApp extends ConsumerWidget {
  const SpotifyLooperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Use device's dynamic color if available, otherwise fallback to Spotify green
        final lightColorScheme = lightDynamic ?? AppColorSchemes.light;
        final darkColorScheme = darkDynamic ?? AppColorSchemes.dark;

        return MaterialApp.router(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,

          // M3E Theme configuration
          theme: AppTheme.light(lightColorScheme),
          darkTheme: AppTheme.dark(darkColorScheme),
          themeMode: ThemeMode.system,

          // Go Router configuration
          routerConfig: router,
        );
      },
    );
  }
}
