import 'dart:async';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../models/create_review_request.dart';
import '../models/product_review_model.dart';
import 'reviews_remote_datasource.dart';

/// Offline Mock Data Source for Product Reviews & Moderation
class MockReviewsRemoteDataSource implements ReviewsRemoteDataSource {
  final List<ProductReviewModel> _reviews;
  final StreamController<List<ProductReviewModel>> _streamController =
      StreamController<List<ProductReviewModel>>.broadcast();

  MockReviewsRemoteDataSource({List<ProductReviewModel>? initialReviews})
      : _reviews = initialReviews != null
            ? List<ProductReviewModel>.from(initialReviews)
            : [
                ProductReviewModel(
                  id: 'rev_101',
                  productId: 'mt-apo-honey',
                  customerId: 'usr_cust_1',
                  customerName: 'Kenji Takahashi',
                  rating: 5,
                  comment:
                      'Incredible anaerobic honey processing! Floral jasmine aroma with distinct wild berry acidity and honey sweetness.',
                  isVerifiedPurchase: true,
                  orderId: 'ord_lmb_1082',
                  createdAt: DateTime.now().subtract(const Duration(days: 2)),
                ),
                ProductReviewModel(
                  id: 'rev_102',
                  productId: 'tokyo-blend',
                  customerId: 'usr_cust_2',
                  customerName: 'Maria Santos',
                  rating: 5,
                  comment:
                      'Rich dark chocolate notes with zero bitterness. Perfect for morning espresso shot pull.',
                  isVerifiedPurchase: true,
                  orderId: 'ord_lmb_1080',
                  createdAt: DateTime.now().subtract(const Duration(days: 5)),
                ),
              ];

  void resetForTesting([List<ProductReviewModel>? reviews]) {
    _reviews.clear();
    if (reviews != null) {
      _reviews.addAll(reviews);
    }
    _notify();
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_reviews));
    }
  }

  @override
  Future<Result<List<ProductReviewModel>, AppFailure>> getProductReviews(
    String productId, {
    int limit = 20,
    dynamic lastDocument,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final filtered = _reviews.where((r) => r.productId == productId && !r.isFlagged).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int startIndex = 0;
    if (lastDocument is String) {
      final idx = filtered.indexWhere((r) => r.id == lastDocument);
      if (idx != -1) startIndex = idx + 1;
    }
    final endIndex = (startIndex + limit) > filtered.length ? filtered.length : startIndex + limit;
    final paged = startIndex < filtered.length ? filtered.sublist(startIndex, endIndex) : <ProductReviewModel>[];
    return Result.success(List.unmodifiable(paged));
  }

  @override
  Future<Result<ProductReviewModel, AppFailure>> submitReview(CreateReviewRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final newReview = ProductReviewModel(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      productId: request.productId,
      customerId: 'usr_mock_author',
      customerName: 'Verified Roastery Buyer',
      rating: request.rating.clamp(1, 5),
      comment: request.comment,
      isVerifiedPurchase: true,
      orderId: request.orderId ?? 'ord_lmb_1082',
      createdAt: DateTime.now(),
    );

    _reviews.insert(0, newReview);
    _notify();
    return Result.success(newReview);
  }

  @override
  Future<Result<bool, AppFailure>> checkReviewEligibility(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return const Result.success(true);
  }

  @override
  Future<Result<ProductReviewModel, AppFailure>> flagReview(String reviewId) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final idx = _reviews.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      _reviews[idx] = _reviews[idx].copyWith(isFlagged: true);
      _notify();
      return Result.success(_reviews[idx]);
    }
    return const Result.failure(NotFoundFailure(message: 'Review not found.'));
  }

  @override
  Future<Result<List<ProductReviewModel>, AppFailure>> getAllReviews({
    bool includeFlagged = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final result = includeFlagged ? _reviews : _reviews.where((r) => !r.isFlagged).toList();
    return Result.success(List.unmodifiable(result));
  }

  @override
  Stream<List<ProductReviewModel>> watchAllReviews({
    bool includeFlagged = true,
  }) async* {
    final initial = includeFlagged ? _reviews : _reviews.where((r) => !r.isFlagged).toList();
    yield List.unmodifiable(initial);

    yield* _streamController.stream.map((list) {
      return includeFlagged ? list : list.where((r) => !r.isFlagged).toList();
    });
  }
}
