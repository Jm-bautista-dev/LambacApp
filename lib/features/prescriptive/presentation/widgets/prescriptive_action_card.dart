import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../../data/models/prescriptive_recommendation_model.dart';
import '../screens/prescriptive_action_detail_screen.dart';

/// Reusable Luxury Card for displaying Prescriptive Action records across Schedule, Queue & History
class PrescriptiveActionCard extends StatelessWidget {
  final PrescriptiveActionModel action;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  const PrescriptiveActionCard({
    super.key,
    required this.action,
    this.onStart,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final priorityColor = switch (action.priority) {
      RecommendationPriority.high => AppColors.error,
      RecommendationPriority.medium => AppColors.warning,
      RecommendationPriority.low => AppColors.info,
    };

    final statusColor = switch (action.status) {
      PrescriptiveActionStatus.completed => AppColors.success,
      PrescriptiveActionStatus.inProgress => AppColors.brandAmber,
      PrescriptiveActionStatus.cancelled => AppColors.error,
      PrescriptiveActionStatus.scheduled => AppColors.info,
      _ => AppColors.cremaGold,
    };

    return AppCard.elevated(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PrescriptiveActionDetailScreen(actionId: action.id),
            ),
          );
        },
        borderRadius: AppRadius.radiusMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category Icon & Priority + Status Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Icon(
                        _getActionIcon(action.actionType),
                        size: 14,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      action.actionType.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(
                        action.priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(
                        action.status.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.vSpaceSm,

            // Action Title
            Text(
              action.title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Target Quantity & Unit Highlight
            Row(
              children: [
                Text(
                  'Target: ',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  '${action.targetQuantity} ${action.targetUnit}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                  ),
                ),
                if (action.assignedTo != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.person_outline_rounded,
                    size: 13,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      action.assignedTo!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 18, thickness: 0.6),

            // Timing and Quick Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      action.status == PrescriptiveActionStatus.completed
                          ? Icons.check_circle_outline_rounded
                          : Icons.access_time_rounded,
                      size: 13,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _getDisplayTiming(action),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (action.status == PrescriptiveActionStatus.scheduled ||
                        action.status == PrescriptiveActionStatus.queued)
                      if (onStart != null)
                        TextButton(
                          onPressed: onStart,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                          ),
                          child: const Text('Start', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    if (action.status == PrescriptiveActionStatus.inProgress)
                      if (onComplete != null)
                        TextButton(
                          onPressed: onComplete,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.success,
                          ),
                          child: const Text('Complete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayTiming(PrescriptiveActionModel a) {
    if (a.completedAt != null) {
      return 'Completed ${_formatTime(a.completedAt!)}';
    }
    if (a.scheduledAt != null) {
      return _formatTime(a.scheduledAt!);
    }
    return 'Created ${_formatTime(a.createdAt)}';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Today $hour:$min $period';
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, $hour:$min $period';
  }

  IconData _getActionIcon(PrescriptiveActionType type) {
    return switch (type) {
      PrescriptiveActionType.roastBatch => Icons.local_fire_department_rounded,
      PrescriptiveActionType.restockRawBeans => Icons.inventory_2_rounded,
      PrescriptiveActionType.menuPromotion => Icons.campaign_rounded,
      PrescriptiveActionType.operationalWorkflow => Icons.storefront_rounded,
      PrescriptiveActionType.informational => Icons.info_outline_rounded,
    };
  }
}
