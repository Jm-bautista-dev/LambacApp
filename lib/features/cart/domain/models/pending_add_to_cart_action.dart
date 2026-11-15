import 'package:equatable/equatable.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';

/// Secure in-memory representation of an intended cart addition awaiting customer authentication
class PendingAddToCartAction extends Equatable {
  final ProductModel product;
  final ProductVariantModel? sizeVariant;
  final ProductVariantModel? grindVariant;
  final int quantity;
  final String? specialInstructions;
  final DateTime timestamp;

  PendingAddToCartAction({
    required this.product,
    this.sizeVariant,
    this.grindVariant,
    this.quantity = 1,
    this.specialInstructions,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [
        product,
        sizeVariant,
        grindVariant,
        quantity,
        specialInstructions,
        timestamp,
      ];
}
