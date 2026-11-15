import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/reviews_provider.dart';
import 'write_product_review_sheet.dart';

/// Product Reviews List Widget with Verified Purchase Badges & Admin Moderation
/// Elevated with Lambac Luxury Editorial typography and Apple-inspired precision
class ProductReviewsList extends ConsumerWidget {
  final String productId;
  final String productName;

  const ProductReviewsList({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    final isBusinessUser = user?.isBusinessUser ?? false;

    final reviewsAsync = ref.watch(productReviewsProvider(productId));
    final eligibilityAsync = ref.watch(reviewEligibilityProvider(productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'Customer Reviews & Ratings',
              style: CustomerLuxuryTheme.editorialStyle(
                isDark: isDark,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            eligibilityAsync.when(
              data: (isEligible) {
                if (!isEligible) return const SizedBox.shrink();
                return AppButton.outlined(
                  text: '+ Write Review',
                  size: AppButtonSize.small,
                  isFullWidth: false,
                  onPressed: () => WriteProductReviewSheet.show(
                    context,
                    productId: productId,
                    productName: productName,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        AppSpacing.vSpaceSm,

        // Reviews List
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                child: Center(
                  child: Text(
                    'No reviews yet for this roast. Be the first to write one!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final avgRating = reviews.fold<num>(0, (sum, r) => sum + r.rating) / (reviews.isEmpty ? 1 : reviews.length);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Average Rating Summary Bar
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (idx) {
                        return Icon(
                          idx < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 18,
                          color: AppColors.brandAmber,
                        );
                      }),
                    ),
                    Text(
                      '(${reviews.length} verified reviews)',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpaceLg,

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => AppSpacing.vSpaceMd,
                  itemBuilder: (context, index) {
                    final review = reviews[index];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(5, (idx) {
                                        return Icon(
                                          idx < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                          size: 15,
                                          color: AppColors.brandAmber,
                                        );
                                      }),
                                    ),
                                    if (review.isVerifiedPurchase)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.matchaSage.withOpacity(0.16),
                                          borderRadius: AppRadius.radiusPill,
                                          border: Border.all(
                                            color: AppColors.matchaSage.withOpacity(0.35),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          'VERIFIED BUYER',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.matchaSage,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isBusinessUser)
                                IconButton(
                                  icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.warning),
                                  tooltip: 'Flag Inappropriate Content',
                                  onPressed: () async {
                                    final repository = ref.read(reviewsRepositoryProvider);
                                    await repository.flagReview(review.id);
                                    if (context.mounted) {
                                      AppToast.info(context, 'Review flagged for moderation audit.');
                                    }
                                    ref.invalidate(productReviewsProvider(productId));
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text(
                            review.comment,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  review.customerName,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(review.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stackTrace) {
            final failure = ErrorHandler.handle(
              err,
              stackTrace: stackTrace,
              operation: 'productReviews',
              domain: FailureDomain.firestoreAccess,
              recordId: productId,
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AppErrorView(
                failure: failure,
                onRetry: () => ref.invalidate(productReviewsProvider(productId)),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
