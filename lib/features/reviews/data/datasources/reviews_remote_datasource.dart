import 'dart:async';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../models/create_review_request.dart';
import '../models/product_review_model.dart';

/// Contract for Remote Product Reviews & Moderation API
abstract class ReviewsRemoteDataSource {
  Future<Result<List<ProductReviewModel>, AppFailure>> getProductReviews(
    String productId, {
    int limit = 20,
    dynamic lastDocument,
  });

  Future<Result<ProductReviewModel, AppFailure>> submitReview(CreateReviewRequest request);

  Future<Result<bool, AppFailure>> checkReviewEligibility(String productId);

  Future<Result<ProductReviewModel, AppFailure>> flagReview(String reviewId);

  Future<Result<List<ProductReviewModel>, AppFailure>> getAllReviews({
    bool includeFlagged = true,
  });

  Stream<List<ProductReviewModel>> watchAllReviews({
    bool includeFlagged = true,
  });
}

/// Concrete Dio-based implementation
class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  final ApiClient _apiClient;

  ReviewsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<List<ProductReviewModel>, AppFailure>> getProductReviews(
    String productId, {
    int limit = 20,
    dynamic lastDocument,
  }) {
    return _apiClient.get(
      '/products/$productId/reviews',
      queryParameters: {'limit': limit},
      decoder: (data) {
        final list = data is List ? data : (data['reviews'] ?? data['data']) as List;
        return list.map((item) => ProductReviewModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<Result<ProductReviewModel, AppFailure>> submitReview(CreateReviewRequest request) {
    return _apiClient.post(
      '/products/${request.productId}/reviews',
      data: request.toJson(),
      requiresAuth: true,
      decoder: (data) => ProductReviewModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<bool, AppFailure>> checkReviewEligibility(String productId) {
    return _apiClient.get(
      '/products/$productId/review-eligibility',
      requiresAuth: true,
      decoder: (data) => (data['is_eligible'] ?? false) as bool,
    );
  }

  @override
  Future<Result<ProductReviewModel, AppFailure>> flagReview(String reviewId) {
    return _apiClient.post(
      '/reviews/$reviewId/flag',
      requiresAuth: true,
      decoder: (data) => ProductReviewModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<List<ProductReviewModel>, AppFailure>> getAllReviews({
    bool includeFlagged = true,
  }) {
    return _apiClient.get(
      '/reviews',
      queryParameters: {'include_flagged': includeFlagged},
      decoder: (data) {
        final list = data is List ? data : (data['reviews'] ?? data['data']) as List;
        return list.map((item) => ProductReviewModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Stream<List<ProductReviewModel>> watchAllReviews({
    bool includeFlagged = true,
  }) {
    return Stream.fromFuture(
      getAllReviews(includeFlagged: includeFlagged).then((res) => res.dataOrNull ?? []),
    );
  }
}
