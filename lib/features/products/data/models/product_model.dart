import 'package:equatable/equatable.dart';
import 'product_variant_model.dart';

/// Product Availability Status
enum ProductAvailability {
  available,
  lowStock,
  outOfStock;

  static ProductAvailability fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'low_stock' || 'lowstock' || 'limited' => ProductAvailability.lowStock,
      'out_of_stock' || 'sold_out' || 'unavailable' => ProductAvailability.outOfStock,
      _ => ProductAvailability.available,
    };
  }

  String toFormattedString() {
    return switch (this) {
      ProductAvailability.available => 'In Stock',
      ProductAvailability.lowStock => 'Limited Batch',
      ProductAvailability.outOfStock => 'Sold Out',
    };
  }

  bool get isOrderable => this != ProductAvailability.outOfStock;
}

/// Customer Catalog Visibility Mode for Disabled Products
enum ProductVisibility {
  visible,
  hidden;

  static ProductVisibility fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'hidden' || 'hide' => ProductVisibility.hidden,
      _ => ProductVisibility.visible,
    };
  }

  String toFormattedString() {
    return switch (this) {
      ProductVisibility.visible => 'Visible',
      ProductVisibility.hidden => 'Hidden from Catalog',
    };
  }
}

/// Core Product Entity for Lambac Roastery
class ProductModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String origin;
  final String description;
  final double basePrice;
  final String? imageUrl;
  final String categoryId;
  final String categoryName;
  final String roastLevel;
  final String tastingNotes;
  final String? elevation;
  final String? process;
  final String? varietal;
  final bool isEnabled;
  final ProductVisibility customerVisibility;
  final ProductAvailability availability;
  final int stockQuantity;
  final List<ProductVariantModel> sizeVariants;
  final List<ProductVariantModel> grindVariants;
  final bool isFeatured;
  final bool isFavorite;
  final double rating;
  final int reviewCount;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.origin,
    required this.description,
    required this.basePrice,
    this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.roastLevel,
    required this.tastingNotes,
    this.elevation,
    this.process,
    this.varietal,
    this.isEnabled = true,
    this.customerVisibility = ProductVisibility.visible,
    this.availability = ProductAvailability.available,
    this.stockQuantity = 25,
    this.sizeVariants = const [],
    this.grindVariants = const [],
    this.isFeatured = false,
    this.isFavorite = false,
    this.rating = 4.9,
    this.reviewCount = 38,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawSizes = json['size_variants'] as List<dynamic>? ?? json['sizes'] as List<dynamic>? ?? [];
    final rawGrinds = json['grind_variants'] as List<dynamic>? ?? json['grinds'] as List<dynamic>? ?? [];

    final isEnabled = (json['is_enabled'] ?? json['isEnabled'] ?? true) as bool;
    final customerVisibility = ProductVisibility.fromString(
      json['customer_visibility']?.toString() ?? json['customerVisibility']?.toString() ?? json['visibility']?.toString(),
    );

    return ProductModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      origin: (json['origin'] ?? 'Single Origin').toString(),
      description: (json['description'] ?? '').toString(),
      basePrice: ((json['price'] ?? json['base_price'] ?? 0.0) as num).toDouble(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      categoryId: (json['category_id'] ?? json['categoryId'] ?? 'coffee').toString(),
      categoryName: (json['category_name'] ?? json['category'] ?? 'Coffee').toString(),
      roastLevel: (json['roast_level'] ?? json['roast'] ?? 'Medium Roast').toString(),
      tastingNotes: (json['tasting_notes'] ?? json['flavor_notes'] ?? '').toString(),
      elevation: json['elevation']?.toString(),
      process: json['process']?.toString(),
      varietal: json['varietal']?.toString(),
      isEnabled: isEnabled,
      customerVisibility: customerVisibility,
      availability: ProductAvailability.fromString(json['availability']?.toString()),
      stockQuantity: (json['stock_quantity'] ?? json['stock'] ?? 20) as int,
      sizeVariants: rawSizes.map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>)).toList(),
      grindVariants: rawGrinds.map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>)).toList(),
      isFeatured: (json['is_featured'] ?? json['featured'] ?? false) as bool,
      isFavorite: (json['is_favorite'] ?? json['favorite'] ?? false) as bool,
      rating: ((json['rating'] ?? 4.9) as num).toDouble(),
      reviewCount: (json['review_count'] ?? json['reviews'] ?? 30) as int,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'origin': origin,
      'description': description,
      'price': basePrice,
      if (imageUrl != null) 'image_url': imageUrl,
      'category_id': categoryId,
      'category_name': categoryName,
      'roast_level': roastLevel,
      'tasting_notes': tastingNotes,
      if (elevation != null) 'elevation': elevation,
      if (process != null) 'process': process,
      if (varietal != null) 'varietal': varietal,
      'is_enabled': isEnabled,
      'customer_visibility': customerVisibility.name,
      'availability': availability.name,
      'stock_quantity': stockQuantity,
      'size_variants': sizeVariants.map((e) => e.toJson()).toList(),
      'grind_variants': grindVariants.map((e) => e.toJson()).toList(),
      'is_featured': isFeatured,
      'is_favorite': isFavorite,
      'rating': rating,
      'review_count': reviewCount,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? origin,
    String? description,
    double? basePrice,
    String? imageUrl,
    String? categoryId,
    String? categoryName,
    String? roastLevel,
    String? tastingNotes,
    String? elevation,
    String? process,
    String? varietal,
    bool? isEnabled,
    ProductVisibility? customerVisibility,
    ProductAvailability? availability,
    int? stockQuantity,
    List<ProductVariantModel>? sizeVariants,
    List<ProductVariantModel>? grindVariants,
    bool? isFeatured,
    bool? isFavorite,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      origin: origin ?? this.origin,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      roastLevel: roastLevel ?? this.roastLevel,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      elevation: elevation ?? this.elevation,
      process: process ?? this.process,
      varietal: varietal ?? this.varietal,
      isEnabled: isEnabled ?? this.isEnabled,
      customerVisibility: customerVisibility ?? this.customerVisibility,
      availability: availability ?? this.availability,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      sizeVariants: sizeVariants ?? this.sizeVariants,
      grindVariants: grindVariants ?? this.grindVariants,
      isFeatured: isFeatured ?? this.isFeatured,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// True if customer catalog can display this product
  bool get isVisibleToCustomer => customerVisibility == ProductVisibility.visible;

  /// True if the customer can add to cart and purchase this product
  bool get isOrderable => isEnabled && availability.isOrderable && stockQuantity > 0;

  /// True if product is marked as Sold Out (visible but non-purchasable)
  bool get isSoldOut => (!isEnabled && customerVisibility == ProductVisibility.visible) || availability == ProductAvailability.outOfStock || stockQuantity <= 0;

  /// True if product is completely hidden from customer catalog
  bool get isHidden => !isEnabled && customerVisibility == ProductVisibility.hidden;

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        origin,
        description,
        basePrice,
        imageUrl,
        categoryId,
        categoryName,
        roastLevel,
        tastingNotes,
        elevation,
        process,
        varietal,
        isEnabled,
        customerVisibility,
        availability,
        stockQuantity,
        sizeVariants,
        grindVariants,
        isFeatured,
        isFavorite,
        rating,
        reviewCount,
        createdAt,
      ];
}
