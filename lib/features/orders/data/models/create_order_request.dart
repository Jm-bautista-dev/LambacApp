import '../../../cart/data/models/cart_item_model.dart';
import '../../../cart/data/models/pickup_location_model.dart';

/// Data Transfer Object for creating a new pickup order
class CreateOrderRequest {
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final List<CartItemModel> items;
  final PickupLocationModel pickupLocation;
  final String pickupDate;
  final String pickupTimeSlot;
  final String paymentMethod;
  final String paymentStatus;
  final String? notes;
  final String? idempotencyKey;

  const CreateOrderRequest({
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.items,
    required this.pickupLocation,
    this.pickupDate = 'Today',
    required this.pickupTimeSlot,
    this.paymentMethod = 'Pay at Counter',
    this.paymentStatus = 'UNPAID',
    this.notes,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName.trim(),
      'customer_phone': customerPhone.trim(),
      if (customerEmail != null && customerEmail!.isNotEmpty) 'customer_email': customerEmail!.trim(),
      'items': items.map((item) => {
        'product_id': item.productId,
        'product_name': item.productName,
        'size': item.sizeVariant?.name,
        'grind': item.grindVariant?.name,
        'unit_price': item.unitPrice,
        'quantity': item.quantity,
        'total_price': item.totalPrice,
        if (item.specialInstructions != null) 'notes': item.specialInstructions,
      }).toList(),
      'pickup_location_id': pickupLocation.id,
      'pickup_date': pickupDate,
      'pickup_time_slot': pickupTimeSlot,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      if (idempotencyKey != null && idempotencyKey!.trim().isNotEmpty) 'idempotency_key': idempotencyKey!.trim(),
    };
  }
}
