import 'package:equatable/equatable.dart';
import 'business_insight_model.dart';
import 'customer_activity_summary.dart';
import 'order_status_breakdown.dart';
import 'product_performance_model.dart';
import 'sales_trend_data_point.dart';

/// Aggregated Analytics Dashboard Container
class AnalyticsSummaryModel extends Equatable {
  final String dateRangeLabel; // "Today", "7 Days", "30 Days", "3 Months"
  final double totalSales;
  final double totalSalesChangePercent; // +18.4%
  final int totalOrders;
  final double totalOrdersChangePercent; // +12.5%
  final double averageOrderValue;
  final String topProductName;
  final double mobileSalesAmount;
  final double walkInSalesAmount;
  final int mobileOrdersCount;
  final int walkInOrdersCount;
  final CustomerActivitySummary customerActivity;
  final OrderStatusBreakdown statusBreakdown;
  final List<SalesTrendDataPoint> salesTrends;
  final List<ProductPerformanceModel> topProducts;
  final List<ProductPerformanceModel> lowestProducts;
  final List<BusinessInsightModel> insights;

  const AnalyticsSummaryModel({
    required this.dateRangeLabel,
    required this.totalSales,
    required this.totalSalesChangePercent,
    required this.totalOrders,
    required this.totalOrdersChangePercent,
    required this.averageOrderValue,
    required this.topProductName,
    this.mobileSalesAmount = 142800.0,
    this.walkInSalesAmount = 202800.0,
    this.mobileOrdersCount = 150,
    this.walkInOrdersCount = 278,
    required this.customerActivity,
    required this.statusBreakdown,
    required this.salesTrends,
    required this.topProducts,
    required this.lowestProducts,
    required this.insights,
  });

  double get mobileSalesPercent => totalSales > 0 ? (mobileSalesAmount / totalSales) * 100 : 0.0;
  double get walkInSalesPercent => totalSales > 0 ? (walkInSalesAmount / totalSales) * 100 : 0.0;

  factory AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawTrends = json['sales_trends'] as List<dynamic>? ?? [];
    final rawTop = json['top_products'] as List<dynamic>? ?? [];
    final rawLowest = json['lowest_products'] as List<dynamic>? ?? [];
    final rawInsights = json['insights'] as List<dynamic>? ?? [];

    final total = ((json['total_sales'] ?? 0.0) as num).toDouble();
    final mobileSales = ((json['mobile_sales_amount'] ?? (total * 0.413)) as num).toDouble();
    final walkInSales = ((json['walk_in_sales_amount'] ?? (total * 0.587)) as num).toDouble();
    final totalOrders = (json['total_orders'] ?? 0) as int;

    return AnalyticsSummaryModel(
      dateRangeLabel: (json['date_range_label'] ?? '30 Days').toString(),
      totalSales: total,
      totalSalesChangePercent: ((json['total_sales_change_percent'] ?? 0.0) as num).toDouble(),
      totalOrders: totalOrders,
      totalOrdersChangePercent: ((json['total_orders_change_percent'] ?? 0.0) as num).toDouble(),
      averageOrderValue: ((json['average_order_value'] ?? 0.0) as num).toDouble(),
      topProductName: (json['top_product_name'] ?? 'Mount Apo Anaerobic').toString(),
      mobileSalesAmount: mobileSales,
      walkInSalesAmount: walkInSales,
      mobileOrdersCount: (json['mobile_orders_count'] ?? (totalOrders * 0.35).round()) as int,
      walkInOrdersCount: (json['walk_in_orders_count'] ?? (totalOrders * 0.65).round()) as int,
      customerActivity: CustomerActivitySummary.fromJson(
        (json['customer_activity'] ?? {}) as Map<String, dynamic>,
      ),
      statusBreakdown: OrderStatusBreakdown.fromJson(
        (json['status_breakdown'] ?? {}) as Map<String, dynamic>,
      ),
      salesTrends: rawTrends.map((e) => SalesTrendDataPoint.fromJson(e as Map<String, dynamic>)).toList(),
      topProducts: rawTop.map((e) => ProductPerformanceModel.fromJson(e as Map<String, dynamic>)).toList(),
      lowestProducts: rawLowest.map((e) => ProductPerformanceModel.fromJson(e as Map<String, dynamic>)).toList(),
      insights: rawInsights.map((e) => BusinessInsightModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_range_label': dateRangeLabel,
      'total_sales': totalSales,
      'total_sales_change_percent': totalSalesChangePercent,
      'total_orders': totalOrders,
      'total_orders_change_percent': totalOrdersChangePercent,
      'average_order_value': averageOrderValue,
      'top_product_name': topProductName,
      'mobile_sales_amount': mobileSalesAmount,
      'walk_in_sales_amount': walkInSalesAmount,
      'mobile_orders_count': mobileOrdersCount,
      'walk_in_orders_count': walkInOrdersCount,
      'customer_activity': customerActivity.toJson(),
      'status_breakdown': statusBreakdown.toJson(),
      'sales_trends': salesTrends.map((e) => e.toJson()).toList(),
      'top_products': topProducts.map((e) => e.toJson()).toList(),
      'lowest_products': lowestProducts.map((e) => e.toJson()).toList(),
      'insights': insights.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        dateRangeLabel,
        totalSales,
        totalSalesChangePercent,
        totalOrders,
        totalOrdersChangePercent,
        averageOrderValue,
        topProductName,
        mobileSalesAmount,
        walkInSalesAmount,
        mobileOrdersCount,
        walkInOrdersCount,
        customerActivity,
        statusBreakdown,
        salesTrends,
        topProducts,
        lowestProducts,
        insights,
      ];
}
