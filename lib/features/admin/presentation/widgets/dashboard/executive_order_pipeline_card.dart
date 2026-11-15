import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/cards/app_card.dart';

/// Executive Order Pipeline & Workload Overview
class ExecutiveOrderPipelineCard extends StatelessWidget {
  final int pendingCount;
  final int preparingCount;
  final int readyCount;
  final int completedCount;

  const ExecutiveOrderPipelineCard({
    super.key,
    required this.pendingCount,
    required this.preparingCount,
    required this.readyCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalActive = pendingCount + preparingCount + readyCount;
    final totalOverall = totalActive + completedCount;
    final completionRatio = totalOverall > 0 ? (completedCount / totalOverall) : 1.0;

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isCompactHeader = headerConstraints.maxWidth < 220;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.sync_alt_rounded,
                              size: 18,
                              color: AppColors.brandAmber,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Live Order Fulfillment Pipeline',
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
                          'Real-time barista stage distribution & active queue throughput',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.go(AppRoutes.adminOrders),
                    borderRadius: AppRadius.radiusSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompactHeader) ...[
                            Text(
                              'Manage Queue',
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

          // 4-Stage Pipeline Grid / Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              final isUltraNarrow = constraints.maxWidth < 200;

              final stages = [
                _PipelineStageData(
                  label: 'PENDING',
                  count: pendingCount,
                  color: AppColors.warning,
                  icon: Icons.hourglass_top_rounded,
                  subtitle: 'Needs review',
                ),
                _PipelineStageData(
                  label: 'PREPARING',
                  count: preparingCount,
                  color: AppColors.brandAmber,
                  icon: Icons.coffee_rounded,
                  subtitle: 'At espresso bar',
                ),
                _PipelineStageData(
                  label: 'READY',
                  count: readyCount,
                  color: AppColors.info,
                  icon: Icons.storefront_rounded,
                  subtitle: 'Awaiting pickup',
                ),
                _PipelineStageData(
                  label: 'COMPLETED',
                  count: completedCount,
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                  subtitle: 'Fulfilled today',
                ),
              ];

              if (isNarrow) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isUltraNarrow ? 1 : 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 82,
                  ),
                  itemCount: stages.length,
                  itemBuilder: (context, index) => _PipelineStageBox(data: stages[index]),
                );
              }

              return Row(
                children: stages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stage = entry.value;

                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _PipelineStageBox(data: stage)),
                        if (index < stages.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          AppSpacing.vSpaceMd,

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Daily Fulfillment Rate',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${(completionRatio * 100).toStringAsFixed(0)}% ($completedCount of $totalOverall)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: AppRadius.radiusPill,
                child: LinearProgressIndicator(
                  value: completionRatio,
                  minHeight: 6,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipelineStageData {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final String subtitle;

  const _PipelineStageData({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.subtitle,
  });
}

class _PipelineStageBox extends StatelessWidget {
  final _PipelineStageData data;

  const _PipelineStageBox({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.go(AppRoutes.adminOrders),
      borderRadius: AppRadius.radiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: isDark ? 0.12 : 0.07),
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: data.color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: data.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(data.icon, size: 13, color: data.color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${data.count}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              data.subtitle,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
