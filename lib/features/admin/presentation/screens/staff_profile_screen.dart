import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/dialogs/app_dialog.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/presentation/spotlight/barista_spotlight_provider.dart';

/// Production Staff / Barista Shift Profile & Station Control Screen
class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: const LambacAppBar(
        showBackButton: false,
        title: 'Barista Station & Shift',
        subtitle: 'Session Road Flagship Store',
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.subtleOperations,
        child: SafeArea(
          child: ResponsiveContentContainer(
          maxWidth: 680,
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Barista Identity Card
              AppCard.elevated(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.matchaSage.withOpacity(0.2) : AppColors.matchaSageLight.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.matchaSage.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.matchaSage,
                        ),
                      ),
                    ),
                    AppSpacing.hSpaceLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.fullName ?? 'Barista Staff',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.matchaSage.withOpacity(0.18),
                                  borderRadius: AppRadius.radiusPill,
                                ),
                                child: const Text(
                                  'STAFF / BARISTA',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.matchaSage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? 'barista.staff@lambac.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Shift Active • Station Ready',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              // Assigned Operational Permissions
              Text(
                'Assigned Operational Roles',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              AppSpacing.vSpaceSm,
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPermBadge('Process Pickup Orders', Icons.check_circle_rounded),
                        _buildPermBadge('Walk-In Sales POS', Icons.check_circle_rounded),
                        _buildPermBadge('Customer Concierge Support', Icons.check_circle_rounded),
                        _buildPermBadge('View Basic Station Metrics', Icons.check_circle_rounded),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Administrative functions, bean catalog pricing, and predictive analytics are restricted to System Administrators.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              // Shift Preferences & System Info
              Text(
                'Shift Preferences',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              AppSpacing.vSpaceSm,
              AppCard(
                key: SpotlightKeys.staffShiftControls,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette_outlined, color: AppColors.matchaSage),
                      title: const Text('Theme Appearance'),
                      subtitle: Text('Current mode: ${themeMode.name.toUpperCase()}'),
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        activeColor: AppColors.matchaSage,
                        onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                      ),
                      onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.point_of_sale_rounded, color: AppColors.brandAmber),
                      title: const Text('Point of Sale (POS Register)'),
                      subtitle: const Text('Open live counter sales terminal'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push(AppRoutes.pos),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.menu_book_rounded, color: AppColors.matchaSage),
                      title: const Text('Help & Operations Guide'),
                      subtitle: const Text('SOP FAQs, POS guides & topic search'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push(AppRoutes.staffHelpGuide),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.matchaSage),
                      title: const Text('Spotlight Coach-Mark Tour'),
                      subtitle: const Text('Replay interactive 8-step Barista station tour'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () {
                        ref.read(baristaSpotlightProvider.notifier).startTour();
                        context.go(AppRoutes.staffOrders);
                      },
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.replay_rounded, color: AppColors.matchaSage),
                      title: const Text('Operations SOP Walkthrough'),
                      subtitle: const Text('Replay 20-step Barista & Staff onboarding'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('${AppRoutes.staffTutorial}?replay=true'),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.store_rounded, color: AppColors.matchaSage),
                      title: const Text('Store Location'),
                      subtitle: const Text('Lambac Coffee Roastery • Session Road Flagship'),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceXxl,

              // End Shift / Sign Out
              AppButton.destructive(
                text: 'End Shift & Sign Out',
                leadingIcon: const Icon(Icons.logout_rounded, size: 18),
                onPressed: () async {
                  final confirm = await AppDialog.show(
                    context,
                    title: 'End Shift',
                    message: 'Are you sure you want to end your shift and sign out of Barista Operations?',
                    confirmText: 'Sign Out',
                    cancelText: 'Stay on Shift',
                  );
                  if (confirm == true) {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      AppToast.info(context, 'Shift ended. Signed out successfully.');
                      context.go(AppRoutes.login);
                    }
                  }
                },
              ),
              AppSpacing.vSpaceLg,
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPermBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.matchaSage.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.matchaSage.withOpacity(0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.matchaSage),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.matchaSage,
            ),
          ),
        ],
      ),
    );
  }
}
