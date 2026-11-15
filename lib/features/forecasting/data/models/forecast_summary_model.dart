import 'package:equatable/equatable.dart';
import 'historical_vs_forecast_data_point.dart';
import 'model_benchmark_result.dart';
import 'product_demand_forecast_model.dart';

/// Forecast Summary Container with Automatic Model Selection Diagnostics & Benchmarking Leaderboard
class ForecastSummaryModel extends Equatable {
  final bool hasSufficientData;
  final String? insufficientDataReason;
  final String forecastPeriod; // "Next 7 Days", "Next 14 Days", "Next 30 Days"
  final double expectedSales;
  final int expectedOrders;
  final double expectedLowerRange; // 95% Confidence Interval Lower Bound
  final double expectedUpperRange; // 95% Confidence Interval Upper Bound
  final String modelName;
  final ModelCandidateType? winningCandidateType;
  final String selectionReason;
  final String evaluationPeriodLabel;
  final double mae; // Mean Absolute Error (in ₱)
  final double rmse; // Root Mean Squared Error (in ₱)
  final double mape; // Mean Absolute Percentage Error (e.g. 4.2%)
  final double smape; // Symmetric Mean Absolute Percentage Error
  final double benchmarkScore;
  final String businessSummary;
  final List<ModelBenchmarkResult> benchmarkResults;
  final List<HistoricalVsForecastDataPoint> points;
  final List<ProductDemandForecastModel> productDemandForecasts;

  const ForecastSummaryModel({
    required this.hasSufficientData,
    this.insufficientDataReason,
    required this.forecastPeriod,
    required this.expectedSales,
    required this.expectedOrders,
    required this.expectedLowerRange,
    required this.expectedUpperRange,
    required this.modelName,
    this.winningCandidateType,
    required this.selectionReason,
    required this.evaluationPeriodLabel,
    required this.mae,
    required this.rmse,
    required this.mape,
    required this.smape,
    required this.benchmarkScore,
    required this.businessSummary,
    required this.benchmarkResults,
    required this.points,
    required this.productDemandForecasts,
  });

  factory ForecastSummaryModel.insufficientData({
    String reason = 'Not enough historical data to generate a reliable forecast. At least 14 days of transaction records are required.',
  }) {
    return ForecastSummaryModel(
      hasSufficientData: false,
      insufficientDataReason: reason,
      forecastPeriod: 'Next 14 Days',
      expectedSales: 0.0,
      expectedOrders: 0,
      expectedLowerRange: 0.0,
      expectedUpperRange: 0.0,
      modelName: 'None',
      winningCandidateType: null,
      selectionReason: 'Insufficient statistical observations for empirical backtesting.',
      evaluationPeriodLabel: 'N/A',
      mae: 0.0,
      rmse: 0.0,
      mape: 0.0,
      smape: 0.0,
      benchmarkScore: 0.0,
      businessSummary: reason,
      benchmarkResults: const [],
      points: const [],
      productDemandForecasts: const [],
    );
  }

  factory ForecastSummaryModel.fromJson(Map<String, dynamic> json) {
    final hasSufficient = (json['has_sufficient_data'] ?? true) as bool;
    if (!hasSufficient) {
      return ForecastSummaryModel.insufficientData(
        reason: (json['insufficient_data_reason'] ?? 'Insufficient historical transaction records.').toString(),
      );
    }

    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final rawDemand = json['product_demand_forecasts'] as List<dynamic>? ?? [];
    final rawBenchmarks = json['benchmark_results'] as List<dynamic>? ?? [];

    ModelCandidateType? candidateType;
    if (json['winning_candidate_type'] != null) {
      final name = json['winning_candidate_type'] as String;
      candidateType = ModelCandidateType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ModelCandidateType.holtWintersSeasonal,
      );
    }

    return ForecastSummaryModel(
      hasSufficientData: true,
      insufficientDataReason: null,
      forecastPeriod: (json['forecast_period'] ?? 'Next 14 Days').toString(),
      expectedSales: ((json['expected_sales'] ?? 0.0) as num).toDouble(),
      expectedOrders: (json['expected_orders'] ?? 0) as int,
      expectedLowerRange: ((json['expected_lower_range'] ?? 0.0) as num).toDouble(),
      expectedUpperRange: ((json['expected_upper_range'] ?? 0.0) as num).toDouble(),
      modelName: (json['model_name'] ?? 'Holt-Winters Seasonal (Triple ES)').toString(),
      winningCandidateType: candidateType,
      selectionReason: (json['selection_reason'] ?? 'Lowest validated error across empirical backtesting.').toString(),
      evaluationPeriodLabel: (json['evaluation_period_label'] ?? '14-Day Walk-Forward Backtest').toString(),
      mae: ((json['mae'] ?? 0.0) as num).toDouble(),
      rmse: ((json['rmse'] ?? 0.0) as num).toDouble(),
      mape: ((json['mape'] ?? 0.0) as num).toDouble(),
      smape: ((json['smape'] ?? 0.0) as num).toDouble(),
      benchmarkScore: ((json['benchmark_score'] ?? 0.0) as num).toDouble(),
      businessSummary: (json['business_summary'] ?? '').toString(),
      benchmarkResults: rawBenchmarks.map((e) => ModelBenchmarkResult.fromJson(e as Map<String, dynamic>)).toList(),
      points: rawPoints.map((e) => HistoricalVsForecastDataPoint.fromJson(e as Map<String, dynamic>)).toList(),
      productDemandForecasts: rawDemand.map((e) => ProductDemandForecastModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_sufficient_data': hasSufficientData,
      if (insufficientDataReason != null) 'insufficient_data_reason': insufficientDataReason,
      'forecast_period': forecastPeriod,
      'expected_sales': expectedSales,
      'expected_orders': expectedOrders,
      'expected_lower_range': expectedLowerRange,
      'expected_upper_range': expectedUpperRange,
      'model_name': modelName,
      'winning_candidate_type': winningCandidateType?.name,
      'selection_reason': selectionReason,
      'evaluation_period_label': evaluationPeriodLabel,
      'mae': mae,
      'rmse': rmse,
      'mape': mape,
      'smape': smape,
      'benchmark_score': benchmarkScore,
      'business_summary': businessSummary,
      'benchmark_results': benchmarkResults.map((e) => e.toJson()).toList(),
      'points': points.map((e) => e.toJson()).toList(),
      'product_demand_forecasts': productDemandForecasts.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        hasSufficientData,
        insufficientDataReason,
        forecastPeriod,
        expectedSales,
        expectedOrders,
        expectedLowerRange,
        expectedUpperRange,
        modelName,
        winningCandidateType,
        selectionReason,
        evaluationPeriodLabel,
        mae,
        rmse,
        mape,
        smape,
        benchmarkScore,
        businessSummary,
        benchmarkResults,
        points,
        productDemandForecasts,
      ];
}
