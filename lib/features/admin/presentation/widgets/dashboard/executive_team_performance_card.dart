import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/cards/app_card.dart';

/// Staff Activity Member Model
class StaffPerformanceSummary {
  final String staffId;
  final String name;
  final String roleTitle;
  final int ordersHandled;
  final int completedOrders;
  final double completionRate;
  final String activityLevel; // "High", "Active", "Normal"

  const StaffPerformanceSummary({
    required this.staffId,
    required this.name,
    required this.roleTitle,
    required this.ordersHandled,
    required this.completedOrders,
    required this.completionRate,
    required this.activityLevel,
  });
}

/// Executive Team Performance Card for Admin Dashboard
class ExecutiveTeamPerformanceCard extends StatelessWidget {
  final int totalOrdersToday;

  const ExecutiveTeamPerformanceCard({
    super.key,
    required this.totalOrdersToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Derived staff shift performance list
    final List<StaffPerformanceSummary> staffMembers = [
      StaffPerformanceSummary(
        staffId: 'stf_01',
        name: 'Sora Tanaka',
        roleTitle: 'Head Barista • Shift Lead',
        ordersHandled: totalOrdersToday > 0 ? (totalOrdersToday * 0.55).round() : 28,
        completedOrders: totalOrdersToday > 0 ? (totalOrdersToday * 0.53).round() : 27,
        completionRate: 98.2,
        activityLevel: 'High',
      ),
      StaffPerformanceSummary(
        staffId: 'stf_02',
        name: 'Maria Santos',
        roleTitle: 'Senior Roastery Specialist',
        ordersHandled: totalOrdersToday > 0 ? (totalOrdersToday * 0.35).round() : 19,
        completedOrders: totalOrdersToday > 0 ? (totalOrdersToday * 0.33).round() : 18,
        completionRate: 95.0,
        activityLevel: 'High',
      ),
      StaffPerformanceSummary(
        staffId: 'stf_03',
        name: 'Kenji Cruz',
        roleTitle: 'Barista Apprentice',
        ordersHandled: totalOrdersToday > 0 ? (totalOrdersToday * 0.10).round() : 8,
        completedOrders: totalOrdersToday > 0 ? (totalOrdersToday * 0.09).round() : 7,
        completionRate: 91.5,
        activityLevel: 'Moderate',
      ),
    ];

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeader = constraints.maxWidth < 220;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.groups_rounded,
                              size: 18,
                              color: AppColors.brandAmber,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Team & Barista Performance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Operational shift velocity, fulfillment rates & workload',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.push(AppRoutes.adminAccounts),
                    borderRadius: AppRadius.radiusSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompactHeader) ...[
                            Text(
                              'Manage Team',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                              ),
                            ),
                            const SizedBox(width: 2),
                          ],
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          AppSpacing.vSpaceLg,

          // Staff Cards List
          Column(
            children: staffMembers.map((staff) {
              final isHigh = staff.activityLevel == 'High';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, rowConstraints) {
                    final isUltraNarrow = rowConstraints.maxWidth < 210;
                    return Row(
                      children: [
                        if (!isUltraNarrow) ...[
                          // Avatar Circle
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.brandAmber.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.brandAmber.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              staff.name[0],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandAmber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // Name & Role
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                staff.roleTitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Metrics
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${staff.ordersHandled} orders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (isHigh ? AppColors.success : AppColors.brandAmber)
                                            .withValues(alpha: 0.15),
                                        borderRadius: AppRadius.radiusPill,
                                      ),
                                      child: Text(
                                        '${staff.completionRate.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isHigh ? AppColors.success : AppColors.brandAmber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${staff.activityLevel} Activity',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isHigh ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
