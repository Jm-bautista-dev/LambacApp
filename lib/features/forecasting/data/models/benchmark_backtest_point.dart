import 'package:equatable/equatable.dart';

/// Data Point in the Walk-Forward Validation Backtest Window
class BenchmarkBacktestPoint extends Equatable {
  final DateTime timestamp;
  final String dateLabel;
  final double actualSales;
  final double winnerPredictedSales;
  final Map<String, double> candidatePredictions;

  const BenchmarkBacktestPoint({
    required this.timestamp,
    required this.dateLabel,
    required this.actualSales,
    required this.winnerPredictedSales,
    this.candidatePredictions = const {},
  });

  factory BenchmarkBacktestPoint.fromJson(Map<String, dynamic> json) {
    return BenchmarkBacktestPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      dateLabel: json['date_label'] as String,
      actualSales: ((json['actual_sales'] ?? 0.0) as num).toDouble(),
      winnerPredictedSales: ((json['winner_predicted_sales'] ?? 0.0) as num).toDouble(),
      candidatePredictions: (json['candidate_predictions'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'date_label': dateLabel,
      'actual_sales': actualSales,
      'winner_predicted_sales': winnerPredictedSales,
      'candidate_predictions': candidatePredictions,
    };
  }

  @override
  List<Object?> get props => [
        timestamp,
        dateLabel,
        actualSales,
        winnerPredictedSales,
        candidatePredictions,
      ];
}
