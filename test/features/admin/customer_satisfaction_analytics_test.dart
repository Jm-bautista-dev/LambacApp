import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/executive_customer_feedback_card.dart';
import 'package:lambac_app/features/reviews/data/datasources/mock_reviews_remote_datasource.dart';
import 'package:lambac_app/features/reviews/data/models/create_review_request.dart';
import 'package:lambac_app/features/reviews/data/models/customer_satisfaction_summary.dart';
import 'package:lambac_app/features/reviews/data/models/product_review_model.dart';
import 'package:lambac_app/features/reviews/data/repositories/reviews_repository_impl.dart';
import 'package:lambac_app/features/reviews/presentation/providers/reviews_provider.dart';

void main() {
  final now = DateTime.utc(2026, 11, 10, 10, 0, 0); // Reference time (Manila UTC+8)

  group('PRODUCTION FIX 05 — Customer Satisfaction & Review Analytics Suite', () {
    // -------------------------------------------------------------------------
    // Test 1: No review documents
    // -------------------------------------------------------------------------
    test('1. No review documents: Yields 0 count, 0.0 avg, and clean empty state', () {
      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: const [],
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      expect(summary.totalReviews, equals(0));
      expect(summary.averageRating, equals(0.0));
      expect(summary.positivePercent, equals(0.0));
      expect(summary.hasReviews, isFalse);
      expect(summary.hasFlaggedOnly, isFalse);
      expect(summary.recentReviews, isEmpty);
      expect(summary.starDistribution, equals({5: 0, 4: 0, 3: 0, 2: 0, 1: 0}));
      expect(summary.starPercentages, equals({5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0}));
    });

    // -------------------------------------------------------------------------
    // Test 2: One valid 5-star review
    // -------------------------------------------------------------------------
    test('2. One valid 5-star review: Correctly computes 5.0 avg, 100% positive, 1 review', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_001',
          productId: 'prod_benguet',
          customerId: 'cust_alice',
          customerName: 'Alice Guo',
          productName: 'Benguet Typica',
          rating: 5,
          comment: 'Outstanding clarity and honey sweetness!',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      expect(summary.totalReviews, equals(1));
      expect(summary.averageRating, equals(5.0));
      expect(summary.positivePercent, equals(100.0));
      expect(summary.hasReviews, isTrue);
      expect(summary.starDistribution[5], equals(1));
      expect(summary.starPercentages[5], equals(1.0));
      expect(summary.recentReviews.first.customerName, equals('Alice Guo'));
    });

    // -------------------------------------------------------------------------
    // Test 3: Multiple reviews with different ratings
    // -------------------------------------------------------------------------
    test('3. Multiple reviews with different ratings (5, 4, 3, 2, 1): Computes accurate distribution and average', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_1',
          productId: 'prod_1',
          customerId: 'cust_1',
          customerName: 'User 1',
          rating: 5,
          comment: 'Perfect roast!',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ProductReviewModel(
          id: 'rev_2',
          productId: 'prod_2',
          customerId: 'cust_2',
          customerName: 'User 2',
          rating: 4,
          comment: 'Very pleasant cup.',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        ProductReviewModel(
          id: 'rev_3',
          productId: 'prod_3',
          customerId: 'cust_3',
          customerName: 'User 3',
          rating: 3,
          comment: 'Average flavor profile.',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        ProductReviewModel(
          id: 'rev_4',
          productId: 'prod_4',
          customerId: 'cust_4',
          customerName: 'User 4',
          rating: 2,
          comment: 'Too bitter for my taste.',
          createdAt: now.subtract(const Duration(days: 4)),
        ),
        ProductReviewModel(
          id: 'rev_5',
          productId: 'prod_5',
          customerId: 'cust_5',
          customerName: 'User 5',
          rating: 1,
          comment: 'Under-extracted or burnt.',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      // (5 + 4 + 3 + 2 + 1) / 5 = 15 / 5 = 3.0
      expect(summary.totalReviews, equals(5));
      expect(summary.averageRating, equals(3.0));
      // Positive (4★ and 5★): 2 out of 5 = 40.0%
      expect(summary.positivePercent, equals(40.0));
      expect(summary.starDistribution, equals({5: 1, 4: 1, 3: 1, 2: 1, 1: 1}));
      expect(summary.starPercentages[5], equals(0.2));
      expect(summary.starPercentages[1], equals(0.2));
    });

    // -------------------------------------------------------------------------
    // Test 4: Multiple reviews for one product
    // -------------------------------------------------------------------------
    test('4. Multiple reviews for one product: Accurately pools ratings', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_apo_1',
          productId: 'mt-apo-honey',
          customerId: 'cust_a',
          customerName: 'Alice',
          rating: 5,
          comment: 'Floral and sweet.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ProductReviewModel(
          id: 'rev_apo_2',
          productId: 'mt-apo-honey',
          customerId: 'cust_b',
          customerName: 'Bob',
          rating: 5,
          comment: 'Super clean finish.',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        ProductReviewModel(
          id: 'rev_apo_3',
          productId: 'mt-apo-honey',
          customerId: 'cust_c',
          customerName: 'Charlie',
          rating: 4,
          comment: 'Good balance.',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      expect(summary.totalReviews, equals(3));
      // (5 + 5 + 4) / 3 = 14 / 3 = 4.666 -> 4.7
      expect(summary.averageRating, equals(4.7));
      expect(summary.positivePercent, equals(100.0));
    });

    // -------------------------------------------------------------------------
    // Test 5: Reviews across multiple products
    // -------------------------------------------------------------------------
    test('5. Reviews across multiple products: Pools catalog-wide metrics with mapped product names', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_p1',
          productId: 'prod_benguet',
          customerId: 'cust_1',
          customerName: 'Customer 1',
          rating: 5,
          comment: 'Best in Luzon.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ProductReviewModel(
          id: 'rev_p2',
          productId: 'prod_sagada',
          customerId: 'cust_2',
          customerName: 'Customer 2',
          rating: 4,
          comment: 'Rich body.',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final productNames = {
        'prod_benguet': 'Benguet Typica Roastery',
        'prod_sagada': 'Sagada Dark Roast',
      };

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
        productNames: productNames,
      );

      expect(summary.totalReviews, equals(2));
      expect(summary.recentReviews[0].productName, equals('Benguet Typica Roastery'));
      expect(summary.recentReviews[1].productName, equals('Sagada Dark Roast'));
    });

    // -------------------------------------------------------------------------
    // Test 6: Duplicate review documents
    // -------------------------------------------------------------------------
    test('6. Duplicate review documents: Deduplicates by id and by (customer, product) keeping latest', () {
      final olderTime = now.subtract(const Duration(days: 5));
      final newerTime = now.subtract(const Duration(days: 1));

      final reviews = [
        ProductReviewModel(
          id: 'rev_dup_1',
          productId: 'prod_espresso',
          customerId: 'cust_same',
          customerName: 'Same Customer',
          rating: 3,
          comment: 'Initial 3-star impression.',
          createdAt: olderTime,
        ),
        // Updated or duplicate submission with 5 stars
        ProductReviewModel(
          id: 'rev_dup_1',
          productId: 'prod_espresso',
          customerId: 'cust_same',
          customerName: 'Same Customer',
          rating: 5,
          comment: 'Revised to 5 stars!',
          createdAt: newerTime,
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      // Should count only once with the newer 5-star rating
      expect(summary.totalReviews, equals(1));
      expect(summary.averageRating, equals(5.0));
      expect(summary.recentReviews.first.comment, equals('Revised to 5 stars!'));
    });

    // -------------------------------------------------------------------------
    // Test 7: Flagged reviews
    // -------------------------------------------------------------------------
    test('7. Flagged reviews: Excluded from public rating, average, and positive percent', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_good',
          productId: 'prod_1',
          customerId: 'cust_good',
          customerName: 'Good Customer',
          rating: 5,
          comment: 'Wonderful coffee.',
          isFlagged: false,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ProductReviewModel(
          id: 'rev_inappropriate',
          productId: 'prod_1',
          customerId: 'cust_bad',
          customerName: 'Spam Bot',
          rating: 1,
          comment: 'Inappropriate spam content.',
          isFlagged: true,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      expect(summary.totalReviews, equals(1));
      expect(summary.averageRating, equals(5.0));
      expect(summary.positivePercent, equals(100.0));
      expect(summary.totalUnpublishedOrFlaggedCount, equals(1));
      expect(summary.recentReviews.any((r) => r.id == 'rev_inappropriate'), isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 8: Unpublished reviews / All reviews flagged
    // -------------------------------------------------------------------------
    test('8. Unpublished / All Flagged reviews: Correctly distinguishes hasFlaggedOnly state', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_flagged_1',
          productId: 'prod_1',
          customerId: 'cust_1',
          customerName: 'Customer 1',
          rating: 1,
          comment: 'Flagged content 1',
          isFlagged: true,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ProductReviewModel(
          id: 'rev_flagged_2',
          productId: 'prod_2',
          customerId: 'cust_2',
          customerName: 'Customer 2',
          rating: 2,
          comment: 'Flagged content 2',
          isFlagged: true,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      expect(summary.totalReviews, equals(0));
      expect(summary.hasReviews, isFalse);
      expect(summary.hasFlaggedOnly, isTrue);
      expect(summary.totalUnpublishedOrFlaggedCount, equals(2));
    });

    // -------------------------------------------------------------------------
    // Test 9: Deleted reviews
    // -------------------------------------------------------------------------
    test('9. Deleted reviews: Removed review is not present in repository stream and excluded from count', () {
      final mockDataSource = MockReviewsRemoteDataSource(initialReviews: [
        ProductReviewModel(
          id: 'rev_active_1',
          productId: 'prod_1',
          customerId: 'cust_1',
          customerName: 'Active Reviewer',
          rating: 5,
          comment: 'Legitimate purchase.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ]);

      // Before deletion
      var all = mockDataSource.getAllReviews();
      expect(all, completion(predicate<dynamic>((res) => res.dataOrNull.length == 1)));

      // Simulate deletion by resetting datasource without that review
      mockDataSource.resetForTesting([]);
      all = mockDataSource.getAllReviews();
      expect(all, completion(predicate<dynamic>((res) => res.dataOrNull.isEmpty)));
    });

    // -------------------------------------------------------------------------
    // Test 10: Invalid rating values (< 1 or > 5)
    // -------------------------------------------------------------------------
    test('10. Invalid rating values (0 or 6): Strictly rejected from satisfaction metrics', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_valid',
          productId: 'prod_1',
          customerId: 'cust_1',
          customerName: 'Valid',
          rating: 4,
          comment: 'Legit review.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ProductReviewModel(
          id: 'rev_zero_star',
          productId: 'prod_1',
          customerId: 'cust_2',
          customerName: 'Corrupted Zero',
          rating: 0, // Corrupted rating
          comment: 'Should be rejected.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ProductReviewModel(
          id: 'rev_six_star',
          productId: 'prod_1',
          customerId: 'cust_3',
          customerName: 'Corrupted Six',
          rating: 6, // Corrupted rating
          comment: 'Should be rejected.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      expect(summary.totalReviews, equals(1));
      expect(summary.averageRating, equals(4.0));
      expect(summary.starDistribution[0], isNull);
      expect(summary.starDistribution[6], isNull);
    });

    // -------------------------------------------------------------------------
    // Test 11: Missing customer reference
    // -------------------------------------------------------------------------
    test('11. Missing customer reference: Excluded as anonymous / unverified record', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_no_customer',
          productId: 'prod_1',
          customerId: null, // Missing customer reference
          customerName: 'Anonymous',
          rating: 5,
          comment: 'Ghost review.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ProductReviewModel(
          id: 'rev_empty_customer',
          productId: 'prod_1',
          customerId: '', // Empty customer reference
          customerName: 'Anonymous',
          rating: 5,
          comment: 'Ghost review 2.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      expect(summary.totalReviews, equals(0));
      expect(summary.hasReviews, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 12: Missing product reference
    // -------------------------------------------------------------------------
    test('12. Missing product reference: Excluded as unlinked review record', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_no_prod',
          productId: '', // Missing product ID
          customerId: 'cust_1',
          customerName: 'Alice',
          rating: 5,
          comment: 'Product-less review.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      expect(summary.totalReviews, equals(0));
      expect(summary.hasReviews, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 13: Reviews submitted within selected date range
    // -------------------------------------------------------------------------
    test('13. Reviews submitted within selected date range: Included in Today and 7D', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_today',
          productId: 'prod_1',
          customerId: 'cust_today',
          customerName: 'Today Reviewer',
          rating: 5,
          comment: 'Placed today in Baguio.',
          createdAt: now, // Same day
        ),
        ProductReviewModel(
          id: 'rev_3days_ago',
          productId: 'prod_1',
          customerId: 'cust_3days',
          customerName: '3 Days Reviewer',
          rating: 4,
          comment: 'Placed 3 days ago.',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      // "Today" should include rev_today but exclude rev_3days_ago
      final summaryToday = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'Today',
        referenceTime: now,
      );
      expect(summaryToday.totalReviews, equals(1));
      expect(summaryToday.recentReviews.first.id, equals('rev_today'));

      // "7D" should include both
      final summary7D = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: '7D',
        referenceTime: now,
      );
      expect(summary7D.totalReviews, equals(2));
    });

    // -------------------------------------------------------------------------
    // Test 14: Reviews submitted outside selected date range
    // -------------------------------------------------------------------------
    test('14. Reviews submitted outside selected date range (45 days ago): Excluded from 30D filter', () {
      final reviews = [
        ProductReviewModel(
          id: 'rev_45days_ago',
          productId: 'prod_1',
          customerId: 'cust_old',
          customerName: 'Old Customer',
          rating: 5,
          comment: 'Historical review.',
          createdAt: now.subtract(const Duration(days: 45)),
        ),
      ];

      final summary30D = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: '30D',
        referenceTime: now,
      );

      expect(summary30D.totalReviews, equals(0));
      expect(summary30D.hasReviews, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 15: Review edit and deletion
    // -------------------------------------------------------------------------
    test('15. Review edit and deletion: Edited comment and rating update aggregates immediately', () async {
      final mockDataSource = MockReviewsRemoteDataSource();
      final repository = ReviewsRepositoryImpl(remoteDataSource: mockDataSource);

      final initialResult = await repository.getAllReviews();
      expect(initialResult.isSuccess, isTrue);

      // Submit an updated review
      await repository.submitReview(const CreateReviewRequest(
        productId: 'mt-apo-honey',
        rating: 4,
        comment: 'Updated from 5 to 4 stars after long storage.',
      ));

      final updatedResult = await repository.getAllReviews();
      expect(updatedResult.isSuccess, isTrue);
      final updatedList = updatedResult.dataOrNull!;
      expect(updatedList.first.comment, contains('Updated from 5 to 4 stars'));
    });

    // -------------------------------------------------------------------------
    // Test 16: Average-rating recalculation
    // -------------------------------------------------------------------------
    test('16. Average-rating recalculation: Recomputes accurately on new incoming ratings', () {
      // Step A: 2 reviews with 5 and 5 -> avg = 5.0
      var reviews = [
        ProductReviewModel(
          id: 'r1',
          productId: 'p1',
          customerId: 'c1',
          customerName: 'U1',
          rating: 5,
          comment: 'Good',
          createdAt: now,
        ),
        ProductReviewModel(
          id: 'r2',
          productId: 'p2',
          customerId: 'c2',
          customerName: 'U2',
          rating: 5,
          comment: 'Good',
          createdAt: now,
        ),
      ];
      var summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );
      expect(summary.averageRating, equals(5.0));

      // Step B: incoming review of 2 stars -> (5 + 5 + 2) / 3 = 12 / 3 = 4.0
      reviews.add(ProductReviewModel(
        id: 'r3',
        productId: 'p3',
        customerId: 'c3',
        customerName: 'U3',
        rating: 2,
        comment: 'Sour',
        createdAt: now,
      ));
      summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );
      expect(summary.averageRating, equals(4.0));
    });

    // -------------------------------------------------------------------------
    // Test 17: Rating-distribution recalculation
    // -------------------------------------------------------------------------
    test('17. Rating-distribution recalculation: Distribution percentages sum to 100%', () {
      final reviews = [
        ProductReviewModel(
          id: 'r1',
          productId: 'p1',
          customerId: 'c1',
          customerName: 'U1',
          rating: 5,
          comment: 'A',
          createdAt: now,
        ),
        ProductReviewModel(
          id: 'r2',
          productId: 'p2',
          customerId: 'c2',
          customerName: 'U2',
          rating: 5,
          comment: 'B',
          createdAt: now,
        ),
        ProductReviewModel(
          id: 'r3',
          productId: 'p3',
          customerId: 'c3',
          customerName: 'U3',
          rating: 4,
          comment: 'C',
          createdAt: now,
        ),
        ProductReviewModel(
          id: 'r4',
          productId: 'p4',
          customerId: 'c4',
          customerName: 'U4',
          rating: 3,
          comment: 'D',
          createdAt: now,
        ),
      ];

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: reviews,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );

      final totalPct = summary.starPercentages.values.fold<double>(0.0, (sum, val) => sum + val);
      expect((totalPct * 100).round(), equals(100));
      expect(summary.starDistribution[5], equals(2));
      expect(summary.starDistribution[4], equals(1));
      expect(summary.starDistribution[3], equals(1));
      expect(summary.starDistribution[2], equals(0));
      expect(summary.starDistribution[1], equals(0));
    });

    // -------------------------------------------------------------------------
    // Test 18: Application refresh and restart
    // -------------------------------------------------------------------------
    test('18. Application refresh and restart: Reactive stream emits fresh state without stale cached fallbacks', () async {
      final mock = MockReviewsRemoteDataSource();
      final stream = mock.watchAllReviews();

      final firstEmission = await stream.first;
      expect(firstEmission.isNotEmpty, isTrue);

      // Ensure that hardcoded 184 is NOT in the dataset
      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: firstEmission,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );
      expect(summary.totalReviews, isNot(equals(184)));
    });

    // -------------------------------------------------------------------------
    // Test 19: Pagination does not change overall aggregates
    // -------------------------------------------------------------------------
    test('19. Pagination does not change overall aggregates: Analytics aggregates full dataset', () async {
      final mock = MockReviewsRemoteDataSource();

      // Suppose UI fetches page 1 with limit = 1
      final pagedResult = await mock.getProductReviews('mt-apo-honey', limit: 1);
      expect(pagedResult.dataOrNull!.length, equals(1));

      // But overall satisfaction query fetches full dataset across catalog
      final fullResult = await mock.getAllReviews();
      expect(fullResult.dataOrNull!.length, equals(2));

      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: fullResult.dataOrNull!,
        dateRangeLabel: 'All Time',
        referenceTime: now,
      );
      expect(summary.totalReviews, equals(2));
    });

    // -------------------------------------------------------------------------
    // Widget Test: ExecutiveCustomerFeedbackCard Rendering
    // -------------------------------------------------------------------------
    testWidgets('ExecutiveCustomerFeedbackCard renders dynamic satisfaction metrics without 184 fallback', (tester) async {
      final summary = CustomerSatisfactionSummary.fromReviews(
        allRawReviews: [
          ProductReviewModel(
            id: 'rev_w1',
            productId: 'mt-apo-honey',
            customerId: 'cust_w1',
            customerName: 'Jasmine Chen',
            productName: 'Mount Apo Anaerobic Honey',
            rating: 5,
            comment: 'Extraordinary berry notes and silky body.',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          ProductReviewModel(
            id: 'rev_w2',
            productId: 'tokyo-blend',
            customerId: 'cust_w2',
            customerName: 'Mateo Lopez',
            productName: 'Tokyo Roast Blend',
            rating: 4,
            comment: 'Great morning espresso with velvety crema.',
            createdAt: now.subtract(const Duration(days: 4)),
          ),
        ],
        dateRangeLabel: '30D',
        referenceTime: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: ExecutiveCustomerFeedbackCard(summary: summary),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and sentiment
      expect(find.text('Customer Satisfaction & Feedback'), findsOneWidget);
      expect(find.text('100% Positive'), findsOneWidget);

      // Verify actual score: (5 + 4) / 2 = 4.5
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('/ 5.0'), findsOneWidget);

      // Verify total verified reviews count (2, NOT 184!)
      expect(find.text('2 verified reviews'), findsOneWidget);
      expect(find.text('184 verified reviews'), findsNothing);

      // Verify latest review quote
      expect(find.text('"Extraordinary berry notes and silky body."'), findsOneWidget);
      expect(find.textContaining('Jasmine Chen'), findsOneWidget);
    });

    testWidgets('ExecutiveCustomerFeedbackCard renders honest empty state when 0 reviews exist', (tester) async {
      const summary = CustomerSatisfactionSummary(
        totalReviews: 0,
        averageRating: 0.0,
        positivePercent: 0.0,
        starDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        starPercentages: {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0},
        recentReviews: [],
        totalUnpublishedOrFlaggedCount: 0,
        hasReviews: false,
        hasFlaggedOnly: false,
        dateRangeLabel: '30D',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: ExecutiveCustomerFeedbackCard(summary: summary),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify honest empty state headline and subtitle
      expect(find.text('No customer reviews yet.'), findsOneWidget);
      expect(find.text('Customer ratings and feedback will appear here as orders are completed.'), findsOneWidget);
      expect(find.text('0 reviews'), findsOneWidget);
      expect(find.text('184 verified reviews'), findsNothing);
      expect(find.text('Maria Santos • Verified Pickup Customer'), findsNothing);
    });
  });
}

