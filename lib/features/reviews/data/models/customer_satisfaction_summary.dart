import 'package:equatable/equatable.dart';
import '../../../../core/utils/business_time_service.dart';
import 'product_review_model.dart';

/// Aggregated Customer Satisfaction & Review Analytics Model
class CustomerSatisfactionSummary extends Equatable {
  final int totalReviews;
  final double averageRating;
  final double positivePercent;
  final Map<int, int> starDistribution;
  final Map<int, double> starPercentages;
  final List<ProductReviewModel> recentReviews;
  final int totalUnpublishedOrFlaggedCount;
  final bool hasReviews;
  final bool hasFlaggedOnly;
  final String dateRangeLabel;

  const CustomerSatisfactionSummary({
    required this.totalReviews,
    required this.averageRating,
    required this.positivePercent,
    required this.starDistribution,
    required this.starPercentages,
    required this.recentReviews,
    this.totalUnpublishedOrFlaggedCount = 0,
    required this.hasReviews,
    this.hasFlaggedOnly = false,
    required this.dateRangeLabel,
  });

  /// Empty fallback summary when no qualifying customer reviews exist
  factory CustomerSatisfactionSummary.empty({
    String dateRangeLabel = 'All Time',
    int totalUnpublishedOrFlaggedCount = 0,
  }) {
    return CustomerSatisfactionSummary(
      totalReviews: 0,
      averageRating: 0.0,
      positivePercent: 0.0,
      starDistribution: const {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      starPercentages: const {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0},
      recentReviews: const [],
      totalUnpublishedOrFlaggedCount: totalUnpublishedOrFlaggedCount,
      hasReviews: false,
      hasFlaggedOnly: totalUnpublishedOrFlaggedCount > 0,
      dateRangeLabel: dateRangeLabel,
    );
  }

  /// Factory that compiles raw reviews into rigorous, production-accurate metrics
  factory CustomerSatisfactionSummary.fromReviews({
    required List<ProductReviewModel> allRawReviews,
    String dateRangeLabel = '30D',
    DateTime? referenceTime,
    Map<String, String>? productNames,
  }) {
    if (allRawReviews.isEmpty) {
      return CustomerSatisfactionSummary.empty(dateRangeLabel: dateRangeLabel);
    }

    // 1. Resolve authoritative Asia/Manila calendar date range
    final isAllTime = dateRangeLabel.toLowerCase() == 'all' ||
        dateRangeLabel.toLowerCase() == 'all time' ||
        dateRangeLabel.toLowerCase() == 'alltime';
    final ManilaDateRange? dateRange = isAllTime
        ? null
        : BusinessTimeService.resolveRange(dateRangeLabel, now: referenceTime);

    // 2. Deduplicate raw reviews by ID and by customer-product composite key
    final Map<String, ProductReviewModel> deduplicatedById = {};
    for (final review in allRawReviews) {
      final existing = deduplicatedById[review.id];
      if (existing == null || review.createdAt.isAfter(existing.createdAt)) {
        deduplicatedById[review.id] = review;
      }
    }

    // Also deduplicate multiple reviews from the same customer on the same product
    final Map<String, ProductReviewModel> deduplicatedByUserProduct = {};
    for (final review in deduplicatedById.values) {
      final userProductKey = review.customerId != null && review.customerId!.isNotEmpty
          ? '${review.customerId}_${review.productId}'
          : review.id;

      final existing = deduplicatedByUserProduct[userProductKey];
      if (existing == null || review.createdAt.isAfter(existing.createdAt)) {
        deduplicatedByUserProduct[userProductKey] = review;
      }
    }

    final uniqueReviews = deduplicatedByUserProduct.values.toList();

    // 3. Separate Flagged / Unpublished Reviews vs. Qualifying Reviews
    int flaggedInPeriodCount = 0;
    final List<ProductReviewModel> qualifying = [];

    for (final r in uniqueReviews) {
      // Exclude seed / demo / non-production records
      final idLower = r.id.toLowerCase();
      final isSeedOrDemo = idLower.startsWith('rev_seed_') ||
          idLower.contains('demo') ||
          idLower.contains('seed') ||
          r.customerId == 'usr_customer_demo';
      if (isSeedOrDemo) continue;

      // Validate core required fields
      if (r.id.trim().isEmpty) continue;
      if (r.productId.trim().isEmpty) continue;
      if (r.customerId == null || r.customerId!.trim().isEmpty) continue;
      if (r.comment.trim().isEmpty) continue;
      if (r.rating < 1 || r.rating > 5) continue;

      // Date filtering check in Asia/Manila
      final fallsInDateRange = dateRange == null || dateRange.contains(r.createdAt);
      if (!fallsInDateRange) continue;

      // Moderation status check
      if (r.isFlagged) {
        flaggedInPeriodCount++;
        continue;
      }

      // Attach resolved product name if available and not present
      final resolvedProductName = r.productName ?? productNames?[r.productId] ?? r.productId;
      qualifying.add(r.copyWith(productName: resolvedProductName));
    }

    if (qualifying.isEmpty) {
      return CustomerSatisfactionSummary.empty(
        dateRangeLabel: dateRangeLabel,
        totalUnpublishedOrFlaggedCount: flaggedInPeriodCount,
      );
    }

    // 4. Calculate Aggregate Metrics
    final total = qualifying.length;
    final ratingSum = qualifying.fold<int>(0, (acc, r) => acc + r.rating);
    final rawAvg = ratingSum / total;
    // Rounded to one decimal place
    final avgRating = double.parse(rawAvg.toStringAsFixed(1)).clamp(1.0, 5.0);

    // Star Distribution
    final Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in qualifying) {
      counts[r.rating] = (counts[r.rating] ?? 0) + 1;
    }

    final Map<int, double> percentages = {};
    for (int star = 1; star <= 5; star++) {
      percentages[star] = (counts[star]! / total);
    }

    // Positive sentiment: 4-star and 5-star ratings
    final positiveCount = (counts[5] ?? 0) + (counts[4] ?? 0);
    final positivePct = double.parse(((positiveCount / total) * 100).toStringAsFixed(1));

    // Sort recent feedback by review submission timestamp descending
    qualifying.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return CustomerSatisfactionSummary(
      totalReviews: total,
      averageRating: avgRating,
      positivePercent: positivePct,
      starDistribution: counts,
      starPercentages: percentages,
      recentReviews: List.unmodifiable(qualifying),
      totalUnpublishedOrFlaggedCount: flaggedInPeriodCount,
      hasReviews: true,
      hasFlaggedOnly: false,
      dateRangeLabel: dateRangeLabel,
    );
  }

  @override
  List<Object?> get props => [
        totalReviews,
        averageRating,
        positivePercent,
        starDistribution,
        starPercentages,
        recentReviews,
        totalUnpublishedOrFlaggedCount,
        hasReviews,
        hasFlaggedOnly,
        dateRangeLabel,
      ];
}

