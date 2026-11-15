import 'package:equatable/equatable.dart';

/// Aggregated Order Status Counts & Ratios
class OrderStatusBreakdown extends Equatable {
  final int pendingCount;
  final int confirmedCount;
  final int preparingCount;
  final int readyForPickupCount;
  final int completedCount;
  final int cancelledCount;

  const OrderStatusBreakdown({
    required this.pendingCount,
    required this.confirmedCount,
    required this.preparingCount,
    required this.readyForPickupCount,
    required this.completedCount,
    required this.cancelledCount,
  });

  int get totalOrders =>
      pendingCount + confirmedCount + preparingCount + readyForPickupCount + completedCount + cancelledCount;

  double get completionRate => totalOrders > 0 ? (completedCount / totalOrders) * 100 : 0.0;

  factory OrderStatusBreakdown.fromJson(Map<String, dynamic> json) {
    return OrderStatusBreakdown(
      pendingCount: (json['pending_count'] ?? 0) as int,
      confirmedCount: (json['confirmed_count'] ?? 0) as int,
      preparingCount: (json['preparing_count'] ?? 0) as int,
      readyForPickupCount: (json['ready_for_pickup_count'] ?? 0) as int,
      completedCount: (json['completed_count'] ?? 0) as int,
      cancelledCount: (json['cancelled_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending_count': pendingCount,
      'confirmed_count': confirmedCount,
      'preparing_count': preparingCount,
      'ready_for_pickup_count': readyForPickupCount,
      'completed_count': completedCount,
      'cancelled_count': cancelledCount,
    };
  }

  @override
  List<Object?> get props => [
        pendingCount,
        confirmedCount,
        preparingCount,
        readyForPickupCount,
        completedCount,
        cancelledCount,
      ];
}
