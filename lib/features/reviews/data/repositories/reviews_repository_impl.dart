import 'dart:async';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_remote_datasource.dart';
import '../models/create_review_request.dart';
import '../models/product_review_model.dart';

/// Concrete ReviewsRepository implementation
class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsRemoteDataSource _remoteDataSource;

  ReviewsRepositoryImpl({required ReviewsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<List<ProductReviewModel>, AppFailure>> getProductReviews(
    String productId, {
    int limit = 20,
    dynamic lastDocument,
  }) {
    return _remoteDataSource.getProductReviews(
      productId,
      limit: limit,
      lastDocument: lastDocument,
    );
  }

  @override
  Future<Result<ProductReviewModel, AppFailure>> submitReview(CreateReviewRequest request) {
    return _remoteDataSource.submitReview(request);
  }

  @override
  Future<Result<bool, AppFailure>> checkReviewEligibility(String productId) {
    return _remoteDataSource.checkReviewEligibility(productId);
  }

  @override
  Future<Result<ProductReviewModel, AppFailure>> flagReview(String reviewId) {
    return _remoteDataSource.flagReview(reviewId);
  }

  @override
  Future<Result<List<ProductReviewModel>, AppFailure>> getAllReviews({
    bool includeFlagged = true,
  }) {
    return _remoteDataSource.getAllReviews(includeFlagged: includeFlagged);
  }

  @override
  Stream<List<ProductReviewModel>> watchAllReviews({
    bool includeFlagged = true,
  }) {
    return _remoteDataSource.watchAllReviews(includeFlagged: includeFlagged);
  }
}
