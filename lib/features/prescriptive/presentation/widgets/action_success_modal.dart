import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../../data/models/prescriptive_recommendation_model.dart';
import '../screens/prescriptive_action_detail_screen.dart';

/// Contextual, Evidence-Based Modal displayed after successful action creation
class ActionSuccessModal extends StatelessWidget {
  final PrescriptiveActionModel action;
  final VoidCallback? onViewSchedule;

  const ActionSuccessModal({
    super.key,
    required this.action,
    this.onViewSchedule,
  });

  static Future<void> show(
    BuildContext context,
    PrescriptiveActionModel action, {
    VoidCallback? onViewSchedule,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ActionSuccessModal(
        action: action,
        onViewSchedule: onViewSchedule,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isScheduled = action.classification == ActionClassification.scheduled;
    final title = isScheduled ? 'Action Scheduled' : 'Action Added to Queue';

    final priorityColor = switch (action.priority) {
      RecommendationPriority.high => AppColors.error,
      RecommendationPriority.medium => AppColors.warning,
      RecommendationPriority.low => AppColors.info,
    };

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Success Icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.brandAmber.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brandAmber.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 30,
                  color: AppColors.brandAmberLight,
                ),
              ),
            ),
            AppSpacing.vSpaceMd,

            // Header Title
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A persistent operational record #${action.id} has been created and synced with the central roastery queue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.35,
              ),
            ),
            AppSpacing.vSpaceLg,

            // Action Metadata Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.coffee_maker_rounded,
                        size: 18,
                        color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Target: ${action.targetQuantity} ${action.targetUnit}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16, thickness: 0.6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (action.scheduledAt != null)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _formatDateTime(action.scheduledAt!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: Text(
                          '${action.priority.name.toUpperCase()} PRIORITY',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.vSpaceLg,

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      foregroundColor:
                          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to action details
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PrescriptiveActionDetailScreen(actionId: action.id),
                        ),
                      );
                    },
                    child: const Text('View Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.primary(
                    text: 'Done',
                    size: AppButtonSize.small,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onViewSchedule?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day} · $hour:$min $period';
  }
}
