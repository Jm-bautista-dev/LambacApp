import 'package:equatable/equatable.dart';
import '../../../cart/data/models/cart_item_model.dart';

/// Immutable snapshot of an ordered item
class OrderItemModel extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String origin;
  final String? size;
  final String? grind;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final String? notes;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.origin,
    this.size,
    this.grind,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.notes,
  });

  factory OrderItemModel.fromCartItem(CartItemModel cartItem) {
    return OrderItemModel(
      id: cartItem.id,
      productId: cartItem.productId,
      productName: cartItem.productName,
      origin: cartItem.origin,
      size: cartItem.sizeVariant?.name ?? '250g Bag',
      grind: cartItem.grindVariant?.name ?? 'Whole Bean',
      unitPrice: cartItem.unitPrice,
      quantity: cartItem.quantity,
      totalPrice: cartItem.totalPrice,
      notes: cartItem.specialInstructions,
    );
  }

  OrderItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? origin,
    String? size,
    String? grind,
    double? unitPrice,
    int? quantity,
    double? totalPrice,
    String? notes,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      origin: origin ?? this.origin,
      size: size ?? this.size,
      grind: grind ?? this.grind,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
    );
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: (json['id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      origin: (json['origin'] ?? '').toString(),
      size: json['size']?.toString(),
      grind: json['grind']?.toString(),
      unitPrice: ((json['unit_price'] ?? 0.0) as num).toDouble(),
      quantity: (json['quantity'] ?? 1) as int,
      totalPrice: ((json['total_price'] ?? 0.0) as num).toDouble(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'origin': origin,
      if (size != null) 'size': size,
      if (grind != null) 'grind': grind,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        origin,
        size,
        grind,
        unitPrice,
        quantity,
        totalPrice,
        notes,
      ];
}
