import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';

/// Visual Card displaying Centralized Sales Data Architecture, Pipeline Flow & Academic System Explanations
class CentralizedPipelineCard extends StatelessWidget {
  const CentralizedPipelineCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.schema_rounded,
                      size: 18,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Centralized Data Architecture',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandAmber.withOpacity(0.15),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Text(
                  'SYSTEM PIPELINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceSm,
          Text(
            'How customer interactions and sales are transformed into data-driven decision recommendations:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.35,
            ),
          ),
          AppSpacing.vSpaceLg,

          // Visual Flowchart Nodes
          _buildPipelineNode(
            context,
            stepNumber: '1',
            title: 'Multi-Channel Sales Data Capture',
            description: 'Customer Mobile Pickup Orders & Walk-In POS Counter Sales are recorded in real-time.',
            icon: Icons.point_of_sale_rounded,
            badge: 'Mobile + POS',
            isDark: isDark,
          ),
          _buildConnector(isDark),
          _buildPipelineNode(
            context,
            stepNumber: '2',
            title: 'Centralized Sales Ledger & Validation',
            description: 'Transactions are deduplicated, timestamps verified, and price snapshots preserved.',
            icon: Icons.menu_book_rounded,
            badge: 'Audit Cleaned',
            isDark: isDark,
          ),
          _buildConnector(isDark),
          _buildPipelineNode(
            context,
            stepNumber: '3',
            title: 'Descriptive Analytics ("What Happened?")',
            description: 'Calculates historical revenue KPIs, channel distributions, and product demand rankings.',
            icon: Icons.bar_chart_rounded,
            badge: 'Historical KPIs',
            isDark: isDark,
          ),
          _buildConnector(isDark),
          _buildPipelineNode(
            context,
            stepNumber: '4',
            title: 'Forecast Readiness & ML Models ("What May Happen?")',
            description: 'Linear Regression & Holt-Winters Exponential Smoothing project 7-day demand trends.',
            icon: Icons.trending_up_rounded,
            badge: 'ML Projections',
            isDark: isDark,
          ),
          _buildConnector(isDark),
          _buildPipelineNode(
            context,
            stepNumber: '5',
            title: 'Prescriptive Decisions ("What Should We Do?")',
            description: 'Business decision rules evaluate forecast anomalies to produce actionable inventory and roasting recommendations.',
            icon: Icons.lightbulb_rounded,
            badge: 'Actionable Advice',
            isDark: isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineNode(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required String badge,
    required bool isDark,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFFAF5EE),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Circle
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkCanvas : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
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

  Widget _buildConnector(bool isDark) {
    return Center(
      child: Container(
        width: 2,
        height: 14,
        color: isDark ? AppColors.brandAmber.withOpacity(0.4) : AppColors.brandAmber.withOpacity(0.3),
      ),
    );
  }
}
