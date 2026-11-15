import 'package:equatable/equatable.dart';

/// Aggregated Customer Activity Entity
class CustomerActivitySummary extends Equatable {
  final int uniqueCustomersCount;
  final int repeatCustomersCount;
  final double averageOrderFrequency; // e.g. 2.4 orders / month

  const CustomerActivitySummary({
    required this.uniqueCustomersCount,
    required this.repeatCustomersCount,
    required this.averageOrderFrequency,
  });

  double get repeatRatio =>
      uniqueCustomersCount > 0 ? (repeatCustomersCount / uniqueCustomersCount) * 100 : 0.0;

  factory CustomerActivitySummary.fromJson(Map<String, dynamic> json) {
    return CustomerActivitySummary(
      uniqueCustomersCount: (json['unique_customers_count'] ?? 0) as int,
      repeatCustomersCount: (json['repeat_customers_count'] ?? 0) as int,
      averageOrderFrequency: ((json['average_order_frequency'] ?? 0.0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unique_customers_count': uniqueCustomersCount,
      'repeat_customers_count': repeatCustomersCount,
      'average_order_frequency': averageOrderFrequency,
    };
  }

  @override
  List<Object?> get props => [
        uniqueCustomersCount,
        repeatCustomersCount,
        averageOrderFrequency,
      ];
}
