import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../data/models/create_review_request.dart';
import '../../data/models/product_review_model.dart';

abstract class ReviewsRepository {
  Future<Result<List<ProductReviewModel>, AppFailure>> getProductReviews(
    String productId, {
    int limit = 20,
    dynamic lastDocument,
  });

  Future<Result<ProductReviewModel, AppFailure>> submitReview(CreateReviewRequest request);

  Future<Result<bool, AppFailure>> checkReviewEligibility(String productId);

  Future<Result<ProductReviewModel, AppFailure>> flagReview(String reviewId);

  /// Fetch all reviews across the catalog for executive satisfaction analytics
  Future<Result<List<ProductReviewModel>, AppFailure>> getAllReviews({
    bool includeFlagged = true,
  });

  /// Live Firestore stream of all reviews for reactive dashboard updates
  Stream<List<ProductReviewModel>> watchAllReviews({
    bool includeFlagged = true,
  });
}
