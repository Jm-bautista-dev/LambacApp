import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';

/// Discoverable Customer Privacy Policy Screen
///
/// In accordance with the Data Privacy Act and standard commercial principles:
/// Outlines personal data collected, processing purpose, retention schedules,
/// access boundaries, data portability, and deletion lifecycle.
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: const LambacAppBar(
        title: 'Privacy Policy',
        subtitle: 'Data protection & customer rights',
        fallbackRoute: AppRoutes.profile,
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.warmDiscovery,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: ResponsiveLayout.maxReadingWidth,
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
              // Notice Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.brandAmber,
                      size: 28,
                    ),
                    AppSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lambac Coffee Roastery Privacy Charter',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          AppSpacing.vSpaceXs,
                          Text(
                            'Effective: October 2026 • Policy Version 1.0\nNote: Requires business owner review prior to production release.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              // Section 1: Data Categories
              _buildPolicySection(
                title: '1. Personal Information We Collect',
                icon: Icons.inventory_2_outlined,
                isDark: isDark,
                content: [
                  '• Account Identity: Full name, verified email address, mobile phone number, and optional profile avatar.',
                  '• Order & Fulfillment: Scheduled pickup times, selected roastery location, items ordered, and payment preference (Cash at counter, GCash).',
                  '• Roastery Support: Concierge chat history between customer and baristas regarding orders and bean recommendations.',
                  '• Reviews & Feedback: Star ratings and tasting feedback submitted for coffee products.',
                  '• Technical Identifiers: AppCheck device attestation tokens, FCM push notification tokens, and temporary diagnostic logs.',
                ],
              ),
              AppSpacing.vSpaceLg,

              // Section 2: Purpose & Access Controls
              _buildPolicySection(
                title: '2. Purpose of Collection & Access Permissions',
                icon: Icons.shield_outlined,
                isDark: isDark,
                content: [
                  '• Order Processing: Roastery staff and baristas access only necessary fulfillment information (name, item choices, pickup time).',
                  '• Customer Support: Baristas access active customer chat threads to answer product questions.',
                  '• Financial Accounting: Transactions are logged in our internal ledger for VAT, statutory reporting, and auditing.',
                  '• Role Isolation: Ordinary customers cannot view or modify other customers\' profiles, notifications, or orders.',
                  '• Zero Payment Token Storage: Credit/debit card numbers and payment tokens are handled externally by licensed payment processors and are never stored on our servers.',
                ],
              ),
              AppSpacing.vSpaceLg,

              // Section 3: Data Retention Schedules
              _buildPolicySection(
                title: '3. Data Retention Schedules',
                icon: Icons.hourglass_top_outlined,
                isDark: isDark,
                content: [
                  '• Active Account Profiles: Retained for the lifetime of your account until deletion is requested.',
                  '• Completed Orders & Financial Sales: Retained for 7 years to satisfy statutory tax, audit, and commercial accounting requirements.',
                  '• Support Conversations: Retained for 1 year for dispute resolution and roastery service quality.',
                  '• Operational Notifications: Retained for 90 days before automated cleanup.',
                  '• Security Audit Logs: Retained for 3 years to ensure non-repudiation and access compliance.',
                ],
              ),
              AppSpacing.vSpaceLg,

              // Section 4: Data Portability & Deletion Lifecycle
              _buildPolicySection(
                title: '4. Your Rights: Export & Account Deletion',
                icon: Icons.lock_reset_outlined,
                isDark: isDark,
                content: [
                  '• Data Portability (Export): You may request a complete JSON export of your personal profile, order history, and reviews at any time.',
                  '• Account Deletion & Anonymization: When you delete your account, your personal information (name, email, phone) is permanently removed or anonymized.',
                  '• Preservation of Business Records: Financial order records and sales ledger transactions are preserved without personal identifiers to maintain commercial ledger integrity.',
                  '• Reviews & Ratings: Published reviews remain visible under "Former Customer" to preserve catalog review averages.',
                ],
              ),
              AppSpacing.vSpaceXxl,
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<String> content,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              ),
              AppSpacing.hSpaceSm,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,
          ...content.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
