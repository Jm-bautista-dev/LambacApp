import 'package:equatable/equatable.dart';
import '../../../products/data/models/product_model.dart';

/// Business Metrics DTO for Admin Dashboard
class BusinessMetricsModel extends Equatable {
  final double todaySales;
  final int todayOrdersCount;
  final int pendingOrdersCount;
  final int completedOrdersCount;
  final int unreadInboxCount;
  final List<ProductModel> popularProducts;

  const BusinessMetricsModel({
    required this.todaySales,
    required this.todayOrdersCount,
    required this.pendingOrdersCount,
    required this.completedOrdersCount,
    required this.unreadInboxCount,
    required this.popularProducts,
  });

  factory BusinessMetricsModel.fromJson(Map<String, dynamic> json) {
    final rawPopular = json['popular_products'] as List<dynamic>? ?? [];

    return BusinessMetricsModel(
      todaySales: ((json['today_sales'] ?? 0.0) as num).toDouble(),
      todayOrdersCount: (json['today_orders_count'] ?? 0) as int,
      pendingOrdersCount: (json['pending_orders_count'] ?? 0) as int,
      completedOrdersCount: (json['completed_orders_count'] ?? 0) as int,
      unreadInboxCount: (json['unread_inbox_count'] ?? 0) as int,
      popularProducts: rawPopular
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'today_sales': todaySales,
      'today_orders_count': todayOrdersCount,
      'pending_orders_count': pendingOrdersCount,
      'completed_orders_count': completedOrdersCount,
      'unread_inbox_count': unreadInboxCount,
      'popular_products': popularProducts.map((p) => p.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        todaySales,
        todayOrdersCount,
        pendingOrdersCount,
        completedOrdersCount,
        unreadInboxCount,
        popularProducts,
      ];
}
