import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../reviews/data/models/customer_satisfaction_summary.dart';
import '../../../../reviews/presentation/providers/reviews_provider.dart';

/// Executive Customer Satisfaction & Feedback Card
/// Dynamically calculates ratings, sentiment, and distributions from genuine Firestore reviews.
class ExecutiveCustomerFeedbackCard extends ConsumerWidget {
  final CustomerSatisfactionSummary? summary;

  const ExecutiveCustomerFeedbackCard({
    super.key,
    this.summary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use passed summary if provided (e.g. for testing); otherwise watch live provider
    if (summary != null) {
      return _buildContent(context, isDark, summary!);
    }

    final satisfactionAsync = ref.watch(customerSatisfactionProvider);

    return satisfactionAsync.when(
      data: (data) => _buildContent(context, isDark, data),
      loading: () => AppCard.elevated(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 160,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.cremaGold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Calculating verified customer satisfaction...',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (err, _) => AppCard.elevated(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Failed to load customer reviews: $err',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(allReviewsStreamProvider),
              child: const Text('Retry', style: TextStyle(color: AppColors.brandAmber)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, CustomerSatisfactionSummary data) {
    final ratingDistribution = [
      (stars: '5★', count: data.starDistribution[5] ?? 0, percent: data.starPercentages[5] ?? 0.0),
      (stars: '4★', count: data.starDistribution[4] ?? 0, percent: data.starPercentages[4] ?? 0.0),
      (stars: '3★', count: data.starDistribution[3] ?? 0, percent: data.starPercentages[3] ?? 0.0),
      (stars: '2★', count: data.starDistribution[2] ?? 0, percent: data.starPercentages[2] ?? 0.0),
      (stars: '1★', count: data.starDistribution[1] ?? 0, percent: data.starPercentages[1] ?? 0.0),
    ];

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rate_rounded,
                          size: 18,
                          color: AppColors.cremaGold,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Customer Satisfaction & Feedback',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aggregated pickup ratings & taste profile sentiment',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: data.hasReviews
                        ? AppColors.success.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: AppRadius.radiusPill,
                    border: Border.all(
                      color: data.hasReviews
                          ? AppColors.success.withValues(alpha: 0.3)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.hasReviews ? Icons.trending_up_rounded : Icons.star_outline_rounded,
                        size: 13,
                        color: data.hasReviews ? AppColors.success : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          data.hasReviews
                              ? '${data.positivePercent.toStringAsFixed(0)}% Positive'
                              : 'No Ratings Yet',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: data.hasReviews ? AppColors.success : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceLg,

          // Score & Distribution Split
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 360;

              final scoreWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            data.hasReviews ? data.averageRating.toStringAsFixed(1) : '0.0',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '/ 5.0',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (index) {
                            final starThreshold = index + 1;
                            final isFilled = data.hasReviews && data.averageRating >= starThreshold - 0.25;
                            return Icon(
                              isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 14,
                              color: isFilled ? AppColors.cremaGold : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.hasReviews
                            ? '${data.totalReviews} verified review${data.totalReviews == 1 ? '' : 's'}'
                            : '0 reviews',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );

              final distributionBars = Column(
                children: ratingDistribution.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            item.stars,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: AppRadius.radiusPill,
                            child: LinearProgressIndicator(
                              value: item.percent,
                              minHeight: 4,
                              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                item.stars == '5★' || item.stars == '4★'
                                    ? AppColors.cremaGold
                                    : AppColors.brandAmber.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 32,
                          child: Text(
                            data.hasReviews ? '${(item.percent * 100).toStringAsFixed(0)}%' : '0%',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );

              if (isStacked) {
                return Column(
                  children: [
                    scoreWidget,
                    const SizedBox(height: 12),
                    distributionBars,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  scoreWidget,
                  const SizedBox(width: 14),
                  Expanded(child: distributionBars),
                ],
              );
            },
          ),
          AppSpacing.vSpaceMd,

          // Latest Customer Review Quote or Genuine Empty State
          if (data.hasReviews && data.recentReviews.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final latestReview = data.recentReviews.first;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.brandAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"${latestReview.comment}"',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${latestReview.customerName} • ${latestReview.productName ?? 'Verified Pickup Customer'}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    latestReview.rating,
                                    (_) => const Icon(Icons.star_rounded, size: 11, color: AppColors.cremaGold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cremaGold.withValues(alpha: 0.12) : AppColors.cremaGold.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rate_review_outlined,
                      size: 16,
                      color: AppColors.cremaGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.hasFlaggedOnly
                              ? 'No published reviews in this period'
                              : 'No customer reviews yet.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.hasFlaggedOnly
                              ? '${data.totalUnpublishedOrFlaggedCount} review(s) currently awaiting moderation.'
                              : 'Customer ratings and feedback will appear here as orders are fulfilled.',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
