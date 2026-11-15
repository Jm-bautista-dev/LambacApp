import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../products/data/models/product_model.dart';

/// Operational Action Alert Model
class DashboardAlertItem {
  final String title;
  final String description;
  final IconData icon;
  final Color severityColor;
  final String actionLabel;
  final VoidCallback onTap;

  const DashboardAlertItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.severityColor,
    required this.actionLabel,
    required this.onTap,
  });
}

/// "Needs Your Attention" Operational Alerts Section
class OperationalAlertsSection extends StatelessWidget {
  final int unreadInboxCount;
  final int pendingOrdersCount;
  final int preparingOrdersCount;
  final List<ProductModel> products;

  const OperationalAlertsSection({
    super.key,
    required this.unreadInboxCount,
    required this.pendingOrdersCount,
    required this.preparingOrdersCount,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<DashboardAlertItem> alerts = [];

    // 1. Unread Messages Alert
    if (unreadInboxCount > 0) {
      alerts.add(
        DashboardAlertItem(
          title: '$unreadInboxCount Customer Inquiries Awaiting Response',
          description: 'Concierge messages require barista or manager attention.',
          icon: Icons.mark_chat_unread_rounded,
          severityColor: AppColors.error,
          actionLabel: 'Open Inbox',
          onTap: () => context.push(AppRoutes.staffInbox),
        ),
      );
    }

    // 2. Active Orders In Preparation Alert
    final totalAwaitingPrep = pendingOrdersCount + preparingOrdersCount;
    if (totalAwaitingPrep > 0) {
      alerts.add(
        DashboardAlertItem(
          title: '$totalAwaitingPrep Orders In Active Preparation Queue',
          description: '$pendingOrdersCount pending acceptance, $preparingOrdersCount currently brewing.',
          icon: Icons.coffee_maker_rounded,
          severityColor: AppColors.brandAmber,
          actionLabel: 'View Queue',
          onTap: () => context.go(AppRoutes.adminOrders),
        ),
      );
    }

    // 3. Low/Sold-out Stock Alert
    final soldOutCount = products.where((p) => !p.isEnabled).length;
    if (soldOutCount > 0) {
      alerts.add(
        DashboardAlertItem(
          title: '$soldOutCount Coffee Roasts Marked Unavailable',
          description: 'Update batch inventory or re-enable roasted origins.',
          icon: Icons.inventory_2_rounded,
          severityColor: AppColors.warning,
          actionLabel: 'Manage Beans',
          onTap: () => context.go(AppRoutes.adminProducts),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: alerts.isNotEmpty ? AppColors.brandAmber : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Needs Your Attention',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (alerts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: Text(
                    '${alerts.length} Action Items',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        if (alerts.isEmpty)
          AppCard.elevated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operations Running Smoothly',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'All customer inquiries answered, order queue fulfilled, inventory in balance.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: alerts.map((alert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard.elevated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: alert.onTap,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 220;
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: alert.severityColor.withValues(alpha: 0.15),
                              borderRadius: AppRadius.radiusSm,
                            ),
                            child: Icon(alert.icon, color: alert.severityColor, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  alert.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isCompact) ...[
                            Text(
                              alert.actionLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
