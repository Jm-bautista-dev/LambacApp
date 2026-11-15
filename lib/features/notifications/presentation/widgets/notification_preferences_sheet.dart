import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../data/models/notification_preferences_model.dart';
import '../providers/notification_provider.dart';

/// Modal Bottom Sheet for Notification Toggle Settings
class NotificationPreferencesSheet extends ConsumerWidget {
  const NotificationPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      title: 'Notification Preferences',
      child: const NotificationPreferencesSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final state = ref.watch(notificationsNotifierProvider);
    final prefs = state.preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Manage alerts and push messages from Lambac Coffee Roastery.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        AppSpacing.vSpaceLg,

        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Order Status Updates',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            'Notifications for pickup order confirmation, brewing, and ready alerts.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          value: prefs.orderStatusEnabled,
          activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
          onChanged: (val) {
            final updated = prefs.copyWith(orderStatusEnabled: val);
            ref.read(notificationsNotifierProvider.notifier).updatePreferences(updated);
          },
        ),
        const Divider(height: 16),

        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Barista Concierge Messages',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            'Notifications when roastery staff respond to your in-app chat inquiries.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          value: prefs.chatMessageEnabled,
          activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
          onChanged: (val) {
            final updated = prefs.copyWith(chatMessageEnabled: val);
            ref.read(notificationsNotifierProvider.notifier).updatePreferences(updated);
          },
        ),
        const Divider(height: 16),

        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Special Roast Releases & Promos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            'Occasional notifications about micro-lot bean harvests and special offers.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          value: prefs.promotionalEnabled,
          activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
          onChanged: (val) {
            final updated = prefs.copyWith(promotionalEnabled: val);
            ref.read(notificationsNotifierProvider.notifier).updatePreferences(updated);
          },
        ),
        AppSpacing.vSpaceLg,
      ],
    );
  }
}
