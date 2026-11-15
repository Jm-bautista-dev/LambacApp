import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Compact Order Context Header displayed inside Chat Screen
class OrderContextChatHeader extends StatelessWidget {
  final String orderId;
  final String orderStatusLabel;
  final double orderTotal;
  final VoidCallback? onTapOrder;

  const OrderContextChatHeader({
    super.key,
    required this.orderId,
    required this.orderStatusLabel,
    required this.orderTotal,
    this.onTapOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTapOrder,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF9F6F0),
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.brandAmberLight.withOpacity(0.18)
                    : AppColors.brandAmber.withOpacity(0.18),
                borderRadius: AppRadius.radiusSm,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'ORDER CONTEXT:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '#$orderId',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Status: $orderStatusLabel • Total: ${CurrencyFormatter.format(orderTotal)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
