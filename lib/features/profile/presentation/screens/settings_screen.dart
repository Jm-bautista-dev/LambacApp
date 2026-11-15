import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/flavor_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';

/// App Settings & Preferences Screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final appConfig = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: const LambacAppBar(
        title: 'Settings',
        subtitle: 'Appearance, notifications & info',
        fallbackRoute: AppRoutes.profile,
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.warmDiscovery,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: ResponsiveLayout.maxReadingWidth,
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
            // Appearance Section
            _buildSectionHeader('Appearance', isDark),
            AppSpacing.vSpaceSm,
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    title: const Text('System Default', style: TextStyle(fontSize: 14)),
                    activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      }
                    },
                  ),
                  _buildDivider(isDark),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    title: const Text('Light (Warm Linen)', style: TextStyle(fontSize: 14)),
                    activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      }
                    },
                  ),
                  _buildDivider(isDark),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    title: const Text('Dark (Tokyo Night Cafe)', style: TextStyle(fontSize: 14)),
                    activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      }
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.vSpaceXxl,

            // Environment & Developer Information
            _buildSectionHeader('Environment & Build Info', isDark),
            AppSpacing.vSpaceSm,
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('App Name', appConfig.appName, isDark),
                  _buildDivider(isDark),
                  _buildInfoRow('Environment', appConfig.environment.name.toUpperCase(), isDark),
                  _buildDivider(isDark),
                  _buildInfoRow('API Base URL', appConfig.apiBaseUrl, isDark),
                  _buildDivider(isDark),
                  _buildInfoRow('API Version', appConfig.apiVersion, isDark),
                ],
              ),
            ),
            AppSpacing.vSpaceXxl,

            // Help & Interactive Guide
            _buildSectionHeader('Help & Walkthrough', isDark),
            AppSpacing.vSpaceSm,
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.help_outline_rounded,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      size: 20,
                    ),
                    title: const Text('Customer Interactive Tutorial', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Replay full 20-step roastery feature walkthrough', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () => context.push(AppRoutes.helpGuide),
                  ),
                ],
              ),
            ),
            AppSpacing.vSpaceXxl,

            // Legal & About
            _buildSectionHeader('About', isDark),
            AppSpacing.vSpaceSm,
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Terms of Service', style: TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () => context.push('${AppRoutes.termsAndConditions}?mode=review'),
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    title: const Text('Privacy Policy', style: TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () => context.push('${AppRoutes.termsAndConditions}?mode=review'),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
    );
  }
}
