import 'package:flutter/material.dart';
import '../../errors/app_failure.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Minimalist Inline Validation Error Banner for Forms
class AppFormFieldError extends StatelessWidget {
  final String? errorMessage;
  final ValidationFailure? validationFailure;
  final String? fieldKey;

  const AppFormFieldError({
    super.key,
    this.errorMessage,
    this.validationFailure,
    this.fieldKey,
  });

  /// Factory helper that extracts the error message for a specific field
  factory AppFormFieldError.forField({
    Key? key,
    required String fieldKey,
    ValidationFailure? failure,
  }) {
    return AppFormFieldError(
      key: key,
      validationFailure: failure,
      fieldKey: fieldKey,
      errorMessage: failure?.firstErrorFor(fieldKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = errorMessage ??
        (fieldKey != null && validationFailure != null
            ? validationFailure!.firstErrorFor(fieldKey!)
            : null);

    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 14,
            color: AppColors.error,
          ),
          AppSpacing.hSpaceXs,
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
