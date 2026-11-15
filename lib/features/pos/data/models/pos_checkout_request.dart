import 'pos_cart_item_model.dart';
import '../../../sales/data/models/sales_record_item_model.dart';

/// Checkout Request DTO for Counter POS Transactions
class PosCheckoutRequest {
  final List<PosCartItemModel> items;
  final String paymentMethod; // 'Cash', 'GCash', 'Maya', 'Card'
  final double? tenderedAmount;
  final double? changeAmount;
  final double discountAmount;
  final String discountType; // 'none', 'pwd_senior', 'staff', 'custom'
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final String staffId;
  final String staffName;
  final String idempotencyKey;

  const PosCheckoutRequest({
    required this.items,
    required this.paymentMethod,
    this.tenderedAmount,
    this.changeAmount,
    this.discountAmount = 0.0,
    this.discountType = 'none',
    this.customerName,
    this.customerPhone,
    this.notes,
    required this.staffId,
    required this.staffName,
    required this.idempotencyKey,
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get totalAmount => (subtotal - discountAmount).clamp(0.0, double.infinity);

  /// Convert to snapshot line items for centralized sales ledger
  List<SalesRecordItemModel> toSalesRecordItems() {
    return items.map((item) {
      final sizeDesc = item.sizeVariant?.name;
      final grindDesc = item.grindVariant?.name;

      return SalesRecordItemModel(
        id: 'pos_item_${item.id}',
        productId: item.product.id,
        productName: item.product.name,
        size: sizeDesc,
        grind: grindDesc,
        snapshotUnitPrice: item.capturedUnitPrice,
        quantity: item.quantity,
        totalPrice: item.lineTotal,
      );
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'idempotency_key': idempotencyKey,
      'payment_method': paymentMethod,
      if (tenderedAmount != null) 'tendered_amount': tenderedAmount,
      if (changeAmount != null) 'change_amount': changeAmount,
      'discount_amount': discountAmount,
      'discount_type': discountType,
      if (customerName != null && customerName!.isNotEmpty) 'customer_name': customerName,
      if (customerPhone != null && customerPhone!.isNotEmpty) 'customer_phone': customerPhone,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'staff_id': staffId,
      'staff_name': staffName,
      'items': toSalesRecordItems().map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'total_amount': totalAmount,
    };
  }
}
