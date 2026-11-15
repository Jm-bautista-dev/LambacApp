import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/dialogs/app_dialog.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'change_password_sheet.dart';
import 'edit_profile_sheet.dart';

/// Production Member Profile & Preferences Screen
/// Elevated with Apple-inspired minimalism, editorial luxury coffee aesthetics,
/// and complete functional preservation of account settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isGuest = user == null || user.isGuest;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : CustomerLuxuryTheme.warmCream,
      appBar: LambacAppBar(
        showBackButton: false,
        title: 'Member Profile',
        subtitle: 'Lambac Roastery Club',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: CinematicRoasteryBackground.subtle(
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 720,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              children: [
                // Member Identity Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: CustomerLuxuryTheme.cardDecoration(
                    isDark: isDark,
                    isElevated: true,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.brandAmber.withOpacity(isDark ? 0.3 : 0.15),
                                  AppColors.cremaGold.withOpacity(isDark ? 0.2 : 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.brandAmberLight.withOpacity(0.4) : AppColors.brandAmber.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user?.fullName.isNotEmpty ?? false
                                  ? user!.fullName[0].toUpperCase()
                                  : 'L',
                              style: CustomerLuxuryTheme.editorialStyle(
                                isDark: isDark,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                              ),
                            ),
                          ),
                          AppSpacing.hSpaceLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'Coffee Enthusiast',
                                  style: CustomerLuxuryTheme.editorialStyle(
                                    isDark: isDark,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isGuest ? 'Guest Member' : user.email,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.cremaGold.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: AppColors.cremaGold.withOpacity(0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${user?.loyaltyPoints ?? 120} Coffee Beans • ${isGuest ? "Guest Level" : "Gold Tier"}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isGuest) ...[
                        AppSpacing.vSpaceLg,
                        AppButton.outlined(
                          text: 'Edit Profile Information',
                          size: AppButtonSize.small,
                          onPressed: () => EditProfileSheet.show(context, user),
                        ),
                      ] else ...[
                        AppSpacing.vSpaceLg,
                        AppButton.primary(
                          text: 'Sign In / Create Account',
                          size: AppButtonSize.small,
                          onPressed: () => context.push(AppRoutes.login),
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.vSpaceLg,

                // Coffee Taste Preferences Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your Brewing Preferences',
                              style: CustomerLuxuryTheme.editorialStyle(
                                isDark: isDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vSpaceMd,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPreferenceChip(label: 'Light-Medium Roast', isSelected: true, isDark: isDark),
                          _buildPreferenceChip(label: 'Anaerobic Honey', isSelected: true, isDark: isDark),
                          _buildPreferenceChip(label: 'V60 Pourover', isSelected: true, isDark: isDark),
                          _buildPreferenceChip(label: 'Single Origin', isSelected: false, isDark: isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpaceLg,

                // Account & Security Navigation Items
                Container(
                  decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                  child: ClipRRect(
                    borderRadius: AppRadius.radiusLg,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        children: [
                          _buildProfileTile(
                            icon: Icons.receipt_long_outlined,
                            title: 'Order Status & Tracking',
                            subtitle: 'Active orders and past roastery receipts',
                            onTap: () => context.go(AppRoutes.orders),
                            isDark: isDark,
                          ),
                          _buildTileDivider(isDark),
                          _buildProfileTile(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Direct Barista Concierge',
                            subtitle: 'Custom grind recommendations and chat',
                            onTap: () => context.push(AppRoutes.chat),
                            isDark: isDark,
                          ),
                          if (!isGuest) ...[
                            _buildTileDivider(isDark),
                            _buildProfileTile(
                              icon: Icons.lock_outline_rounded,
                              title: 'Change Password',
                              subtitle: 'Update your account password',
                              onTap: () => ChangePasswordSheet.show(context),
                              isDark: isDark,
                            ),
                          ],
                          _buildTileDivider(isDark),
                          _buildProfileTile(
                            icon: Icons.palette_outlined,
                            title: 'Theme Appearance',
                            subtitle: 'Mode: ${themeMode.name.toUpperCase()}',
                            trailing: Switch.adaptive(
                              value: themeMode == ThemeMode.dark,
                              activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                              onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                            ),
                            onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                            isDark: isDark,
                          ),
                          _buildTileDivider(isDark),
                          _buildProfileTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Interactive Guide',
                            subtitle: 'Replay customer tutorial, FAQs & brewing guide',
                            onTap: () => context.push(AppRoutes.helpGuide),
                            isDark: isDark,
                          ),
                          _buildTileDivider(isDark),
                          _buildProfileTile(
                            icon: Icons.settings_outlined,
                            title: 'Preferences & Build Info',
                            subtitle: 'Environment settings, terms, privacy',
                            onTap: () => context.push(AppRoutes.settings),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppSpacing.vSpaceXxl,

                if (!isGuest) ...[
                  AppButton.outlined(
                    text: 'Sign Out',
                    leadingIcon: const Icon(Icons.logout_rounded, size: 18),
                    onPressed: () async {
                      final confirm = await AppDialog.destructive(
                        context,
                        title: 'Sign Out?',
                        message: 'Are you sure you want to sign out of your Lambac Roastery account?',
                        confirmText: 'Sign Out',
                        cancelText: 'Cancel',
                        icon: Icons.logout_rounded,
                      );

                      if (confirm == true) {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) {
                          AppToast.info(context, 'Signed out successfully.');
                          context.go(AppRoutes.home);
                        }
                      }
                    },
                  ),
                  AppSpacing.vSpaceMd,
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () async {
                        final confirm = await AppDialog.show(
                          context,
                          title: 'Delete Account',
                          message: 'This action is permanent and cannot be undone. All your beans points and order history will be deleted.',
                          confirmText: 'Delete Permanently',
                          cancelText: 'Cancel',
                          isDestructive: true,
                          icon: Icons.warning_amber_rounded,
                        );

                        if (confirm == true) {
                          final result = await ref.read(authNotifierProvider.notifier).deleteAccount();
                          if (context.mounted) {
                            if (result.isSuccess) {
                              AppToast.info(context, 'Account deleted.');
                              context.go(AppRoutes.home);
                            } else {
                              AppToast.error(context, result.failureOrNull?.userFriendlyMessage ?? 'Failed to delete account');
                            }
                          }
                        }
                      },
                      child: const Text('Delete Account', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                AppSpacing.vSpaceXxxl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceChip({
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.brandAmber.withOpacity(0.2) : AppColors.brandAmber.withOpacity(0.12))
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: AppRadius.radiusPill,
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
              : (isDark ? AppColors.darkBorder : CustomerLuxuryTheme.borderLight),
          width: isSelected ? 1.2 : 0.8,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.brandAmber : AppColors.brandAmber).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
      onTap: onTap,
    );
  }

  Widget _buildTileDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkBorder : CustomerLuxuryTheme.borderLight,
    );
  }
}
