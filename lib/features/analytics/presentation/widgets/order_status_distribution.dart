import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/order_status_breakdown.dart';

/// Order Status Distribution & Completion Progress Card
class OrderStatusDistributionCard extends StatelessWidget {
  final OrderStatusBreakdown breakdown;

  const OrderStatusDistributionCard({
    super.key,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final total = breakdown.totalOrders == 0 ? 1 : breakdown.totalOrders;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pickup Order Status Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Text(
                  '${breakdown.completionRate.toStringAsFixed(1)}% Completed',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceLg,

          _buildProgressBar('Completed Orders', breakdown.completedCount, total, AppColors.success, isDark),
          AppSpacing.vSpaceSm,
          _buildProgressBar('Ready for Pickup Queue', breakdown.readyForPickupCount, total, isDark ? AppColors.brandAmberLight : AppColors.brandAmber, isDark),
          AppSpacing.vSpaceSm,
          _buildProgressBar('Brewing & Packing', breakdown.preparingCount, total, AppColors.info, isDark),
          AppSpacing.vSpaceSm,
          _buildProgressBar('Pending & Confirmed', breakdown.pendingCount + breakdown.confirmedCount, total, AppColors.warning, isDark),
          AppSpacing.vSpaceSm,
          _buildProgressBar('Cancelled Orders', breakdown.cancelledCount, total, AppColors.error, isDark),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int count, int total, Color color, bool isDark) {
    final ratio = (count / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            Text(
              '$count orders (${(ratio * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: AppRadius.radiusPill,
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
