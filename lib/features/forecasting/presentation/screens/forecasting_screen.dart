import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../providers/forecasting_provider.dart';
import '../widgets/forecast_control_bar.dart';
import '../widgets/hero_forecast_card.dart';
import '../widgets/historical_vs_forecast_chart.dart';
import '../widgets/how_forecasting_works_card.dart';
import '../widgets/model_benchmark_preview_card.dart';
import '../widgets/model_reliability_card.dart';
import '../widgets/product_demand_forecast_card.dart';

/// Premium Production Forecasting & Model Intelligence Screen
class ForecastingScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const ForecastingScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  ConsumerState<ForecastingScreen> createState() => _ForecastingScreenState();
}

class _ForecastingScreenState extends ConsumerState<ForecastingScreen> {
  bool _isRebenchmarking = false;

  Future<void> _handleRebenchmark() async {
    setState(() => _isRebenchmarking = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    ref.refresh(forecastSummaryProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isRebenchmarking = false);
      AppToast.success(
        context,
        'Forecasting candidate algorithms evaluated & best model re-selected!',
      );
    }
  }

  void _handleRefreshForecast() {
    ref.refresh(forecastSummaryProvider);
    AppToast.info(
      context,
      'Forecast regenerated using the current winning model.',
    );
  }

  void _handleOpenBenchmark() {
    context.push(AppRoutes.forecastBenchmarking);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final forecastAsync = ref.watch(forecastSummaryProvider);

    final content = CinematicRoasteryBackground(
      mode: RoasteryAtmosphereMode.subtleOperations,
      child: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 880,
          child: forecastAsync.when(
            data: (summary) {
              // Insufficient Historical Data State
              if (!summary.hasSufficientData) {
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
                            'Not Enough Historical Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          AppSpacing.vSpaceSm,
                          Text(
                            summary.insufficientDataReason ??
                                'Additional historical sales records are required before the system can reliably benchmark forecasting models. At least 14 days of roastery order transactions are required.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.vSpaceXl,
                          AppButton.primary(
                            text: 'Refresh Forecast Engine',
                            leadingIcon: const Icon(Icons.refresh_rounded, size: 16),
                            onPressed: _handleRefreshForecast,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(forecastSummaryProvider),
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    // 1. Forecast Control Bar (Horizon, Status, Actions)
                    ForecastControlBar(
                      onRefreshForecast: _handleRefreshForecast,
                      onRebenchmark: _handleRebenchmark,
                      status: 'Up to date',
                      isRebenchmarking: _isRebenchmarking,
                    ),
                    AppSpacing.vSpaceLg,

                    // 2. Primary Hero Forecast Card & "Why this model?"
                    HeroForecastCard(
                      summary: summary,
                      onOpenBenchmark: _handleOpenBenchmark,
                    ),
                    AppSpacing.vSpaceXl,

                    // 3. Model Benchmark Leaderboard Preview Card
                    if (summary.benchmarkResults.isNotEmpty) ...[
                      ModelBenchmarkPreviewCard(
                        summary: summary,
                        onViewFullBenchmark: _handleOpenBenchmark,
                        onRebenchmark: _handleRebenchmark,
                      ),
                      AppSpacing.vSpaceXl,
                    ],

                    // 4. Business Language Forecast Insight Summary Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.brandAmber.withOpacity(0.16) : const Color(0xFFF7EFE8),
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: isDark ? AppColors.brandAmber.withOpacity(0.5) : AppColors.brandAmber.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 22,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Forecast Insight Summary',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  summary.businessSummary,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vSpaceXl,

                    // 5. Historical vs Forecast Chart with 95% Uncertainty Shading
                    HistoricalVsForecastChart(points: summary.points),
                    AppSpacing.vSpaceXl,

                    // 6. Product-Level Demand Forecasts
                    ProductDemandForecastCard(forecasts: summary.productDemandForecasts),
                    AppSpacing.vSpaceXl,

                    // 7. Measurable Model Reliability & Error Metrics
                    ModelReliabilityCard(summary: summary),
                    AppSpacing.vSpaceXl,

                    // 8. Academic Defensibility Pipeline Flow ("How Forecasting Works")
                    const HowForecastingWorksCard(),
                    AppSpacing.vSpaceXxl,
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: LambacRoasteryLoader(message: 'Generating Demand Forecasts...'),
            ),
            error: (err, _) => AppErrorView(
              title: 'Unable to Load Forecast Data',
              message: err.toString(),
              onRetry: () => ref.refresh(forecastSummaryProvider),
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
        title: 'Sales & Demand Forecasting',
        subtitle: 'Automated Empirical Model Selection & Projection',
        fallbackRoute: AppRoutes.adminDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: 'Forecast Benchmarking Module',
            onPressed: _handleOpenBenchmark,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Forecast',
            onPressed: _handleRefreshForecast,
          ),
        ],
      ),
      body: content,
    );
  }
}
