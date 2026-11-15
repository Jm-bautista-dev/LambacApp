import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../../data/models/prescriptive_recommendation_model.dart';
import '../screens/prescriptive_action_detail_screen.dart';
import 'action_configuration_sheet.dart';

/// Actionable Decision-Support Recommendation Card with Decision Traceability & Dynamic Action States
class RecommendationCard extends StatelessWidget {
  final PrescriptiveRecommendationModel recommendation;
  final VoidCallback? onNavigateToSchedule;
  final VoidCallback? onNavigateToQueue;
  final VoidCallback? onNavigateToHistory;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onNavigateToSchedule,
    this.onNavigateToQueue,
    this.onNavigateToHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final priorityColor = switch (recommendation.priority) {
      RecommendationPriority.high => AppColors.error,
      RecommendationPriority.medium => AppColors.warning,
      RecommendationPriority.low => AppColors.info,
    };

    final priorityLabel = recommendation.priority.name.toUpperCase();

    final categoryLabel = switch (recommendation.category) {
      RecommendationCategory.preparation => 'Roast Prep',
      RecommendationCategory.inventory => 'Stock Restock',
      RecommendationCategory.promotion => 'Menu Promo',
      RecommendationCategory.productPerformance => 'Performance',
    };

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  categoryLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$priorityLabel PRIORITY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: priorityColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Recommendation Title
          Text(
            recommendation.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          AppSpacing.vSpaceSm,

          // Decision Traceability Pipeline Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFFAF5EE),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTraceStep('Historical Sales', isDark),
                _buildTraceArrow(isDark),
                _buildTraceStep('Forecast Spike', isDark),
                _buildTraceArrow(isDark),
                _buildTraceStep('Decision Rule', isDark),
                _buildTraceArrow(isDark),
                _buildTraceStep('Actionable', isDark, isHighlight: true),
              ],
            ),
          ),
          AppSpacing.vSpaceSm,

          // Explainability ("WHY" Box)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF9F6F0),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      size: 14,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DATA-DRIVEN RATIONALE & EVIDENCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  recommendation.explanation,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Supporting Metric: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        recommendation.supportingMetric,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vSpaceLg,

          // Dynamic Action Execution Area
          _buildActionSection(context, isDark),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, bool isDark) {
    switch (recommendation.actionStatus) {
      case RecommendationActionStatus.actionScheduled:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, size: 16, color: AppColors.info),
                  const SizedBox(width: 6),
                  Text(
                    'ACTION SCHEDULED',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (recommendation.linkedActionScheduledAt != null)
                    Text(
                      _formatScheduledTime(recommendation.linkedActionScheduledAt!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (recommendation.linkedActionId != null)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          foregroundColor:
                              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PrescriptiveActionDetailScreen(
                                actionId: recommendation.linkedActionId!,
                              ),
                            ),
                          );
                        },
                        child: const Text('View Action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        foregroundColor:
                            isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      ),
                      onPressed: onNavigateToSchedule,
                      child: const Text('View Schedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case RecommendationActionStatus.actionQueued:
      case RecommendationActionStatus.inProgress:
        final isInProgress = recommendation.actionStatus == RecommendationActionStatus.inProgress;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandAmber.withOpacity(0.1),
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.brandAmber.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isInProgress ? Icons.hourglass_top_rounded : Icons.queue_rounded,
                    size: 16,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isInProgress ? 'ACTION IN PROGRESS' : 'ACTION IN QUEUE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  minimumSize: Size.zero,
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  foregroundColor:
                      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                onPressed: () {
                  if (recommendation.linkedActionId != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PrescriptiveActionDetailScreen(
                          actionId: recommendation.linkedActionId!,
                        ),
                      ),
                    );
                  } else {
                    onNavigateToQueue?.call();
                  }
                },
                child: const Text('View Queue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

      case RecommendationActionStatus.actionCompleted:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'ACTION COMPLETED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  minimumSize: Size.zero,
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  foregroundColor:
                      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                onPressed: onNavigateToHistory,
                child: const Text('View History', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

      case RecommendationActionStatus.dismissed:
        return Text(
          'Recommendation Dismissed',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        );

      case RecommendationActionStatus.pending:
      default:
        if (recommendation.actionText != null) {
          return AppButton.primary(
            text: recommendation.actionText!,
            size: AppButtonSize.small,
            onPressed: () {
              ActionConfigurationSheet.show(
                context,
                recommendation,
                onActionCreated: onNavigateToSchedule,
              );
            },
          );
        }
        return const SizedBox.shrink();
    }
  }

  String _formatScheduledTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} · $hour:$min $period';
  }

  Widget _buildTraceStep(String text, bool isDark, {bool isHighlight = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
        color: isHighlight
            ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      ),
    );
  }

  Widget _buildTraceArrow(bool isDark) {
    return Icon(
      Icons.arrow_forward_rounded,
      size: 10,
      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
    );
  }
}
