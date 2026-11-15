import 'package:equatable/equatable.dart';
import 'model_benchmark_result.dart';

/// Historical Record of an Automated Forecasting Benchmark Execution (Audit Log)
class BenchmarkHistoryEntryModel extends Equatable {
  final String id;
  final DateTime timestamp;
  final String evaluationPeriodLabel;
  final DateTime startDate;
  final DateTime endDate;
  final String granularity;
  final String winningModelName;
  final ModelCandidateType winningCandidateType;
  final double mae;
  final double rmse;
  final double mape;
  final double smape;
  final double compositeScore;
  final int modelsEvaluatedCount;
  final String status;

  const BenchmarkHistoryEntryModel({
    required this.id,
    required this.timestamp,
    required this.evaluationPeriodLabel,
    required this.startDate,
    required this.endDate,
    this.granularity = 'Daily',
    required this.winningModelName,
    required this.winningCandidateType,
    required this.mae,
    required this.rmse,
    required this.mape,
    required this.smape,
    required this.compositeScore,
    this.modelsEvaluatedCount = 7,
    this.status = 'Evaluated',
  });

  factory BenchmarkHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    final candidateStr = json['winning_candidate_type'] as String? ?? 'linearRegression';
    final candidate = ModelCandidateType.values.firstWhere(
      (e) => e.name == candidateStr,
      orElse: () => ModelCandidateType.linearRegression,
    );

    return BenchmarkHistoryEntryModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      evaluationPeriodLabel: json['evaluation_period_label'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      granularity: (json['granularity'] ?? 'Daily') as String,
      winningModelName: json['winning_model_name'] as String,
      winningCandidateType: candidate,
      mae: ((json['mae'] ?? 0.0) as num).toDouble(),
      rmse: ((json['rmse'] ?? 0.0) as num).toDouble(),
      mape: ((json['mape'] ?? 0.0) as num).toDouble(),
      smape: ((json['smape'] ?? 0.0) as num).toDouble(),
      compositeScore: ((json['composite_score'] ?? 0.0) as num).toDouble(),
      modelsEvaluatedCount: (json['models_evaluated_count'] ?? 7) as int,
      status: (json['status'] ?? 'Evaluated') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'evaluation_period_label': evaluationPeriodLabel,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'granularity': granularity,
      'winning_model_name': winningModelName,
      'winning_candidate_type': winningCandidateType.name,
      'mae': mae,
      'rmse': rmse,
      'mape': mape,
      'smape': smape,
      'composite_score': compositeScore,
      'models_evaluated_count': modelsEvaluatedCount,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        evaluationPeriodLabel,
        startDate,
        endDate,
        granularity,
        winningModelName,
        winningCandidateType,
        mae,
        rmse,
        mape,
        smape,
        compositeScore,
        modelsEvaluatedCount,
        status,
      ];
}
