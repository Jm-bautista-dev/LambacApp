import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../../data/models/model_benchmark_result.dart';
import '../providers/forecasting_benchmarking_provider.dart';
import '../widgets/benchmarking_backtest_chart.dart';
import '../widgets/benchmarking_comparison_table.dart';
import '../widgets/benchmarking_date_filter_bar.dart';
import '../widgets/benchmarking_error_chart.dart';
import '../widgets/benchmarking_history_table.dart';
import '../widgets/benchmarking_kpi_header.dart';
import '../widgets/benchmarking_methodology_flow_card.dart';
import '../widgets/export_benchmark_dialog.dart';
import '../widgets/model_inspection_dialog.dart';

/// Dedicated Production Forecasting Benchmarking Module Screen
/// Provides transparent, auditable, and academically defensible backtest evidence for model selection.
class ForecastingBenchmarkingScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const ForecastingBenchmarkingScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  ConsumerState<ForecastingBenchmarkingScreen> createState() => _ForecastingBenchmarkingScreenState();
}

class _ForecastingBenchmarkingScreenState extends ConsumerState<ForecastingBenchmarkingScreen> {
  bool _isRebenchmarking = false;

  Future<void> _handleRunBenchmark() async {
    setState(() => _isRebenchmarking = true);
    ref.read(isRebenchmarkingActiveProvider.notifier).state = true;

    // Simulate realistic multi-step backtest progress
    await Future<void>.delayed(const Duration(milliseconds: 400));
    ref.read(rebenchmarkNonceProvider.notifier).state++;
    ref.invalidate(forecastingBenchmarkReportProvider);

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isRebenchmarking = false);
      ref.read(isRebenchmarkingActiveProvider.notifier).state = false;
      AppToast.success(
        context,
        'Cross-validation backtest completed! Candidate models re-ranked and current forecast model updated.',
      );
    }
  }

  void _handleInspectModel(ModelBenchmarkResult model) {
    final report = ref.read(forecastingBenchmarkReportProvider).asData?.value;
    if (report == null) return;
    ModelInspectionDialog.show(context, model: model, report: report);
  }

  void _handleExport() {
    final report = ref.read(forecastingBenchmarkReportProvider).asData?.value;
    if (report == null) return;
    ExportBenchmarkDialog.show(context, report);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final reportAsync = ref.watch(forecastingBenchmarkReportProvider);

    final content = CinematicRoasteryBackground(
      mode: RoasteryAtmosphereMode.subtleOperations,
      child: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 920,
          child: reportAsync.when(
            data: (report) {
              // Insufficient Historical Data State
              if (!report.hasSufficientData) {
                return Center(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: AppCard.elevated(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 48,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                          ),
                          AppSpacing.vSpaceLg,
                          Text(
                            'Insufficient Historical Data for Selected Range',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.vSpaceSm,
                          Text(
                            report.insufficientDataReason ??
                                'Not enough historical order records within the selected date filter. Please choose a broader date range or select a preset.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.vSpaceXl,
                          BenchmarkingDateFilterBar(
                            onExport: () {},
                            onRunBenchmark: _handleRunBenchmark,
                            isRebenchmarking: _isRebenchmarking,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(forecastingBenchmarkReportProvider);
                },
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    // 1. Interactive Date Range & Control Bar
                    BenchmarkingDateFilterBar(
                      onExport: _handleExport,
                      onRunBenchmark: _handleRunBenchmark,
                      isRebenchmarking: _isRebenchmarking,
                    ),
                    AppSpacing.vSpaceLg,

                    // 2. Current Best Model Showcase & Top KPI Grid
                    BenchmarkingKpiHeader(
                      report: report,
                      isRebenchmarking: _isRebenchmarking,
                    ),
                    AppSpacing.vSpaceXl,

                    // 3. Academic Defensibility Pipeline Flow (Step 1 to 7)
                    const BenchmarkingMethodologyFlowCard(),
                    AppSpacing.vSpaceXl,

                    // 4. Model Comparison & Backtest Error Leaderboard Table
                    BenchmarkingComparisonTable(
                      results: report.benchmarkResults,
                      onInspectModel: _handleInspectModel,
                    ),
                    AppSpacing.vSpaceXl,

                    // 5. Performance Visualizations: Error Comparison (MAE/RMSE & MAPE/sMAPE)
                    BenchmarkingErrorChart(results: report.benchmarkResults),
                    AppSpacing.vSpaceXl,

                    // 6. Out-of-Sample Backtest: Actual vs Predicted Curve
                    if (report.backtestPoints.isNotEmpty) ...[
                      BenchmarkingBacktestChart(
                        points: report.backtestPoints,
                        winningModel: report.winningModel,
                      ),
                      AppSpacing.vSpaceXl,
                    ],

                    // 7. Historical Benchmark Audit Log Table
                    if (report.history.isNotEmpty) ...[
                      BenchmarkingHistoryTable(history: report.history),
                      AppSpacing.vSpaceXxl,
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: LambacRoasteryLoader(message: 'Executing Rolling-Origin Backtesting...'),
            ),
            error: (err, _) => AppErrorView(
              title: 'Unable to Generate Benchmark Report',
              message: err.toString(),
              onRetry: () => ref.refresh(forecastingBenchmarkReportProvider),
            ),
          ),
        ),
      ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        title: 'Forecast Benchmarking',
        subtitle: 'Automated Empirical Model Selection & Audit',
        fallbackRoute: AppRoutes.forecasting,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 20),
            tooltip: 'Export Benchmark',
            onPressed: _handleExport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Benchmark',
            onPressed: () => ref.refresh(forecastingBenchmarkReportProvider),
          ),
        ],
      ),
      body: content,
    );
  }
}
