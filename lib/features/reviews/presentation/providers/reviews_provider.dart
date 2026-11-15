import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_reviews_remote_datasource.dart';
import '../../data/datasources/reviews_remote_datasource.dart';
import '../../data/models/customer_satisfaction_summary.dart';
import '../../data/models/product_review_model.dart';
import '../../data/repositories/reviews_repository_impl.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';

/// Provider for Reviews Remote Data Source (Cloud Firestore Production Data Source)
final reviewsRemoteDataSourceProvider = Provider<ReviewsRemoteDataSource>((ref) {
  return FirebaseReviewsRemoteDataSource();
});

/// Provider for ReviewsRepository
final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  final remoteDataSource = ref.watch(reviewsRemoteDataSourceProvider);
  return ReviewsRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// FutureProvider for Product Reviews list by Product ID
final productReviewsProvider = FutureProvider.family<List<ProductReviewModel>, String>((ref, productId) async {
  final repository = ref.watch(reviewsRepositoryProvider);
  final result = await repository.getProductReviews(productId);

  return result.when(
    success: (list) => list,
    failure: (failure) => throw Exception(failure.message),
  );
});

/// FutureProvider checking Verified Purchase Review Eligibility
final reviewEligibilityProvider = FutureProvider.family<bool, String>((ref, productId) async {
  final repository = ref.watch(reviewsRepositoryProvider);
  final result = await repository.checkReviewEligibility(productId);

  return result.when(
    success: (isEligible) => isEligible,
    failure: (_) => false,
  );
});

/// Realtime StreamProvider watching all reviews across the roastery catalog
final allReviewsStreamProvider = StreamProvider<List<ProductReviewModel>>((ref) {
  final repository = ref.watch(reviewsRepositoryProvider);
  return repository.watchAllReviews(includeFlagged: true);
});

/// Reactive Customer Satisfaction & Review Analytics Provider
final customerSatisfactionProvider = Provider<AsyncValue<CustomerSatisfactionSummary>>((ref) {
  final reviewsAsync = ref.watch(allReviewsStreamProvider);
  final dateRangeLabel = ref.watch(analyticsDateRangeProvider);
  final productsState = ref.watch(productsNotifierProvider);

  // Build lookup map for product names from the active catalog
  final Map<String, String> productNames = {
    for (final p in productsState.products) p.id: p.name,
  };

  return reviewsAsync.when(
    data: (allReviews) {
      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: allReviews,
        dateRangeLabel: dateRangeLabel,
        productNames: productNames,
      );
      return AsyncValue.data(summary);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
  );
});
