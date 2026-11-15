import 'package:equatable/equatable.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';

/// Cart Line Item with immutable variant snapshot and quantity
class CartItemModel extends Equatable {
  final String id; // Unique composite key: productId_sizeId_grindId
  final String productId;
  final String productName;
  final String origin;
  final String roastLevel;
  final String? imageUrl;
  final ProductVariantModel? sizeVariant;
  final ProductVariantModel? grindVariant;
  final double unitPrice;
  final int quantity;
  final String? specialInstructions;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.origin,
    required this.roastLevel,
    this.imageUrl,
    this.sizeVariant,
    this.grindVariant,
    required this.unitPrice,
    this.quantity = 1,
    this.specialInstructions,
  });

  /// Factory helper to build from a ProductModel and selected options
  factory CartItemModel.fromProduct({
    required ProductModel product,
    ProductVariantModel? sizeVariant,
    ProductVariantModel? grindVariant,
    int quantity = 1,
    String? specialInstructions,
  }) {
    final sizeId = sizeVariant?.id ?? 'default_size';
    final grindId = grindVariant?.id ?? 'default_grind';
    final compositeId = '${product.id}_${sizeId}_$grindId';

    final sizeDelta = sizeVariant?.priceDelta ?? 0.0;
    final grindDelta = grindVariant?.priceDelta ?? 0.0;
    final unitPrice = product.basePrice + sizeDelta + grindDelta;

    return CartItemModel(
      id: compositeId,
      productId: product.id,
      productName: product.name,
      origin: product.origin,
      roastLevel: product.roastLevel,
      imageUrl: product.imageUrl,
      sizeVariant: sizeVariant,
      grindVariant: grindVariant,
      unitPrice: unitPrice,
      quantity: quantity,
      specialInstructions: specialInstructions,
    );
  }

  double get totalPrice => unitPrice * quantity;

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? origin,
    String? roastLevel,
    String? imageUrl,
    ProductVariantModel? sizeVariant,
    ProductVariantModel? grindVariant,
    double? unitPrice,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      origin: origin ?? this.origin,
      roastLevel: roastLevel ?? this.roastLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      sizeVariant: sizeVariant ?? this.sizeVariant,
      grindVariant: grindVariant ?? this.grindVariant,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: (json['id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      origin: (json['origin'] ?? '').toString(),
      roastLevel: (json['roast_level'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      sizeVariant: json['size_variant'] != null
          ? ProductVariantModel.fromJson(json['size_variant'] as Map<String, dynamic>)
          : null,
      grindVariant: json['grind_variant'] != null
          ? ProductVariantModel.fromJson(json['grind_variant'] as Map<String, dynamic>)
          : null,
      unitPrice: ((json['unit_price'] ?? 0.0) as num).toDouble(),
      quantity: (json['quantity'] ?? 1) as int,
      specialInstructions: json['special_instructions']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'origin': origin,
      'roast_level': roastLevel,
      if (imageUrl != null) 'image_url': imageUrl,
      if (sizeVariant != null) 'size_variant': sizeVariant!.toJson(),
      if (grindVariant != null) 'grind_variant': grindVariant!.toJson(),
      'unit_price': unitPrice,
      'quantity': quantity,
      if (specialInstructions != null) 'special_instructions': specialInstructions,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        origin,
        roastLevel,
        imageUrl,
        sizeVariant,
        grindVariant,
        unitPrice,
        quantity,
        specialInstructions,
      ];
}
