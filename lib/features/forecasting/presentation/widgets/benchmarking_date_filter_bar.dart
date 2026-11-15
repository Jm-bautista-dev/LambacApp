import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../providers/forecasting_benchmarking_provider.dart';

/// Interactive Date Filter & Control Bar for Forecasting Benchmarking
class BenchmarkingDateFilterBar extends ConsumerWidget {
  final VoidCallback onExport;
  final VoidCallback onRunBenchmark;
  final bool isRebenchmarking;

  const BenchmarkingDateFilterBar({
    super.key,
    required this.onExport,
    required this.onRunBenchmark,
    this.isRebenchmarking = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateRange = ref.watch(benchmarkDateRangeProvider);
    final granularity = ref.watch(benchmarkGranularityProvider);

    final df = DateFormat('MMM d, yyyy');
    final formattedRange = '${df.format(dateRange.start)} – ${df.format(dateRange.end)}';

    return AppCard.elevated(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date Display & Action Buttons
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              // Benchmarking Period Label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BENCHMARKING PERIOD',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 16,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          formattedRange,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Date Range Picker Button
                  AppButton.outlined(
                    text: 'Change Date',
                    leadingIcon: const Icon(Icons.calendar_month_rounded, size: 15),
                    size: AppButtonSize.small,
                    isFullWidth: false,
                    onPressed: () => _showCustomDatePicker(context, ref, dateRange),
                  ),

                  // Export Benchmark Button
                  AppButton.outlined(
                    text: 'Export Benchmark',
                    leadingIcon: const Icon(Icons.download_rounded, size: 15),
                    size: AppButtonSize.small,
                    isFullWidth: false,
                    onPressed: onExport,
                  ),

                  // Run Re-Benchmark Button
                  AppButton.primary(
                    text: isRebenchmarking ? 'Benchmarking...' : 'Run Benchmark',
                    leadingIcon: isRebenchmarking ? null : const Icon(Icons.play_arrow_rounded, size: 16),
                    isLoading: isRebenchmarking,
                    size: AppButtonSize.small,
                    isFullWidth: false,
                    onPressed: isRebenchmarking ? null : onRunBenchmark,
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.vSpaceMd,
          Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          AppSpacing.vSpaceSm,

          // Presets & Granularity Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              // Presets
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Presets: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  _buildPresetChip('Last 7D', 7, ref, isDark),
                  _buildPresetChip('Last 14D', 14, ref, isDark),
                  _buildPresetChip('Last 30D', 30, ref, isDark),
                  _buildPresetChip('Sep 2026', 0, ref, isDark, customStart: DateTime(2026, 9, 1), customEnd: DateTime(2026, 9, 30)),
                ],
              ),

              // Granularity Toggle
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Granularity: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : const Color(0xFFECE5DF),
                      borderRadius: AppRadius.radiusSm,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Daily', 'Weekly'].map((g) {
                        final isSelected = granularity == g;
                        return GestureDetector(
                          onTap: () {
                            ref.read(benchmarkGranularityProvider.notifier).state = g;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                                  : Colors.transparent,
                              borderRadius: AppRadius.radiusSm,
                            ),
                            child: Text(
                              g,
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
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    int days,
    WidgetRef ref,
    bool isDark, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final currentRange = ref.watch(benchmarkDateRangeProvider);

    final targetStart = customStart ?? yesterday.subtract(Duration(days: days - 1));
    final targetEnd = customEnd ?? yesterday;

    final isSelected = currentRange.start.year == targetStart.year &&
        currentRange.start.month == targetStart.month &&
        currentRange.start.day == targetStart.day &&
        currentRange.end.year == targetEnd.year &&
        currentRange.end.month == targetEnd.month &&
        currentRange.end.day == targetEnd.day;

    return GestureDetector(
      onTap: () {
        ref.read(benchmarkDateRangeProvider.notifier).state = DateTimeRange(
          start: targetStart,
          end: targetEnd,
        );
      },
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandAmber.withOpacity(0.18)
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: AppRadius.radiusPill,
            border: Border.all(
              color: isSelected
                  ? AppColors.brandAmber
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      );
  }

  Future<void> _showCustomDatePicker(BuildContext context, WidgetRef ref, DateTimeRange currentRange) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.brandAmber,
                  onPrimary: Colors.white,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      ref.read(benchmarkDateRangeProvider.notifier).state = picked;
    }
  }
}
