import 'package:equatable/equatable.dart';

/// Product Variant Model (Size, Grind, Format)
class ProductVariantModel extends Equatable {
  final String id;
  final String name;
  final String type; // 'size' or 'grind' or 'roast'
  final double priceDelta;
  final bool isDefault;
  final bool inStock;

  const ProductVariantModel({
    required this.id,
    required this.name,
    this.type = 'size',
    this.priceDelta = 0.0,
    this.isDefault = false,
    this.inStock = true,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'size').toString(),
      priceDelta: ((json['price_delta'] ?? json['priceAdjustment'] ?? 0.0) as num).toDouble(),
      isDefault: (json['is_default'] ?? json['isDefault'] ?? false) as bool,
      inStock: (json['in_stock'] ?? json['inStock'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price_delta': priceDelta,
      'is_default': isDefault,
      'in_stock': inStock,
    };
  }

  @override
  List<Object?> get props => [id, name, type, priceDelta, isDefault, inStock];
}
