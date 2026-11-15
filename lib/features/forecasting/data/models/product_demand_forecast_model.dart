import 'package:equatable/equatable.dart';

enum DemandTrend { increasing, decreasing, stable }

/// Product-Level Demand Prediction Entity
class ProductDemandForecastModel extends Equatable {
  final String productId;
  final String productName;
  final String categoryName;
  final double historicalAvgDailyBags;
  final double predictedAvgDailyBags;
  final DemandTrend trend;
  final int projectedStockoutDays; // Days until stock depleted based on velocity
  final String explanation; // Business language summary

  const ProductDemandForecastModel({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.historicalAvgDailyBags,
    required this.predictedAvgDailyBags,
    required this.trend,
    required this.projectedStockoutDays,
    required this.explanation,
  });

  factory ProductDemandForecastModel.fromJson(Map<String, dynamic> json) {
    final trendStr = (json['trend'] ?? 'stable').toString().toLowerCase();
    final trend = switch (trendStr) {
      'increasing' => DemandTrend.increasing,
      'decreasing' => DemandTrend.decreasing,
      _ => DemandTrend.stable,
    };

    return ProductDemandForecastModel(
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      historicalAvgDailyBags: ((json['historical_avg_daily_bags'] ?? 0.0) as num).toDouble(),
      predictedAvgDailyBags: ((json['predicted_avg_daily_bags'] ?? 0.0) as num).toDouble(),
      trend: trend,
      projectedStockoutDays: (json['projected_stockout_days'] ?? 14) as int,
      explanation: (json['explanation'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'category_name': categoryName,
      'historical_avg_daily_bags': historicalAvgDailyBags,
      'predicted_avg_daily_bags': predictedAvgDailyBags,
      'trend': trend.name,
      'projected_stockout_days': projectedStockoutDays,
      'explanation': explanation,
    };
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        categoryName,
        historicalAvgDailyBags,
        predictedAvgDailyBags,
        trend,
        projectedStockoutDays,
        explanation,
      ];
}
