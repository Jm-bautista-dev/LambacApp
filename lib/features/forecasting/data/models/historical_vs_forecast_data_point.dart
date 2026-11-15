import 'package:equatable/equatable.dart';

/// Data Point representing Historical (actual) or Forecasted (predicted) Sales
class HistoricalVsForecastDataPoint extends Equatable {
  final String dateLabel; // e.g. "Aug 15"
  final DateTime timestamp;
  final double? actualSales;
  final double? predictedSales;
  final double? lowerBound; // 95% Confidence Interval Lower
  final double? upperBound; // 95% Confidence Interval Upper
  final bool isForecasted;

  const HistoricalVsForecastDataPoint({
    required this.dateLabel,
    required this.timestamp,
    this.actualSales,
    this.predictedSales,
    this.lowerBound,
    this.upperBound,
    required this.isForecasted,
  });

  factory HistoricalVsForecastDataPoint.fromJson(Map<String, dynamic> json) {
    return HistoricalVsForecastDataPoint(
      dateLabel: (json['date_label'] ?? '').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actualSales: json['actual_sales'] != null ? ((json['actual_sales']) as num).toDouble() : null,
      predictedSales: json['predicted_sales'] != null ? ((json['predicted_sales']) as num).toDouble() : null,
      lowerBound: json['lower_bound'] != null ? ((json['lower_bound']) as num).toDouble() : null,
      upperBound: json['upper_bound'] != null ? ((json['upper_bound']) as num).toDouble() : null,
      isForecasted: (json['is_forecasted'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_label': dateLabel,
      'timestamp': timestamp.toIso8601String(),
      if (actualSales != null) 'actual_sales': actualSales,
      if (predictedSales != null) 'predicted_sales': predictedSales,
      if (lowerBound != null) 'lower_bound': lowerBound,
      if (upperBound != null) 'upper_bound': upperBound,
      'is_forecasted': isForecasted,
    };
  }

  @override
  List<Object?> get props => [
        dateLabel,
        timestamp,
        actualSales,
        predictedSales,
        lowerBound,
        upperBound,
        isForecasted,
      ];
}
