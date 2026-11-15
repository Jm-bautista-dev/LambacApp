import 'package:equatable/equatable.dart';

/// Authoritative Backend Response Model for Customer First-Order GCash Requirement
class FirstOrderEligibility extends Equatable {
  final String customerId;
  final bool hasCompletedFirstOrder;
  final bool requiresFirstOrderGcash;
  final List<String> allowedPaymentMethods;
  final String? activeFirstOrderId;
  final String? qualifyingOrderId;
  final String message;

  const FirstOrderEligibility({
    required this.customerId,
    required this.hasCompletedFirstOrder,
    required this.requiresFirstOrderGcash,
    required this.allowedPaymentMethods,
    this.activeFirstOrderId,
    this.qualifyingOrderId,
    required this.message,
  });

  /// Factory for a customer who MUST pay their first order via PayMongo GCash
  factory FirstOrderEligibility.firstOrderRequired({
    required String customerId,
    String? activeFirstOrderId,
  }) {
    return FirstOrderEligibility(
      customerId: customerId,
      hasCompletedFirstOrder: false,
      requiresFirstOrderGcash: true,
      allowedPaymentMethods: const ['GCash'],
      activeFirstOrderId: activeFirstOrderId,
      qualifyingOrderId: null,
      message: 'Your first order must be paid through GCash.',
    );
  }

  /// Factory for a customer who has already completed a verified first order
  factory FirstOrderEligibility.completed({
    required String customerId,
    String? qualifyingOrderId,
  }) {
    return FirstOrderEligibility(
      customerId: customerId,
      hasCompletedFirstOrder: true,
      requiresFirstOrderGcash: false,
      allowedPaymentMethods: const ['GCash', 'Pay at Counter'],
      activeFirstOrderId: null,
      qualifyingOrderId: qualifyingOrderId,
      message: 'First-order GCash requirement completed. All payment methods available.',
    );
  }

  factory FirstOrderEligibility.fromJson(Map<String, dynamic> json) {
    final completed = (json['has_completed_first_order'] ??
            json['hasCompletedFirstOrder'] ??
            false) ==
        true;
    final requiredGcash = (json['requires_first_order_gcash'] ??
            json['requiresFirstOrderGcash'] ??
            !completed) ==
        true;

    final rawMethods = json['allowed_payment_methods'] ?? json['allowedPaymentMethods'];
    final List<String> methods;
    if (rawMethods is List) {
      methods = rawMethods.map((e) => e.toString()).toList();
    } else {
      methods = requiredGcash ? const ['GCash'] : const ['GCash', 'Pay at Counter'];
    }

    return FirstOrderEligibility(
      customerId: (json['customer_id'] ?? json['customerId'] ?? json['uid'] ?? '').toString(),
      hasCompletedFirstOrder: completed,
      requiresFirstOrderGcash: requiredGcash,
      allowedPaymentMethods: methods,
      activeFirstOrderId: (json['active_first_order_id'] ?? json['activeFirstOrderId'])?.toString(),
      qualifyingOrderId: (json['qualifying_order_id'] ?? json['qualifyingOrderId'])?.toString(),
      message: (json['message'] ??
              (requiredGcash
                  ? 'Your first order must be paid through GCash.'
                  : 'All payment methods available.'))
          .toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'has_completed_first_order': hasCompletedFirstOrder,
      'requires_first_order_gcash': requiresFirstOrderGcash,
      'allowed_payment_methods': allowedPaymentMethods,
      if (activeFirstOrderId != null) 'active_first_order_id': activeFirstOrderId,
      if (qualifyingOrderId != null) 'qualifying_order_id': qualifyingOrderId,
      'message': message,
    };
  }

  bool isPaymentMethodAllowed(String method) {
    final normalized = method.trim().toLowerCase();
    if (requiresFirstOrderGcash) {
      return normalized == 'gcash';
    }
    return allowedPaymentMethods.any((m) => m.trim().toLowerCase() == normalized);
  }

  @override
  List<Object?> get props => [
        customerId,
        hasCompletedFirstOrder,
        requiresFirstOrderGcash,
        allowedPaymentMethods,
        activeFirstOrderId,
        qualifyingOrderId,
        message,
      ];
}

