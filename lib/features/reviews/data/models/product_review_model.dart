import 'package:equatable/equatable.dart';

/// Customer Product Review Entity with Verified Purchase Badge
class ProductReviewModel extends Equatable {
  final String id;
  final String productId;
  final String? customerId;
  final String customerName;
  final String? productName;
  final int rating; // 1 to 5 stars
  final String comment;
  final bool isVerifiedPurchase;
  final bool isFlagged;
  final String? orderId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductReviewModel({
    required this.id,
    required this.productId,
    this.customerId,
    required this.customerName,
    this.productName,
    required this.rating,
    required this.comment,
    this.isVerifiedPurchase = true,
    this.isFlagged = false,
    this.orderId,
    required this.createdAt,
    this.updatedAt,
  });

  ProductReviewModel copyWith({
    String? id,
    String? productId,
    String? customerId,
    String? customerName,
    String? productName,
    int? rating,
    String? comment,
    bool? isVerifiedPurchase,
    bool? isFlagged,
    String? orderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      productName: productName ?? this.productName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      isFlagged: isFlagged ?? this.isFlagged,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      id: (json['id'] ?? '').toString(),
      productId: (json['product_id'] ?? json['productId'] ?? '').toString(),
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString(),
      customerName: (json['customer_name'] ?? json['customerName'] ?? 'Roastery Customer').toString(),
      productName: json['product_name']?.toString() ?? json['productName']?.toString(),
      rating: (json['rating'] ?? 5) as int,
      comment: (json['comment'] ?? '').toString(),
      isVerifiedPurchase: (json['is_verified_purchase'] ?? json['isVerifiedPurchase'] ?? true) as bool,
      isFlagged: (json['is_flagged'] ?? json['isFlagged'] ?? false) as bool,
      orderId: (json['order_id'] ?? json['orderId'])?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : (json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      if (customerId != null) 'customer_id': customerId,
      'customer_name': customerName,
      if (productName != null) 'product_name': productName,
      'rating': rating,
      'comment': comment,
      'is_verified_purchase': isVerifiedPurchase,
      'is_flagged': isFlagged,
      if (orderId != null) 'order_id': orderId,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        customerId,
        customerName,
        productName,
        rating,
        comment,
        isVerifiedPurchase,
        isFlagged,
        orderId,
        createdAt,
        updatedAt,
      ];
}
