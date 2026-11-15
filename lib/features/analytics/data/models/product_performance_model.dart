import 'package:equatable/equatable.dart';

/// Aggregated Product Sales Performance Entity
class ProductPerformanceModel extends Equatable {
  final String productId;
  final String productName;
  final String categoryName;
  final int quantitySold;
  final double revenueGenerated;
  final double percentageOfTotalRevenue;

  const ProductPerformanceModel({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantitySold,
    required this.revenueGenerated,
    required this.percentageOfTotalRevenue,
  });

  factory ProductPerformanceModel.fromJson(Map<String, dynamic> json) {
    return ProductPerformanceModel(
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      quantitySold: (json['quantity_sold'] ?? 0) as int,
      revenueGenerated: ((json['revenue_generated'] ?? 0.0) as num).toDouble(),
      percentageOfTotalRevenue: ((json['percentage_of_total_revenue'] ?? 0.0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'category_name': categoryName,
      'quantity_sold': quantitySold,
      'revenue_generated': revenueGenerated,
      'percentage_of_total_revenue': percentageOfTotalRevenue,
    };
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        categoryName,
        quantitySold,
        revenueGenerated,
        percentageOfTotalRevenue,
      ];
}
