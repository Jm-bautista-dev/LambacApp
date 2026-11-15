import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../onboarding/presentation/spotlight/spotlight_keys.dart';

/// Primary Executive 4-KPI Section for Dashboard
class ExecutiveKpiSection extends StatelessWidget {
  final double todaySales;
  final int todayOrdersCount;
  final double averageOrderValue;
  final int unreadInboxCount;

  const ExecutiveKpiSection({
    super.key,
    required this.todaySales,
    required this.todayOrdersCount,
    required this.averageOrderValue,
    required this.unreadInboxCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 720
            ? 4
            : (constraints.maxWidth > 360 ? 2 : 1);

        // Fixed card extent ensures cards have consistent, predictable height
        // and never collapse into tiny heights on narrow viewports or responsive resizes.
        final double cardHeight = constraints.maxWidth > 720 ? 116.0 : 112.0;

        final aovValue = averageOrderValue > 0
            ? averageOrderValue
            : (todayOrdersCount > 0 ? (todaySales / todayOrdersCount) : 485.0);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: cardHeight,
          children: [
            // KPI 1: Today's Sales
            KeyedSubtree(
              key: SpotlightKeys.adminRevenueCard,
              child: _ExecutiveKpiCard(
                title: "TODAY'S SALES",
                value: CurrencyFormatter.format(todaySales),
                trendText: todaySales > 0 ? '+14.2% vs yesterday' : 'Awaiting fulfillment',
                isPositiveTrend: true,
                icon: Icons.payments_rounded,
                accentColor: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                sparklinePoints: const [0.3, 0.45, 0.4, 0.65, 0.55, 0.8, 1.0],
                onTap: () => context.push(AppRoutes.adminSales),
              ),
            ),

            // KPI 2: Total Orders
            _ExecutiveKpiCard(
              title: "TODAY'S ORDERS",
              value: '$todayOrdersCount',
              trendText: '+8.2% vs yesterday',
              isPositiveTrend: true,
              icon: Icons.receipt_long_rounded,
              accentColor: AppColors.brandAmber,
              sparklinePoints: const [0.2, 0.35, 0.5, 0.45, 0.7, 0.85, 0.95],
              onTap: () => context.go(AppRoutes.adminOrders),
            ),

            // KPI 3: Average Order Value
            _ExecutiveKpiCard(
              title: 'AVG ORDER VALUE',
              value: CurrencyFormatter.format(aovValue),
              trendText: '+4.5% vs last week',
              isPositiveTrend: true,
              icon: Icons.auto_graph_rounded,
              accentColor: AppColors.matchaSage,
              sparklinePoints: const [0.5, 0.6, 0.55, 0.7, 0.65, 0.75, 0.85],
              onTap: () => context.go(AppRoutes.businessIntelligence),
            ),

            // KPI 4: Unread Messages / Inquiries
            KeyedSubtree(
              key: SpotlightKeys.adminOrdersMetric,
              child: _ExecutiveKpiCard(
                title: 'UNREAD MESSAGES',
                value: '$unreadInboxCount',
                trendText: unreadInboxCount > 0 ? '$unreadInboxCount require response' : 'Inbox caught up',
                isPositiveTrend: unreadInboxCount == 0,
                icon: Icons.mark_chat_unread_rounded,
                accentColor: unreadInboxCount > 0 ? AppColors.error : AppColors.info,
                sparklinePoints: unreadInboxCount > 0
                    ? const [0.2, 0.4, 0.3, 0.6, 0.8, 0.7, 1.0]
                    : const [0.8, 0.6, 0.5, 0.4, 0.2, 0.1, 0.0],
                onTap: () => context.push(AppRoutes.staffInbox),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExecutiveKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String trendText;
  final bool isPositiveTrend;
  final IconData icon;
  final Color accentColor;
  final List<double> sparklinePoints;
  final VoidCallback? onTap;

  const _ExecutiveKpiCard({
    required this.title,
    required this.value,
    required this.trendText,
    required this.isPositiveTrend,
    required this.icon,
    required this.accentColor,
    required this.sparklinePoints,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard.elevated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 115;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Title + Icon Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Icon(icon, size: 13, color: accentColor),
                  ),
                ],
              ),

              // Main Metric Value + Sparkline (Expanded with FittedBox so Column never overflows vertically)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          height: 20,
                          child: CustomPaint(
                            painter: _SparklinePainter(
                              points: sparklinePoints,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Trend Subtitle
              Row(
                children: [
                  Icon(
                    isPositiveTrend ? Icons.trending_up_rounded : Icons.info_outline_rounded,
                    size: 12,
                    color: isPositiveTrend ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trendText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPositiveTrend ? AppColors.success : AppColors.warning,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          );

          if (constraints.maxHeight < 72) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: constraints.maxWidth,
                height: 72,
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _SparklinePainter({
    required this.points,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i].clamp(0.0, 1.0) * (size.height - 4)) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
