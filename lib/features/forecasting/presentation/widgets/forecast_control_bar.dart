import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../providers/forecasting_provider.dart';

/// Control Bar with Forecast Horizon Selector, Model Status Pill, and Refresh/Re-Benchmark Actions
class ForecastControlBar extends ConsumerWidget {
  final VoidCallback onRefreshForecast;
  final VoidCallback onRebenchmark;
  final String status;
  final bool isRebenchmarking;

  const ForecastControlBar({
    super.key,
    required this.onRefreshForecast,
    required this.onRebenchmark,
    this.status = 'Up to date',
    this.isRebenchmarking = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedPeriod = ref.watch(forecastPeriodProvider);
    final horizons = [
      ('7D', '7 Days'),
      ('14D', '14 Days'),
      ('30D', '30 Days'),
    ];

    return AppCard.elevated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          // Left: Horizon Selector & Status Pill
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Forecast Horizon Selector
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFEDE5DF),
                  borderRadius: AppRadius.radiusSm,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                  children: horizons.map((h) {
                    final isSelected = selectedPeriod == h.$1;
                    return GestureDetector(
                      onTap: () {
                        ref.read(forecastPeriodProvider.notifier).state = h.$1;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                              : Colors.transparent,
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: Text(
                          h.$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? AppColors.darkCanvas : Colors.white)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  ),
                ),
              ),

              // Status Pill
              _buildStatusPill(isDark),
            ],
          ),

          // Right: Action Buttons (Refresh vs Re-Benchmark)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Info Icon explaining difference
              IconButton(
                icon: Icon(
                  Icons.help_outline_rounded,
                  size: 17,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                tooltip: 'Refresh Forecast vs Re-Benchmark',
                onPressed: () => _showActionsHelpDialog(context, isDark),
              ),

              // Refresh Forecast Button
              AppButton.outlined(
                text: 'Refresh Forecast',
                leadingIcon: const Icon(Icons.refresh_rounded, size: 14),
                size: AppButtonSize.small,
                isFullWidth: false,
                onPressed: onRefreshForecast,
              ),

              // Re-Benchmark Models Button
              AppButton.primary(
                text: isRebenchmarking ? 'Benchmarking...' : 'Re-Benchmark',
                leadingIcon: isRebenchmarking ? null : const Icon(Icons.science_rounded, size: 14),
                isLoading: isRebenchmarking,
                size: AppButtonSize.small,
                isFullWidth: false,
                onPressed: isRebenchmarking ? null : onRebenchmark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(bool isDark) {
    final isOk = status == 'Up to date';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOk
            ? (isDark ? const Color(0xFF1B3828) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF3E2818) : const Color(0xFFFFF3E0)),
        borderRadius: AppRadius.radiusPill,
        border: Border.all(
          color: isOk ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOk ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isOk
                  ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                  : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionsHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        title: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: AppColors.brandAmber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Forecasting Actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionExplainer(
              'Refresh Forecast',
              'Generates a forward projection using the currently selected best model without re-evaluating candidate algorithms.',
              Icons.refresh_rounded,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildActionExplainer(
              'Re-Benchmark Models',
              'Executes rolling-origin walk-forward backtesting across all candidate algorithms (Holt-Winters, Holt, OLS, SES, MA, Poly, Naive) on the historical sales ledger and selects the lowest-error model.',
              Icons.science_rounded,
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(color: AppColors.brandAmber, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionExplainer(String title, String desc, IconData icon, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.brandAmber),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
