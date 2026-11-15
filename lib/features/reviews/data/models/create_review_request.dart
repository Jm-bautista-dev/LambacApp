/// Payload DTO for submitting a product review
class CreateReviewRequest {
  final String productId;
  final int rating; // 1 to 5
  final String comment;
  final String? orderId;

  const CreateReviewRequest({
    required this.productId,
    required this.rating,
    required this.comment,
    this.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'rating': rating,
      'comment': comment.trim(),
      if (orderId != null) 'order_id': orderId,
    };
  }
}
