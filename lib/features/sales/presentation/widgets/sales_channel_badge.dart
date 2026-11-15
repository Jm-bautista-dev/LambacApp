import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/sales_channel.dart';

/// Visual Channel Badge for Centralized Transactions
class SalesChannelBadge extends StatelessWidget {
  final SalesChannel channel;

  const SalesChannelBadge({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isMobile = channel == SalesChannel.mobileApp;

    final color = isMobile
        ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
        : AppColors.matchaSage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.radiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMobile ? Icons.phone_iphone_rounded : Icons.storefront_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            channel.badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
