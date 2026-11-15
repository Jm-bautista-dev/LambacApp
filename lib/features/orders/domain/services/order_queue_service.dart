import '../../data/models/order_model.dart';
import 'pickup_scheduling_service.dart';

/// Operational Urgency Level for Lambac Roastery Pickup Queue
enum OrderUrgency {
  overdue,
  dueSoon,
  upcoming,
  later;

  String get displayLabel {
    return switch (this) {
      OrderUrgency.overdue => 'Overdue',
      OrderUrgency.dueSoon => 'Due Soon',
      OrderUrgency.upcoming => 'Upcoming',
      OrderUrgency.later => 'Later',
    };
  }
}

/// Dynamic Order Queue Operational Metrics Container
class OrderQueueMetrics {
  final int activeCount;
  final int preparingCount;
  final int readyCount;
  final int overdueOrDueSoonCount;
  final int completedCount;
  final int totalCount;

  const OrderQueueMetrics({
    required this.activeCount,
    required this.preparingCount,
    required this.readyCount,
    required this.overdueOrDueSoonCount,
    required this.completedCount,
    required this.totalCount,
  });
}

/// Production Order Queue Prioritization & Urgency Engine
class OrderQueueService {
  static const OrderQueueService _instance = OrderQueueService._internal();
  factory OrderQueueService() => _instance;
  const OrderQueueService._internal();

