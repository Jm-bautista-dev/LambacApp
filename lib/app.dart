import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/flavor_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root Widget for Lambac Coffee Roastery Mobile Application
class LambacApp extends ConsumerWidget {
  const LambacApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appConfig = ref.watch(appConfigProvider);

    return MaterialApp.router(
      title: appConfig.appName,
      debugShowCheckedModeBanner: false,

      // Routing Configuration
      routerConfig: router,

      // Theme Configuration (Apple + Japanese Minimalist Roastery)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Global Builder for Dismissing Keyboard on Tap Outside & Safe Bounds
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Dismiss active keyboard when tapping outside input fields
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
