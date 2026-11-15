import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
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
import '../../../onboarding/presentation/spotlight/admin_spotlight_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';

/// Production Business Administrator Control & Settings Screen
class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

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
        title: 'Admin Control Center',
        subtitle: 'System Administration & Security',
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.subtleOperations,
        child: SafeArea(
          child: ResponsiveContentContainer(
          maxWidth: 680,
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Admin Identity Card
              AppCard.elevated(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.brandAmber.withOpacity(0.2) : AppColors.cremaGold.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.brandAmber.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'A',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
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
                                  user?.fullName ?? 'Administrator',
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
                                  color: AppColors.brandAmber.withOpacity(0.18),
                                  borderRadius: AppRadius.radiusPill,
                                ),
                                child: Text(
                                  'ADMINISTRATOR',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? 'admin@lambac.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lambac Roastery HQ • Full System Access',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              // Administrative Modules Shortcuts
              Text(
                'Administrative Governance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              AppSpacing.vSpaceSm,
              AppCard(
                key: SpotlightKeys.adminControlModules,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.point_of_sale_rounded, color: AppColors.brandAmber),
                      title: const Text('Point of Sale (POS Register)'),
                      subtitle: const Text('Live counter sales register with real-time product sync'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push(AppRoutes.pos),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.manage_accounts_rounded, color: AppColors.brandAmber),
                      title: const Text('Account Management & RBAC'),
                      subtitle: const Text('Provision administrators, staff credentials, and security'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push(AppRoutes.adminAccounts),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.table_chart_rounded, color: AppColors.brandAmber),
                      title: const Text('Centralized Sales Ledger'),
                      subtitle: const Text('Audit mobile pickup orders and centralized sales transactions'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push(AppRoutes.adminSales),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brandAmber),
                      title: const Text('Customer Concierge Inbox'),
                      subtitle: const Text('Review customer inquiries and live support logs'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push(AppRoutes.staffInbox),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.trending_up_rounded, color: AppColors.brandAmber),
                      title: const Text('Sales & Demand Forecasting'),
                      subtitle: const Text('Predictive ML time-series bean demand models'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push(AppRoutes.forecasting),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.tune_rounded, color: AppColors.brandAmber),
                      title: const Text('Forecast Benchmarking'),
                      subtitle: const Text('Auditable cross-validation & model selection evidence'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push(AppRoutes.forecastBenchmarking),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.insights_rounded, color: AppColors.brandAmber),
                      title: const Text('Descriptive Analytics'),
                      subtitle: const Text('Historical revenue, basket sizes, and customer metrics'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push(AppRoutes.analytics),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              // Help & Knowledge Hub
              Text(
                'Help & Knowledge Hub',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              AppSpacing.vSpaceSm,
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.menu_book_rounded, color: AppColors.brandAmber),
                      title: const Text('Help & BI System Guide'),
                      subtitle: const Text('Roastery SOP FAQs, forecasting metrics & module directory'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push(AppRoutes.adminHelpGuide),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.brandAmber),
                      title: const Text('Spotlight Coach-Mark Tour'),
                      subtitle: const Text('Live interactive highlight tour of the Executive Platform'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () {
                        ref.read(adminSpotlightProvider.notifier).startTour();
                        context.go(AppRoutes.adminDashboard);
                      },
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.replay_rounded, color: AppColors.brandAmber),
                      title: const Text('Interactive Executive Tour'),
                      subtitle: const Text('Replay 22-step Administrator & BI walkthrough'),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('${AppRoutes.adminTutorial}?replay=true'),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              // System Preferences & Security
              Text(
                'System Configuration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              AppSpacing.vSpaceSm,
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette_outlined, color: AppColors.brandAmber),
                      title: const Text('Theme Appearance'),
                      subtitle: Text('Current mode: ${themeMode.name.toUpperCase()}'),
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                        onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                      ),
                      onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ListTile(
                      leading: const Icon(Icons.security_rounded, color: AppColors.brandAmber),
                      title: const Text('Audit Logging Security'),
                      subtitle: const Text('Active & Tamper-Evident • High-Privilege Token'),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceXxl,

              // Sign Out Button
              AppButton.destructive(
                text: 'Sign Out of Business Platform',
                leadingIcon: const Icon(Icons.logout_rounded, size: 18),
                onPressed: () async {
                  final confirm = await AppDialog.show(
                    context,
                    title: 'Sign Out',
                    message: 'Are you sure you want to sign out of the Administrator Platform?',
                    confirmText: 'Sign Out',
                    cancelText: 'Cancel',
                  );
                  if (confirm == true) {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      AppToast.info(context, 'Signed out of Business Platform.');
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
}
