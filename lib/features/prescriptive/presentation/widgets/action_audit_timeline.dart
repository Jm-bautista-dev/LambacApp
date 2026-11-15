import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/prescriptive_action_model.dart';

/// Luxury Vertical Audit Log Timeline for Operational Accountability
class ActionAuditTimeline extends StatelessWidget {
  final List<ActionAuditLogModel> auditLogs;

  const ActionAuditTimeline({
    super.key,
    required this.auditLogs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (auditLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No audit logs recorded yet.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(auditLogs.length, (index) {
        final log = auditLogs[index];
        final isLast = index == auditLogs.length - 1;

        final statusColor = switch (log.toStatus) {
          PrescriptiveActionStatus.completed => AppColors.success,
          PrescriptiveActionStatus.inProgress => AppColors.brandAmber,
          PrescriptiveActionStatus.cancelled => AppColors.error,
          PrescriptiveActionStatus.scheduled => AppColors.info,
          _ => AppColors.cremaGold,
        };

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Column (Node + Vertical Line)
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Log Details Box
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: AppRadius.radiusSm,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.fromStatus != null
                                  ? '${log.fromStatus!.displayName} → ${log.toStatus.displayName}'
                                  : log.toStatus.displayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              _formatTime(log.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By ${log.changedBy}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (log.note != null && log.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            log.note!,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} · $hour:$min $period';
  }
}
