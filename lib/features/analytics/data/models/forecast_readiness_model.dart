import 'package:equatable/equatable.dart';

enum ReadinessStatus {
  ready,
  marginal,
  insufficient;

  String get badgeText {
    return switch (this) {
      ReadinessStatus.ready => 'FORECAST READY',
      ReadinessStatus.marginal => 'MARGINAL DATA',
      ReadinessStatus.insufficient => 'INSUFFICIENT DATA',
    };
  }
}

/// Statistical Forecast Readiness Assessment Entity
class ForecastReadinessModel extends Equatable {
  final ReadinessStatus status;
  final int historicalRecordCount;
  final int historicalDaySpan;
  final double completenessScorePercent;
  final String explanation;
  final List<String> missingRequirements;

  const ForecastReadinessModel({
    required this.status,
    required this.historicalRecordCount,
    required this.historicalDaySpan,
    required this.completenessScorePercent,
    required this.explanation,
    this.missingRequirements = const [],
  });

  bool get isReady => status == ReadinessStatus.ready || status == ReadinessStatus.marginal;

  factory ForecastReadinessModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? 'ready').toString().toLowerCase();
    final status = switch (statusStr) {
      'marginal' => ReadinessStatus.marginal,
      'insufficient' => ReadinessStatus.insufficient,
      _ => ReadinessStatus.ready,
    };

    final rawMissing = json['missing_requirements'] as List<dynamic>? ?? [];

    return ForecastReadinessModel(
      status: status,
      historicalRecordCount: (json['historical_record_count'] ?? 0) as int,
      historicalDaySpan: (json['historical_day_span'] ?? 0) as int,
      completenessScorePercent: ((json['completeness_score_percent'] ?? 100.0) as num).toDouble(),
      explanation: (json['explanation'] ?? '').toString(),
      missingRequirements: rawMissing.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'historical_record_count': historicalRecordCount,
      'historical_day_span': historicalDaySpan,
      'completeness_score_percent': completenessScorePercent,
      'explanation': explanation,
      'missing_requirements': missingRequirements,
    };
  }

  @override
  List<Object?> get props => [
        status,
        historicalRecordCount,
        historicalDaySpan,
        completenessScorePercent,
        explanation,
        missingRequirements,
      ];
}
