import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/analytics_summary_model.dart';

/// Visual Card displaying Centralized Sales Breakdown by Channel (Mobile Pickup vs Walk-In POS)
class SalesChannelBreakdownCard extends StatelessWidget {
  final AnalyticsSummaryModel summary;

  const SalesChannelBreakdownCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mobilePercent = summary.mobileSalesPercent;
    final walkInPercent = summary.walkInSalesPercent;

    return AppCard.elevated(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.brandAmber.withOpacity(0.2) : AppColors.brandAmber.withOpacity(0.12),
                        borderRadius: AppRadius.radiusSm,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.account_tree_rounded,
                        size: 16,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Centralized Sales by Channel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Customer Mobile Pickup Orders & Scheduled Collections',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.matchaSage.withOpacity(0.15),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: const Text(
                  'UNIFIED LEDGER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.matchaSage,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceLg,

          // Visual Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: walkInPercent > 0 ? mobilePercent.round().clamp(1, 99) : 100,
                    child: Container(color: AppColors.brandAmber),
                  ),
                  if (walkInPercent > 0) ...[
                    const SizedBox(width: 2),
                    Expanded(
                      flex: walkInPercent.round().clamp(1, 99),
                      child: Container(
                        color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AppSpacing.vSpaceLg,

          // Channels Grid Summary
          Row(
            children: [
              // Mobile Pickup Channel
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFFAF5EE),
                    borderRadius: AppRadius.radiusSm,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.brandAmber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Mobile Pickup',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(summary.mobileSalesAmount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${mobilePercent.toStringAsFixed(1)}% revenue (${summary.mobileOrdersCount} orders)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Walk-In POS Channel
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFFAF5EE),
                    borderRadius: AppRadius.radiusSm,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Walk-In POS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(summary.walkInSalesAmount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${walkInPercent.toStringAsFixed(1)}% revenue (${summary.walkInOrdersCount} sales)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Informative Footer
          Text(
            'Sales from mobile customer orders and walk-in counter transactions are unified in the Central Sales Ledger for accurate business forecasting.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
