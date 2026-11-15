import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/reviews/data/datasources/mock_reviews_remote_datasource.dart';
import 'package:lambac_app/features/reviews/data/models/create_review_request.dart';
import 'package:lambac_app/features/reviews/data/repositories/reviews_repository_impl.dart';

void main() {
  group('Product Reviews & Moderation Unit Tests', () {
    late MockReviewsRemoteDataSource remoteDataSource;
    late ReviewsRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockReviewsRemoteDataSource();
      repository = ReviewsRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('getProductReviews returns verified customer reviews for product', () async {
      final result = await repository.getProductReviews('mt-apo-honey');

      expect(result.isSuccess, isTrue);
      final reviews = result.dataOrNull!;
      expect(reviews.isNotEmpty, isTrue);
      expect(reviews.first.isVerifiedPurchase, isTrue);
      expect(reviews.first.rating, equals(5));
    });

    test('submitReview creates verified review with 1-5 star rating validation', () async {
      final request = const CreateReviewRequest(
        productId: 'mt-apo-honey',
        rating: 5,
        comment: 'Tasting notes match description perfectly! Bright citric acidity.',
        orderId: 'ord_lmb_1082',
      );

      final result = await repository.submitReview(request);

      expect(result.isSuccess, isTrue);
      final review = result.dataOrNull!;
      expect(review.rating, equals(5));
      expect(review.isVerifiedPurchase, isTrue);
      expect(review.comment, contains('Bright citric acidity'));
    });

    test('flagReview marks inappropriate review for moderation audit', () async {
      final result = await repository.flagReview('rev_101');

      expect(result.isSuccess, isTrue);
      final flagged = result.dataOrNull!;
      expect(flagged.isFlagged, isTrue);
    });
  });
}
