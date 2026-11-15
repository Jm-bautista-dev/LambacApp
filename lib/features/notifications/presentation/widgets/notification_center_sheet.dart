import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/widgets/buttons/app_scale_button.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_skeleton.dart';
import '../../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../data/models/app_notification_model.dart';
import '../providers/notification_provider.dart';
import 'notification_preferences_sheet.dart';

/// Modal Bottom Sheet displaying Notification History & Deep Link Navigation
/// Elevated with Apple-style sheet ergonomics and Lambac Luxury Roastery aesthetics
class NotificationCenterSheet extends ConsumerWidget {
  const NotificationCenterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      title: 'Notifications',
      child: const NotificationCenterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final state = ref.watch(notificationsNotifierProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);
    final notificationService = ref.watch(notificationServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Actions Row: Messages Count & Preferences / Mark All Read
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                state.hasUnread
                    ? '${state.unreadCount} unread • ${state.notifications.length} total'
                    : '${state.notifications.length} roastery alerts',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.hasUnread)
                    GestureDetector(
                      onTap: () => notifier.markAllAsRead(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          'Mark all read',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      NotificationPreferencesSheet.show(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Preferences',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Body: Loading Skeleton, Empty State, or Scrollable Notification List
        if (state.isLoading)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, __) => AppSkeleton(
              height: 72,
              borderRadius: AppRadius.radiusMd,
            ),
          )
        else if (state.failure != null && state.notifications.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: AppErrorView(
              failure: state.failure!,
              onRetry: () => notifier.loadNotifications(),
            ),
          )
        else if (state.notifications.isEmpty)
          _buildEmptyState(context, isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notif = state.notifications[index];
              return _NotificationTile(
                notification: notif,
                isDark: isDark,
                onTap: () {
                  notifier.markAsRead(notif.id);
                  Navigator.of(context).pop();
                  notificationService.handleNotificationTap(context, notif);
                },
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1A17) : CustomerLuxuryTheme.lightCreamSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : CustomerLuxuryTheme.borderLight,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.notifications_none_rounded,
              size: 28,
              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You're all caught up",
            style: CustomerLuxuryTheme.editorialStyle(
              isDark: isDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'New order updates, barista responses, and micro-lot harvest arrivals will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOrder = notification.type == NotificationType.orderStatus;
    final isChat = notification.type == NotificationType.chatMessage;

    final iconColor = isOrder
        ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
        : isChat
            ? AppColors.info
            : (isDark ? AppColors.cremaGold : AppColors.brandAmberDark);

    final iconBgColor = iconColor.withOpacity(0.12);

    final icon = isOrder
        ? Icons.local_shipping_outlined
        : isChat
            ? Icons.chat_bubble_outline_rounded
            : Icons.coffee_rounded;

    return AppScaleButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: !notification.isRead
              ? (isDark ? const Color(0xFF221C18) : const Color(0xFFFAF5EE))
              : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: !notification.isRead
                ? (isDark ? AppColors.brandAmber.withOpacity(0.4) : AppColors.brandAmber.withOpacity(0.35))
                : (isDark ? AppColors.darkBorder : CustomerLuxuryTheme.borderLight),
            width: 0.9,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: const Color(0xFF1E140C).withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: AppRadius.radiusSm,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatRelativeTime(notification.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
                          color: !notification.isRead
                              ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                              : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
