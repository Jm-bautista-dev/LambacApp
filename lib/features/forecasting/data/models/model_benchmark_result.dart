import 'package:equatable/equatable.dart';

/// Supported Forecasting Algorithm Candidate Types
enum ModelCandidateType {
  naivePersistence,
  movingAverage,
  linearRegression,
  polynomialRegression,
  exponentialSmoothing,
  holtsTrend,
  holtWintersSeasonal,
}

extension ModelCandidateTypeX on ModelCandidateType {
  String get displayName {
    switch (this) {
      case ModelCandidateType.naivePersistence:
        return 'Naive Persistence / Lag-7';
      case ModelCandidateType.movingAverage:
        return '7-Day Moving Average';
      case ModelCandidateType.linearRegression:
        return 'Linear Regression (OLS)';
      case ModelCandidateType.polynomialRegression:
        return 'Polynomial Quadratic Trend';
      case ModelCandidateType.exponentialSmoothing:
        return 'Simple Exponential Smoothing (SES)';
      case ModelCandidateType.holtsTrend:
        return "Holt's Linear Trend (Double ES)";
      case ModelCandidateType.holtWintersSeasonal:
        return 'Holt-Winters Seasonal (Triple ES)';
    }
  }

  String get shortCode {
    switch (this) {
      case ModelCandidateType.naivePersistence:
        return 'NAIVE';
      case ModelCandidateType.movingAverage:
        return 'SMA-7';
      case ModelCandidateType.linearRegression:
        return 'OLS-LIN';
      case ModelCandidateType.polynomialRegression:
        return 'POLY-2';
      case ModelCandidateType.exponentialSmoothing:
        return 'SES';
      case ModelCandidateType.holtsTrend:
        return 'HOLT-LIN';
      case ModelCandidateType.holtWintersSeasonal:
        return 'HW-SEASONAL';
    }
  }

  String get description {
    switch (this) {
      case ModelCandidateType.naivePersistence:
        return 'Baseline forecasting model carrying forward recent weekly day-of-week transaction values.';
      case ModelCandidateType.movingAverage:
        return 'Rolling 7-day simple moving average smoothing high-frequency noise and short-term variance.';
      case ModelCandidateType.linearRegression:
        return 'Ordinary least-squares linear trend fitting for steady long-term upward or downward trajectories.';
      case ModelCandidateType.polynomialRegression:
        return 'Degree-2 quadratic polynomial fitting for accelerating growth or nonlinear deceleration curves.';
      case ModelCandidateType.exponentialSmoothing:
        return 'Single exponential smoothing weighting recent transactions exponentially higher than past data.';
      case ModelCandidateType.holtsTrend:
        return 'Double exponential smoothing separating baseline level and velocity trend equations.';
      case ModelCandidateType.holtWintersSeasonal:
        return 'Triple exponential smoothing capturing level, trend, and 7-day cyclical weekly seasonality.';
    }
  }
}

/// Backtested Evaluation & Benchmark Result for a Candidate Forecasting Model
class ModelBenchmarkResult extends Equatable {
  final ModelCandidateType candidateType;
  final String modelName;
  final double mae; // Mean Absolute Error (in ₱)
  final double rmse; // Root Mean Squared Error (in ₱)
  final double mape; // Mean Absolute Percentage Error (%)
  final double smape; // Symmetric Mean Absolute Percentage Error (%)
  final double compositeScore; // Weighted normalized error benchmark score (lower = better)
  final int rank;
  final bool isWinner;
  final bool isSufficientData;
  final String rationale;

  const ModelBenchmarkResult({
    required this.candidateType,
    required this.modelName,
    required this.mae,
    required this.rmse,
    required this.mape,
    required this.smape,
    required this.compositeScore,
    required this.rank,
    required this.isWinner,
    this.isSufficientData = true,
    required this.rationale,
  });

  factory ModelBenchmarkResult.fromJson(Map<String, dynamic> json) {
    final typeStr = json['candidate_type'] as String? ?? 'linearRegression';
    final candidate = ModelCandidateType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ModelCandidateType.linearRegression,
    );

    return ModelBenchmarkResult(
      candidateType: candidate,
      modelName: (json['model_name'] ?? candidate.displayName).toString(),
      mae: ((json['mae'] ?? 0.0) as num).toDouble(),
      rmse: ((json['rmse'] ?? 0.0) as num).toDouble(),
      mape: ((json['mape'] ?? 0.0) as num).toDouble(),
      smape: ((json['smape'] ?? 0.0) as num).toDouble(),
      compositeScore: ((json['composite_score'] ?? 0.0) as num).toDouble(),
      rank: (json['rank'] ?? 1) as int,
      isWinner: (json['is_winner'] ?? false) as bool,
      isSufficientData: (json['is_sufficient_data'] ?? true) as bool,
      rationale: (json['rationale'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidate_type': candidateType.name,
      'model_name': modelName,
      'mae': mae,
      'rmse': rmse,
      'mape': mape,
      'smape': smape,
      'composite_score': compositeScore,
      'rank': rank,
      'is_winner': isWinner,
      'is_sufficient_data': isSufficientData,
      'rationale': rationale,
    };
  }

  @override
  List<Object?> get props => [
        candidateType,
        modelName,
        mae,
        rmse,
        mape,
        smape,
        compositeScore,
        rank,
        isWinner,
        isSufficientData,
        rationale,
      ];
}