  /// Resolves the exact scheduled pickup [DateTime] for an order.
  DateTime resolvePickupDateTime(OrderModel order, [DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();
    final pickupDateStr = order.pickupDate.trim();
    final timeSlotStr = order.pickupTimeSlot.trim();

    // Check if slot is ASAP
    if (timeSlotStr.toUpperCase().contains('ASAP')) {
      return order.createdAt.add(const Duration(minutes: 20));
    }

    // Resolve date component
    DateTime date;
    if (pickupDateStr.equalsIgnoreCase('Today') || pickupDateStr.isEmpty) {
      date = DateTime(now.year, now.month, now.day);
    } else if (pickupDateStr.equalsIgnoreCase('Tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    } else {
      // Attempt standard ISO or named date parsing
      final parsedIso = DateTime.tryParse(pickupDateStr);
      if (parsedIso != null) {
        date = DateTime(parsedIso.year, parsedIso.month, parsedIso.day);
      } else {
        // Fallback or attempt to parse month day strings (e.g. "Sep 25", "Friday, Sep 25")
        date = _parseCustomDateString(pickupDateStr, now) ?? DateTime(now.year, now.month, now.day);
      }
    }

    // Resolve time component
    final timeOfDay = PickupSchedulingService().parseTimeString(timeSlotStr);
    if (timeOfDay != null) {
      return DateTime(date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute);
    }

    // If time cannot be parsed, fallback to estimatedReadyAt or order creation + 30 mins
    return order.estimatedReadyAt ?? order.createdAt.add(const Duration(minutes: 30));
  }

  /// Evaluates operational urgency for an order based on current time & pickup schedule
  OrderUrgency getOrderUrgency(OrderModel order, [DateTime? referenceNow]) {
    if (!order.status.isActive) {
      return OrderUrgency.later;
    }

    final now = referenceNow ?? DateTime.now();
    final scheduledPickup = resolvePickupDateTime(order, now);
    final difference = scheduledPickup.difference(now);

    // Overdue: Scheduled pickup is past and order is not ready for customer pickup yet
    if (difference.isNegative &&
        order.status != OrderStatus.readyForPickup &&
        order.status != OrderStatus.completed) {
      return OrderUrgency.overdue;
    }

    // Due Soon: Within 35 minutes or order is already ready for pickup
    if (order.status == OrderStatus.readyForPickup || (!difference.isNegative && difference.inMinutes <= 35)) {
      return OrderUrgency.dueSoon;
    }

    // Upcoming: Scheduled for today beyond 35 minutes
    final isToday = scheduledPickup.year == now.year &&
        scheduledPickup.month == now.month &&
        scheduledPickup.day == now.day;

    if (isToday) {
      return OrderUrgency.upcoming;
    }

    // Later: Scheduled for tomorrow or future dates
    return OrderUrgency.later;
  }

  /// Returns a clean, professional human-readable urgency status description
  String getUrgencyDescription(OrderModel order, [DateTime? referenceNow]) {
    if (order.status == OrderStatus.readyForPickup) {
      return 'Ready for Customer Pickup';
    }
    if (order.status == OrderStatus.completed) {
      return 'Completed';
    }
    if (order.status == OrderStatus.cancelled) {
      return 'Cancelled';
    }

    final now = referenceNow ?? DateTime.now();
    final scheduledPickup = resolvePickupDateTime(order, now);
    final difference = scheduledPickup.difference(now);

    if (difference.isNegative) {
      final passedMinutes = difference.inMinutes.abs();
      if (passedMinutes < 1) return 'Pickup Due Right Now';
      return 'Pickup Overdue by ${passedMinutes}m';
    }

    if (difference.inMinutes <= 60) {
      if (difference.inMinutes <= 1) return 'Pickup in ~1 min';
      return 'Pickup in ${difference.inMinutes} mins';
    }

    final isToday = scheduledPickup.year == now.year &&
        scheduledPickup.month == now.month &&
        scheduledPickup.day == now.day;

    if (isToday) {
      return 'Scheduled for ${order.pickupTimeSlot}';
    }

    return '${order.pickupDate} • ${order.pickupTimeSlot}';
  }

  /// Sorts orders with coffee roastery operational queue priority:
  /// 1. Overdue orders first (most overdue first)
  /// 2. Active orders sorted by earliest scheduled pickup date/time
  /// 3. In-progress status priority (Ready -> Prepared -> Preparing -> Confirmed -> Pending)
  /// 4. Creation timestamp ascending
  List<OrderModel> sortQueueOrders(List<OrderModel> orders, [DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();
    final sorted = List<OrderModel>.from(orders);

    sorted.sort((a, b) {
      // 1. Active vs Non-Active
      if (a.status.isActive && !b.status.isActive) return -1;
      if (!a.status.isActive && b.status.isActive) return 1;

      // If both non-active, sort by newest createdAt descending
      if (!a.status.isActive && !b.status.isActive) {
        return b.createdAt.compareTo(a.createdAt);
      }

      final aPickup = resolvePickupDateTime(a, now);
      final bPickup = resolvePickupDateTime(b, now);

      final aIsOverdue = aPickup.isBefore(now) && a.status != OrderStatus.readyForPickup;
      final bIsOverdue = bPickup.isBefore(now) && b.status != OrderStatus.readyForPickup;

      // 2. Overdue orders prioritized at top
      if (aIsOverdue && !bIsOverdue) return -1;
      if (!aIsOverdue && bIsOverdue) return 1;

      // 3. Earliest pickup time first
      final pickupComparison = aPickup.compareTo(bPickup);
      if (pickupComparison != 0) return pickupComparison;

      // 4. Status priority (Ready for pickup > Preparing > Pending)
      final aPriority = _statusPriority(a.status);
      final bPriority = _statusPriority(b.status);
      if (aPriority != bPriority) return bPriority.compareTo(aPriority);

      // 5. Creation date ascending (first ordered, first served)
      return a.createdAt.compareTo(b.createdAt);
    });

    return sorted;
  }

  /// Calculates real-time database-driven queue metrics
  OrderQueueMetrics calculateMetrics(List<OrderModel> orders, [DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();

    int active = 0;
    int preparing = 0;
    int ready = 0;
    int urgentOrOverdue = 0;
    int completed = 0;

    for (final order in orders) {
      if (order.status.isActive) {
        active++;
        if (order.status == OrderStatus.preparing || order.status == OrderStatus.prepared) {
          preparing++;
        }
        if (order.status == OrderStatus.readyForPickup) {
          ready++;
        }
        final urgency = getOrderUrgency(order, now);
        if (urgency == OrderUrgency.overdue || urgency == OrderUrgency.dueSoon) {
          urgentOrOverdue++;
        }
      } else if (order.status == OrderStatus.completed) {
        completed++;
      }
    }

    return OrderQueueMetrics(
      activeCount: active,
      preparingCount: preparing,
      readyCount: ready,
      overdueOrDueSoonCount: urgentOrOverdue,
      completedCount: completed,
      totalCount: orders.length,
    );
  }

  int _statusPriority(OrderStatus status) {
    return switch (status) {
      OrderStatus.readyForPickup => 5,
      OrderStatus.prepared => 4,
      OrderStatus.preparing => 3,
      OrderStatus.confirmed => 2,
      OrderStatus.pending => 1,
      OrderStatus.completed => 0,
      OrderStatus.cancelled => -1,
    };
  }

  DateTime? _parseCustomDateString(String str, DateTime now) {
    const months = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
      'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
    };

    final upper = str.toUpperCase();
    for (final entry in months.entries) {
      if (upper.contains(entry.key)) {
        final match = RegExp(r'(\d{1,2})').firstMatch(upper);
        if (match != null) {
          final day = int.tryParse(match.group(1)!) ?? now.day;
          return DateTime(now.year, entry.value, day);
        }
      }
    }
    return null;
  }
}

extension _StringCaseExt on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}
