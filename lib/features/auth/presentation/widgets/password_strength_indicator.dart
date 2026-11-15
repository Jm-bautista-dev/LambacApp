import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';

/// Interactive Visual Password-Strength Indicator & Dynamic Requirements Checklist
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strength = Validators.evaluatePassword(password);

    final (strengthColor, strengthLabel) = switch (strength.score) {
      0 || 1 => (AppColors.error, 'Weak Password'),
      2 || 3 => (AppColors.warning, 'Fair Password'),
      _ => (AppColors.success, 'Strong Password'),
    };

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strength Bar & Label
          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(4, (index) {
                    final isActive = index < strength.score;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: isActive
                              ? strengthColor
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strengthLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Requirements Header
          Text(
            'Password must contain:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),

          // Dynamic Checklist Items
          _buildRequirementItem('At least 8 characters', strength.hasMinLength, isDark),
          _buildRequirementItem('One uppercase letter (A-Z)', strength.hasUppercase, isDark),
          _buildRequirementItem('One lowercase letter (a-z)', strength.hasLowercase, isDark),
          _buildRequirementItem('One number (0-9)', strength.hasNumber, isDark),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String label, bool isSatisfied, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isSatisfied
                ? AppColors.success
                : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.w400,
                color: isSatisfied
                    ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
