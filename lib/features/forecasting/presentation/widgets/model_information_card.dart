import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';

/// Card providing Academic Model Details, Algorithm Assumptions & Forecasting Limitations
class ModelInformationCard extends StatelessWidget {
  const ModelInformationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                size: 18,
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              ),
              const SizedBox(width: 8),
              Text(
                'Forecasting Model Architecture',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Model Specifications Table
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFFAF5EE),
              borderRadius: AppRadius.radiusSm,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow('Primary Algorithm', 'Linear Regression Trend Analysis', isDark),
                const Divider(height: 12),
                _buildInfoRow('Seasonal Smoothing', 'Holt-Winters Triple Exponential Smoothing', isDark),
                const Divider(height: 12),
                _buildInfoRow('Forecast Target', 'Daily Revenue (₱) & Bean Unit Demand', isDark),
                const Divider(height: 12),
                _buildInfoRow('Forecast Horizon', '7-Day & 14-Day Forward Rolling Windows', isDark),
                const Divider(height: 12),
                _buildInfoRow('Data Sources', 'Centralized Ledger (Customer Mobile Orders & Pickups)', isDark),
              ],
            ),
          ),
          AppSpacing.vSpaceLg,

          // Limitations & Assumptions Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.brandAmber.withOpacity(0.12) : const Color(0xFFF9F3EA),
              borderRadius: AppRadius.radiusSm,
              border: Border.all(
                color: isDark ? AppColors.brandAmber.withOpacity(0.3) : AppColors.brandAmber.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Model Assumptions & Limitations',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '• Predictions represent statistical estimates based on historical patterns rather than guaranteed sales.\n'
                  '• External events (severe weather, holidays, unforeseen supply delays) may alter actual roastery sales.\n'
                  '• Forecasts are designed to guide inventory preparation alongside human roastery expertise.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
