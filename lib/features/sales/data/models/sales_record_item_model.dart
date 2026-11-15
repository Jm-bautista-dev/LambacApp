import 'package:equatable/equatable.dart';

/// Immutable Historical Transaction Line Item Snapshot
class SalesRecordItemModel extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? size; // e.g. "250g Bag", "500g Bag"
  final String? grind; // e.g. "V60 Pourover"
  final double snapshotUnitPrice; // Frozen selling price at transaction time
  final int quantity;
  final double totalPrice;

  const SalesRecordItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.size,
    this.grind,
    required this.snapshotUnitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory SalesRecordItemModel.fromJson(Map<String, dynamic> json) {
    final unitPrice = ((json['snapshot_unit_price'] ?? json['unit_price'] ?? 0.0) as num).toDouble();
    final qty = (json['quantity'] ?? 1) as int;
    final total = json['total_price'] != null
        ? ((json['total_price']) as num).toDouble()
        : unitPrice * qty;

    return SalesRecordItemModel(
      id: (json['id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      size: json['size']?.toString(),
      grind: json['grind']?.toString(),
      snapshotUnitPrice: unitPrice,
      quantity: qty,
      totalPrice: total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      if (size != null) 'size': size,
      if (grind != null) 'grind': grind,
      'snapshot_unit_price': snapshotUnitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        size,
        grind,
        snapshotUnitPrice,
        quantity,
        totalPrice,
      ];
}
