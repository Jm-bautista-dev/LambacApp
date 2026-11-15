import '../../../../core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../data/models/create_review_request.dart';
import '../providers/reviews_provider.dart';

/// Modal Bottom Sheet for Submitting Verified Product Reviews
/// Elevated with Apple-style sheet ergonomics and Lambac Luxury styling
class WriteProductReviewSheet extends ConsumerStatefulWidget {
  final String productId;
  final String productName;

  const WriteProductReviewSheet({
    super.key,
    required this.productId,
    required this.productName,
  });

  static Future<void> show(BuildContext context, {required String productId, required String productName}) {
    return AppBottomSheet.show<void>(
      context,
      title: 'Write a Review',
      child: WriteProductReviewSheet(productId: productId, productName: productName),
    );
  }

  @override
  ConsumerState<WriteProductReviewSheet> createState() => _WriteProductReviewSheetState();
}

class _WriteProductReviewSheetState extends ConsumerState<WriteProductReviewSheet> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (_selectedRating < 1 || _selectedRating > 5) {
      AppToast.error(context, 'Please select a rating between 1 and 5 stars.');
      return;
    }

    final comment = _commentController.text.trim();
    final validationError = Validators.reviewComment(comment);
    if (validationError != null) {
      AppToast.error(context, validationError);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(reviewsRepositoryProvider);
      final result = await repository.submitReview(
        CreateReviewRequest(
          productId: widget.productId,
          rating: _selectedRating,
          comment: comment,
        ),
      );

      if (!mounted) return;

      result.when(
        success: (_) {
          AppToast.success(context, 'Review submitted successfully!');
          ref.invalidate(productReviewsProvider(widget.productId));
          Navigator.of(context).pop();
        },
        failure: (AppFailure failure) {
          AppToast.error(context, failure.userFriendlyMessage);
        },
      );
    } catch (e, st) {
      if (!mounted) return;
      final failure = ErrorHandler.handle(
        e,
        stackTrace: st,
        operation: 'submitReview',
        domain: FailureDomain.firestoreAccess,
      );
      AppToast.error(context, failure.userFriendlyMessage);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Share your roastery experience for "${widget.productName}"',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        AppSpacing.vSpaceLg,

        // Interactive Star Rating Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final star = index + 1;
            final isFilled = star <= _selectedRating;

            return IconButton(
              iconSize: 34,
              icon: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFilled ? AppColors.brandAmber : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
              ),
              onPressed: () => setState(() => _selectedRating = star),
            );
          }),
        ),
        Center(
          child: Text(
            '$_selectedRating out of 5 Stars',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
            ),
          ),
        ),
        AppSpacing.vSpaceLg,

        // Review Comment Input
        AppTextField(
          label: 'Tasting & Quality Notes',
          hint: 'Describe flavor profile, aroma, body, or grind preference...',
          controller: _commentController,
          maxLines: 3,
          maxLength: 1000,
          validator: Validators.reviewComment,
        ),
        AppSpacing.vSpaceXxl,

        // Submit Action
        AppButton.primary(
          text: 'Submit Verified Review',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _handleSubmit,
        ),
        AppSpacing.vSpaceMd,
      ],
    );
  }
}
