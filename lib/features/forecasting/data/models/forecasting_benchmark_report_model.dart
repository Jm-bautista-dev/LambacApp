import 'package:equatable/equatable.dart';
import 'benchmark_backtest_point.dart';
import 'benchmark_history_entry_model.dart';
import 'model_benchmark_result.dart';

/// Comprehensive Auditable Benchmark Evaluation Report Model
class ForecastingBenchmarkReportModel extends Equatable {
  final DateTime benchmarkTimestamp;
  final DateTime startDate;
  final DateTime endDate;
  final String granularity;
  final String evaluationPeriodLabel;
  final bool hasSufficientData;
  final String? insufficientDataReason;
  final ModelBenchmarkResult winningModel;
  final List<ModelBenchmarkResult> benchmarkResults;
  final List<BenchmarkBacktestPoint> backtestPoints;
  final int totalObservedPoints;
  final int trainingPoints;
  final int validationPoints;
  final String winnerExplanation;
  final String status;
  final List<BenchmarkHistoryEntryModel> history;

  const ForecastingBenchmarkReportModel({
    required this.benchmarkTimestamp,
    required this.startDate,
    required this.endDate,
    this.granularity = 'Daily',
    required this.evaluationPeriodLabel,
    this.hasSufficientData = true,
    this.insufficientDataReason,
    required this.winningModel,
    required this.benchmarkResults,
    this.backtestPoints = const [],
    this.totalObservedPoints = 0,
    this.trainingPoints = 0,
    this.validationPoints = 0,
    required this.winnerExplanation,
    this.status = 'Up to date',
    this.history = const [],
  });

  factory ForecastingBenchmarkReportModel.insufficientData({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) {
    const fallbackResult = ModelBenchmarkResult(
      candidateType: ModelCandidateType.linearRegression,
      modelName: 'None Evaluated',
      mae: 0.0,
      rmse: 0.0,
      mape: 0.0,
      smape: 0.0,
      compositeScore: 0.0,
      rank: 1,
      isWinner: false,
      isSufficientData: false,
      rationale: 'Insufficient data points to calculate reliable cross-validation metrics.',
    );

    return ForecastingBenchmarkReportModel(
      benchmarkTimestamp: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      evaluationPeriodLabel: 'Insufficient Data Scope',
      hasSufficientData: false,
      insufficientDataReason: reason ??
          'A minimum of 7-14 continuous data observations within the selected date range are required to execute statistical backtesting.',
      winningModel: fallbackResult,
      benchmarkResults: const [],
      winnerExplanation: 'Benchmarking halted due to insufficient observations in the specified date range.',
      status: 'Insufficient data',
    );
  }

  @override
  List<Object?> get props => [
        benchmarkTimestamp,
        startDate,
        endDate,
        granularity,
        evaluationPeriodLabel,
        hasSufficientData,
        insufficientDataReason,
        winningModel,
        benchmarkResults,
        backtestPoints,
        totalObservedPoints,
        trainingPoints,
        validationPoints,
        winnerExplanation,
        status,
        history,
      ];
}
