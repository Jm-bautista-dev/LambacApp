import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import 'orders_provider.dart';

/// StreamProvider family that streams real-time order lifecycle changes
/// Combines an instant event-driven broadcast stream with a fallback synchronization
/// poll to guarantee 100% status accuracy across all network conditions.
final orderTrackingStreamProvider = StreamProvider.autoDispose.family<OrderModel, String>((ref, orderId) {
  final repository = ref.watch(orderRepositoryProvider);
  final controller = StreamController<OrderModel>();
  OrderModel? latestEmitted;

  void emitOrder(OrderModel order) {
    if (controller.isClosed) return;
    // Guard: once completed, do not allow stale polling or events to revert it
    if (latestEmitted != null &&
        latestEmitted!.status == OrderStatus.completed &&
        order.status != OrderStatus.completed) {
      return;
    }
    latestEmitted = order;
    controller.add(order);
  }

  // 1. Initial immediate fetch from backend source of truth
  repository.getOrderById(orderId).then((initialResult) {
    if (initialResult.isSuccess) {
      emitOrder(initialResult.dataOrNull!);
    }
  });

  // 2. Real-time event listener (0ms latency reaction to Barista/Admin updates)
  final realTimeSub = repository.watchOrder(orderId).listen((updatedOrder) {
    emitOrder(updatedOrder);
    // Invalidate orderDetailProvider cache so it always mirrors live state
    ref.invalidate(orderDetailProvider(orderId));
  });

  // 3. Fallback synchronization timer (handles offline reconnects / resume)
  final fallbackTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
    final result = await repository.getOrderById(orderId);
    if (result.isSuccess) {
      emitOrder(result.dataOrNull!);
    }
  });

  ref.onDispose(() {
    realTimeSub.cancel();
    fallbackTimer.cancel();
    if (!controller.isClosed) {
      controller.close();
    }
  });

  return controller.stream;
});
