import 'package:equatable/equatable.dart';

/// Time-Series Data Point for Sales & Volume Charts
class SalesTrendDataPoint extends Equatable {
  final String dateLabel; // e.g. "Mon", "Aug 15"
  final DateTime timestamp;
  final double salesAmount;
  final int ordersCount;

  const SalesTrendDataPoint({
    required this.dateLabel,
    required this.timestamp,
    required this.salesAmount,
    required this.ordersCount,
  });

  factory SalesTrendDataPoint.fromJson(Map<String, dynamic> json) {
    return SalesTrendDataPoint(
      dateLabel: (json['date_label'] ?? '').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      salesAmount: ((json['sales_amount'] ?? 0.0) as num).toDouble(),
      ordersCount: (json['orders_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_label': dateLabel,
      'timestamp': timestamp.toIso8601String(),
      'sales_amount': salesAmount,
      'orders_count': ordersCount,
    };
  }

  @override
  List<Object?> get props => [dateLabel, timestamp, salesAmount, ordersCount];
}
