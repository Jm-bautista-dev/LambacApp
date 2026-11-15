import 'package:equatable/equatable.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';

/// POS Line Item Model with real-time price monitoring and availability status
class PosCartItemModel extends Equatable {
  final String id; // Unique composite key: productId_sizeId_grindId
  final ProductModel product;
  final ProductVariantModel? sizeVariant;
  final ProductVariantModel? grindVariant;
  final double capturedUnitPrice; // Unit price when added to cart
  final int quantity;
  final String? notes;

  // Real-time synchronization flags (computed against authoritative catalog)
  final double currentLiveUnitPrice;
  final bool isPriceStale;
  final bool isUnavailable;
  final String? unavailabilityReason;

  const PosCartItemModel({
    required this.id,
    required this.product,
    this.sizeVariant,
    this.grindVariant,
    required this.capturedUnitPrice,
    this.quantity = 1,
    this.notes,
    required this.currentLiveUnitPrice,
    this.isPriceStale = false,
    this.isUnavailable = false,
    this.unavailabilityReason,
  });

  factory PosCartItemModel.fromProduct({
    required ProductModel product,
    ProductVariantModel? sizeVariant,
    ProductVariantModel? grindVariant,
    int quantity = 1,
    String? notes,
  }) {
    final sizeId = sizeVariant?.id ?? 'default_size';
    final grindId = grindVariant?.id ?? 'default_grind';
    final compositeId = '${product.id}_${sizeId}_$grindId';

    final sizeDelta = sizeVariant?.priceDelta ?? 0.0;
    final grindDelta = grindVariant?.priceDelta ?? 0.0;
    final unitPrice = product.basePrice + sizeDelta + grindDelta;

    final isSoldOut = product.isSoldOut || !product.isEnabled;

    return PosCartItemModel(
      id: compositeId,
      product: product,
      sizeVariant: sizeVariant,
      grindVariant: grindVariant,
      capturedUnitPrice: unitPrice,
      currentLiveUnitPrice: unitPrice,
      quantity: quantity,
      notes: notes,
      isPriceStale: false,
      isUnavailable: isSoldOut,
      unavailabilityReason: isSoldOut ? 'Product is currently sold out or disabled' : null,
    );
  }

  /// Recalculates stale price and availability against latest live product from Firestore stream
  PosCartItemModel syncWithLiveProduct(ProductModel? liveProduct) {
    if (liveProduct == null) {
      return copyWith(
        isUnavailable: true,
        unavailabilityReason: 'Product removed from catalog',
      );
    }

    final sizeDelta = sizeVariant?.priceDelta ?? 0.0;
    final grindDelta = grindVariant?.priceDelta ?? 0.0;
    final liveUnitPrice = liveProduct.basePrice + sizeDelta + grindDelta;
    final priceChanged = (liveUnitPrice - capturedUnitPrice).abs() > 0.001;

    final isNowUnavailable = !liveProduct.isEnabled ||
        liveProduct.isSoldOut ||
        liveProduct.stockQuantity < quantity;

    String? reason;
    if (!liveProduct.isEnabled) {
      reason = 'Product was disabled by Administrator';
    } else if (liveProduct.isSoldOut || liveProduct.stockQuantity <= 0) {
      reason = 'Product is sold out';
    } else if (liveProduct.stockQuantity < quantity) {
      reason = 'Only ${liveProduct.stockQuantity} units remaining in inventory';
    }

    return copyWith(
      product: liveProduct,
      currentLiveUnitPrice: liveUnitPrice,
      isPriceStale: priceChanged,
      isUnavailable: isNowUnavailable,
      unavailabilityReason: reason,
    );
  }

  /// Accept updated live price
  PosCartItemModel acceptLivePrice() {
    return copyWith(
      capturedUnitPrice: currentLiveUnitPrice,
      isPriceStale: false,
    );
  }

  double get lineTotal => capturedUnitPrice * quantity;
  double get liveLineTotal => currentLiveUnitPrice * quantity;

  PosCartItemModel copyWith({
    String? id,
    ProductModel? product,
    ProductVariantModel? sizeVariant,
    ProductVariantModel? grindVariant,
    double? capturedUnitPrice,
    int? quantity,
    String? notes,
    double? currentLiveUnitPrice,
    bool? isPriceStale,
    bool? isUnavailable,
    String? unavailabilityReason,
  }) {
    return PosCartItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      sizeVariant: sizeVariant ?? this.sizeVariant,
      grindVariant: grindVariant ?? this.grindVariant,
      capturedUnitPrice: capturedUnitPrice ?? this.capturedUnitPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      currentLiveUnitPrice: currentLiveUnitPrice ?? this.currentLiveUnitPrice,
      isPriceStale: isPriceStale ?? this.isPriceStale,
      isUnavailable: isUnavailable ?? this.isUnavailable,
      unavailabilityReason: unavailabilityReason ?? this.unavailabilityReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        product,
        sizeVariant,
        grindVariant,
        capturedUnitPrice,
        quantity,
        notes,
        currentLiveUnitPrice,
        isPriceStale,
        isUnavailable,
        unavailabilityReason,
      ];
}
