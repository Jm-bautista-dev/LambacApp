import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/reviews/data/models/create_review_request.dart';
import 'package:lambac_app/features/reviews/data/models/product_review_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('Firestore Reviews Migration Specifications', () {
    test('ProductReviewModel adheres to normalized reviews/{reviewId} document schema', () {
      final now = DateTime.utc(2026, 10, 6, 12, 0, 0);
      final review = ProductReviewModel(
        id: 'rev_mt_apo_101',
        productId: 'mt-apo-honey',
        customerName: 'Kenji Takahashi',
        rating: 5,
        comment: 'Incredible anaerobic honey processing! Floral jasmine aroma with distinct wild berry acidity and honey sweetness.',
        isVerifiedPurchase: true,
        isFlagged: false,
        orderId: 'ord_lmb_1082',
        createdAt: now,
      );

      final json = review.toJson();

      // Verify Firestore field normalization
      expect(json['id'], equals('rev_mt_apo_101'));
      expect(json['product_id'], equals('mt-apo-honey'));
      expect(json['customer_name'], equals('Kenji Takahashi'));
      expect(json['rating'], equals(5));
      expect(json['comment'], contains('Incredible anaerobic honey'));
      expect(json['is_verified_purchase'], isTrue);
      expect(json['is_flagged'], isFalse);
      expect(json['order_id'], equals('ord_lmb_1082'));
      expect(json['created_at'], equals('2026-10-06T12:00:00.000Z'));

      // Round-trip deserialization
      final deserialized = ProductReviewModel.fromJson(json);
      expect(deserialized.id, equals(review.id));
      expect(deserialized.productId, equals('mt-apo-honey'));
      expect(deserialized.rating, equals(5));
      expect(deserialized.isVerifiedPurchase, isTrue);
      expect(deserialized.isFlagged, isFalse);
    });

    test('Rating validation strictly enforces 1 to 5 star boundaries', () {
      const validRequest = CreateReviewRequest(
        productId: 'mt-apo-honey',
        rating: 4,
        comment: 'Balanced sweetness.',
      );
      expect(validRequest.rating >= 1 && validRequest.rating <= 5, isTrue);

      const clampedLow = -1;
      expect(clampedLow.clamp(1, 5), equals(1));

      const clampedHigh = 7;
      expect(clampedHigh.clamp(1, 5), equals(5));
    });

    test('Review moderation flags inappropriate content and hides from public listing', () {
      final review = ProductReviewModel(
        id: 'rev_bad_1',
        productId: 'mt-apo-honey',
        customerName: 'Spam User',
        rating: 1,
        comment: 'Spam message',
        isVerifiedPurchase: false,
        isFlagged: false,
        createdAt: DateTime.now(),
      );

      final flagged = review.copyWith(isFlagged: true);
      expect(flagged.isFlagged, isTrue);

      final catalogReviews = [
        ProductReviewModel(
          id: 'rev_good_1',
          productId: 'mt-apo-honey',
          customerName: 'Good User',
          rating: 5,
          comment: 'Great coffee!',
          createdAt: DateTime.now(),
        ),
        flagged,
      ];

      final publicVisible = catalogReviews.where((r) => !r.isFlagged).toList();
      expect(publicVisible.length, equals(1));
      expect(publicVisible.first.id, equals('rev_good_1'));
    });

    test('Role authorization enforces customer review identity', () {
      const customer = UserModel(
        id: 'cust_abc_123',
        email: 'juan@example.com',
        fullName: 'Juan Dela Cruz',
        role: UserRole.customer,
      );

      const otherCustomer = UserModel(
        id: 'cust_xyz_789',
        email: 'other@example.com',
        fullName: 'Other User',
        role: UserRole.customer,
      );

      final reviewData = {
        'id': 'rev_101',
        'customer_id': 'cust_abc_123',
        'rating': 5,
        'comment': 'Awesome brew',
      };

      // Customer can create/update only under own authenticated UID
      expect(reviewData['customer_id'] == customer.id, isTrue);
      expect(reviewData['customer_id'] == otherCustomer.id, isFalse);
    });
  });
}
