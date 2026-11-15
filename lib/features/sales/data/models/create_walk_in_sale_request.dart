import 'sales_record_item_model.dart';

/// Payload DTO for recording a walk-in store transaction
class CreateWalkInSaleRequest {
  final String? customerName;
  final String? customerPhone;
  final List<SalesRecordItemModel> items;
  final String paymentMethod; // Cash, GCash, Maya, Card
  final String? notes;

  const CreateWalkInSaleRequest({
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.paymentMethod,
    this.notes,
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get totalAmount => subtotal;

  Map<String, dynamic> toJson() {
    return {
      if (customerName != null && customerName!.isNotEmpty) 'customer_name': customerName,
      if (customerPhone != null && customerPhone!.isNotEmpty) 'customer_phone': customerPhone,
      'items': items.map((i) => i.toJson()).toList(),
      'payment_method': paymentMethod,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
