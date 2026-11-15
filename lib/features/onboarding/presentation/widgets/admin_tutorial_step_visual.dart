import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/models/admin_tutorial_step_model.dart';

/// Renders luxury interactive executive previews for each Administrator / BI tutorial step
class AdminTutorialStepVisual extends StatelessWidget {
  final AdminTutorialVisualType visualType;
  final bool isDark;

  const AdminTutorialStepVisual({
    super.key,
    required this.visualType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        decoration: TextDecoration.none,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontFamily: 'Inter',
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 145, maxHeight: 185),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1612) : const Color(0xFFFBF8F4),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isDark
                ? AppColors.brandAmber.withValues(alpha: 0.35)
                : AppColors.brandAmber.withValues(alpha: 0.25),
            width: 1.0,
          ),
          boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
        ),
        child: Center(
          child: _buildVisualContent(context),
        ),
      ),
    );
  }

  Widget _buildVisualContent(BuildContext context) {
    return switch (visualType) {
      AdminTutorialVisualType.adminWelcomeBanner => _buildWelcomeVisual(),
      AdminTutorialVisualType.adminDashboardKpis => _buildDashboardKpisVisual(),
      AdminTutorialVisualType.adminDateFiltersDemo => _buildDateFiltersVisual(),
      AdminTutorialVisualType.adminOrdersOperations => _buildOrdersOperationsVisual(),
      AdminTutorialVisualType.adminProductsCatalog => _buildProductsCatalogVisual(),
      AdminTutorialVisualType.adminEmployeeManagement => _buildEmployeeManagementVisual(),
      AdminTutorialVisualType.adminSecurityGovernance => _buildSecurityGovernanceVisual(),
      AdminTutorialVisualType.adminBiPipelineOverview => _buildBiPipelineVisual(),
      AdminTutorialVisualType.adminDescriptiveMetrics => _buildDescriptiveMetricsVisual(),
      AdminTutorialVisualType.adminDescriptiveDateFilters => _buildDescriptiveDateRangesVisual(),
      AdminTutorialVisualType.adminForecastingChart => _buildForecastingChartVisual(),
      AdminTutorialVisualType.adminForecastingMetricsMaeMape => _buildForecastingMetricsVisual(),
      AdminTutorialVisualType.adminInsufficientDataHandling => _buildInsufficientDataVisual(),
      AdminTutorialVisualType.adminPrescriptiveRecommendationCard => _buildRecommendationCardVisual(),
      AdminTutorialVisualType.adminPrescriptiveActionWorkflow => _buildActionWorkflowVisual(),
      AdminTutorialVisualType.adminPrescriptiveScheduleTimeline => _buildScheduleTimelineVisual(),
      AdminTutorialVisualType.adminPrescriptiveActionQueue => _buildActionQueueVisual(),
      AdminTutorialVisualType.adminPrescriptiveActionHistory => _buildActionHistoryVisual(),
      AdminTutorialVisualType.adminAnalyticsTraceability => _buildAnalyticsTraceabilityVisual(),
      AdminTutorialVisualType.adminCustomerConcierge => _buildCustomerConciergeVisual(),
      AdminTutorialVisualType.adminNotificationsCenter => _buildNotificationsCenterVisual(),
      AdminTutorialVisualType.adminProfileSettings => _buildProfileSettingsVisual(),
      AdminTutorialVisualType.adminHelpReplayAccess => _buildHelpReplayVisual(),
    };
  }

  // 1. BI Hub Welcome Banner
  Widget _buildWelcomeVisual() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF261D17) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.brandAmber,
              width: 2.0,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.auto_graph_rounded,
            size: 28,
            color: AppColors.brandAmberLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'LAMBAC BI & GOVERNANCE HUB',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.brandAmber.withValues(alpha: 0.2),
            borderRadius: AppRadius.radiusPill,
          ),
          child: const Text(
            'EXECUTIVE COMMAND & ANALYTICS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.brandAmberLight,
            ),
          ),
        ),
      ],
    );
  }

  // 2. Executive Dashboard KPIs
  Widget _buildDashboardKpisVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildKpiCard('Revenue', '₱148.2k', AppColors.brandAmber, '+18.4%'),
        _buildKpiCard('Orders', '84', AppColors.info, '+12'),
        _buildKpiCard('Active Beans', '12', AppColors.matchaSage, 'In Stock'),
        _buildKpiCard('Shift Staff', '4', AppColors.success, 'On Duty'),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color accent, String subtext) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              color: accent.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Multi-Period Dashboard Filters
  Widget _buildDateFiltersVisual() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Today', false),
          const SizedBox(width: 6),
          _buildFilterChip('Last 7 Days', true, accent: AppColors.brandAmber),
          const SizedBox(width: 6),
          _buildFilterChip('Last 15 Days', false),
          const SizedBox(width: 6),
          _buildFilterChip('Last 30 Days', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool active, {Color? accent}) {
    final actColor = accent ?? AppColors.brandAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? actColor.withValues(alpha: 0.25)
            : (isDark ? const Color(0xFF241D17) : Colors.white),
        borderRadius: AppRadius.radiusPill,
        border: Border.all(
          color: active ? actColor : (isDark ? Colors.white24 : Colors.black12),
          width: active ? 1.5 : 1.0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? (isDark ? Colors.white : actColor) : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  // 4. Operations & Orders Queue
  Widget _buildOrdersOperationsVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.brandAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ORDER #LMB-8921',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandAmberLight),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: const Text(
                  'READY FOR PICKUP',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '3x Mount Apo Washed (500g, Whole Bean)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pickup: 2:00 PM • Maria Clara', style: TextStyle(fontSize: 9.5)),
              Text(
                'UNPAID ₱1,740',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Product Catalog & Bean Management
  Widget _buildProductsCatalogVisual() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.brandAmber.withValues(alpha: 0.2),
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.brandAmber.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.coffee_rounded, size: 28, color: AppColors.brandAmberLight),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sagada Arabica Typica',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const Text(
                'Single-Origin • Medium Dark Roast • ₱620.00',
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: const Text(
                      'IN STOCK (24 kg)',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Cupping: 87.5 pts', style: TextStyle(fontSize: 8.5, color: AppColors.cremaGold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 6. Employee Management & Staff Accounts
  Widget _buildEmployeeManagementVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.matchaSage,
            child: Icon(Icons.badge_rounded, color: Colors.white, size: 18),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Jordan Lee (Lead Barista)',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Permissions: Process Orders, Walk-In POS, Inbox',
                  style: TextStyle(fontSize: 9.5),
                ),
                Text(
                  'Status: Active • Mandatory Password Setup: Done',
                  style: TextStyle(fontSize: 8.5, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. Role-Based Security Governance
  Widget _buildSecurityGovernanceVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRoleBox('Customer', 'Shopping & Chat', Colors.blueGrey),
        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white30),
        _buildRoleBox('Staff', 'Queue & POS', AppColors.matchaSage),
        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white30),
        _buildRoleBox('Admin', 'Governance & BI', AppColors.brandAmber),
      ],
    );
  }

  Widget _buildRoleBox(String role, String scope, Color accent) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: accent, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(role, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 2),
          Text(scope, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, height: 1.2)),
        ],
      ),
    );
  }

  // 8. 4-Tier BI Pipeline Architecture
  Widget _buildBiPipelineVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPipelineNode('1. Data', Icons.point_of_sale_rounded, AppColors.info),
        const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.cremaGold),
        _buildPipelineNode('2. Descr.', Icons.bar_chart_rounded, AppColors.brandAmber),
        const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.cremaGold),
        _buildPipelineNode('3. Forecast', Icons.timeline_rounded, AppColors.matchaSage),
        const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.cremaGold),
        _buildPipelineNode('4. Prescr.', Icons.lightbulb_rounded, AppColors.success),
      ],
    );
  }

  Widget _buildPipelineNode(String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // 9. Descriptive Metrics & Sales Trends
  Widget _buildDescriptiveMetricsVisual() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DESCRIPTIVE REVENUE CURVE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandAmberLight),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildTrendBar(24, 'M'),
                  _buildTrendBar(36, 'T'),
                  _buildTrendBar(48, 'W'),
                  _buildTrendBar(60, 'T'),
                  _buildTrendBar(75, 'F'),
                  _buildTrendBar(90, 'S'),
                  _buildTrendBar(85, 'S'),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 85,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF241D17) : Colors.white,
            borderRadius: AppRadius.radiusSm,
            border: Border.all(color: AppColors.brandAmber.withValues(alpha: 0.3)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('AOV Baseline', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600)),
              Text('₱685.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandAmber)),
              Text('+12.4% vs 30D', style: TextStyle(fontSize: 7.5, color: AppColors.success, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendBar(double height, String day) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height * 0.45,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.brandAmber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 2),
          Text(day, style: const TextStyle(fontSize: 7.5)),
        ],
      ),
    );
  }

  // 10. Descriptive Date Range Semantics
  Widget _buildDescriptiveDateRangesVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRangeRow('Today', 'Midnight to current moment of active day'),
          _buildRangeRow('Last 7 Days', 'Rolling 7-day window (today + 6 prior)'),
          _buildRangeRow('Last 15 Days', 'Bi-weekly inventory reorder period'),
          _buildRangeRow('Last 30 Days', 'Full monthly executive benchmark'),
        ],
      ),
    );
  }

  Widget _buildRangeRow(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.brandAmber.withValues(alpha: 0.2),
              borderRadius: AppRadius.radiusSm,
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.brandAmberLight),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(desc, style: const TextStyle(fontSize: 8.5)),
          ),
        ],
      ),
    );
  }

  // 11. Forecasting Dual-Curve Chart
  Widget _buildForecastingChartVisual() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DEMAND FORECAST (NEXT 7 DAYS)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandAmberLight),
            ),
            Text(
              'Mount Apo Washed',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF241D17) : Colors.white,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.matchaSage.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.show_chart_rounded, size: 30, color: AppColors.brandAmber),
              Text(
                'Historical Sales (──) + Projected Demand (- - -)\nProjected Weekend Peak: 42 bags',
                style: TextStyle(fontSize: 9, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 12. Forecasting Statistical Error Metrics
  Widget _buildForecastingMetricsVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMetricTile('MAE', '1.4 bags', 'Mean Absolute Error'),
        _buildMetricTile('RMSE', '2.1 bags', 'Outlier Penalty'),
        _buildMetricTile('MAPE', '7.8% Error', 'Relative Error Fit'),
      ],
    );
  }

  Widget _buildMetricTile(String title, String val, String subtitle) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: AppColors.brandAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandAmberLight)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 7.5)),
        ],
      ),
    );
  }

  // 13. Insufficient Data Handling
  Widget _buildInsufficientDataVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261E14) : const Color(0xFFFFF8EE),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.warning, width: 1.2),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 24, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'INSUFFICIENT HISTORICAL DATA',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.warning),
                ),
                Text(
                  'Newly launched micro-lot (<14 days history). System refrains from generating uncalibrated predictions.',
                  style: TextStyle(fontSize: 9, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 14. Prescriptive Recommendation Card
  Widget _buildRecommendationCardVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.brandAmber, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandAmber.withValues(alpha: 0.2),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: const Text('ROAST PREP • HIGH PRIORITY', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.brandAmberLight)),
              ),
              const Text('Projected: +34%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Roast 12kg of Benguet Typica for Weekend Rush', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const Text('Historical demand indicates Saturday surge. Current stock covers only 18 hours.', style: TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  // 15. Action Workflow
  Widget _buildActionWorkflowVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionStage('1. Evidence', Icons.psychology_rounded),
        const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brandAmber),
        _buildActionStage('2. Schedule', Icons.calendar_month_rounded),
        const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brandAmber),
        _buildActionStage('3. Execute', Icons.coffee_maker_rounded),
        const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brandAmber),
        _buildActionStage('4. Audit', Icons.verified_rounded),
      ],
    );
  }

  Widget _buildActionStage(String title, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.brandAmber.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppColors.brandAmberLight),
        ),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // 16. Schedule Timeline
  Widget _buildScheduleTimelineVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildScheduleItem('Fri 6:00 AM', 'Roast 12kg Benguet Typica', 'Lead Barista Jordan'),
          const Divider(height: 6),
          _buildScheduleItem('Sat 7:00 AM', 'Prep 18L Cold Brew Batch', 'Barista Team'),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String title, String staff) {
    return Row(
      children: [
        const Icon(Icons.access_time_filled_rounded, size: 12, color: AppColors.brandAmberLight),
        const SizedBox(width: 4),
        Text(time, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.brandAmberLight)),
        const SizedBox(width: 6),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600))),
        Text(staff, style: const TextStyle(fontSize: 8, color: Colors.white54)),
      ],
    );
  }

  // 17. Action Queue
  Widget _buildActionQueueVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQueueStatus('Pending', '2', AppColors.warning),
        _buildQueueStatus('Scheduled', '3', AppColors.info),
        _buildQueueStatus('In Progress', '1', AppColors.brandAmber),
        _buildQueueStatus('Completed', '28', AppColors.success),
      ],
    );
  }

  Widget _buildQueueStatus(String title, String count, Color color) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 18. Action History
  Widget _buildActionHistoryVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
      ),
      child: const Row(
        children: [
          Icon(Icons.task_alt_rounded, size: 22, color: AppColors.success),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Roast Batch #492 Completed', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.success)),
                Text('12kg Benguet Typica roasted by Jordan Lee • Stock updated to 36kg', style: TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 19. Analytics Traceability
  Widget _buildAnalyticsTraceabilityVisual() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text('Sales Spike\n(+28%)', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        Icon(Icons.arrow_forward_rounded, size: 12),
        Text('Forecast\n(+34% wknd)', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        Icon(Icons.arrow_forward_rounded, size: 12),
        Text('Prescription\n(Roast 12kg)', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        Icon(Icons.arrow_forward_rounded, size: 12),
        Text('Fulfilled\n(100% stock)', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.success)),
      ],
    );
  }

  // 20. Customer Concierge
  Widget _buildCustomerConciergeVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: AppColors.brandAmber, child: Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.white)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Admin Oversight: Concierge Thread #104', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800)),
                Text('Customer requested 20kg wholesale reservation. Admin replied directly.', style: TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 21. Notifications Center
  Widget _buildNotificationsCenterVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.brandAmber),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_active_rounded, size: 20, color: AppColors.brandAmber),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PROACTIVE REPLENISHMENT ALERT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.brandAmber)),
                Text('Mount Apo green bean inventory below 10kg threshold.', style: TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 22. Profile Settings
  Widget _buildProfileSettingsVisual() {
    return Row(
      children: [
        const CircleAvatar(radius: 18, backgroundColor: AppColors.brandAmber, child: Icon(Icons.security_rounded, size: 18, color: Colors.white)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Administrator System Console', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              Text('Role: Executive Administrator • Security Token: Active', style: TextStyle(fontSize: 9, color: isDark ? Colors.white70 : Colors.black54)),
              const Text('Full Governance Authority • BI Hub Access Enabled', style: TextStyle(fontSize: 8.5, color: AppColors.brandAmberLight, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // 23. Help Replay Access
  Widget _buildHelpReplayVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D17) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.brandAmber.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 22, color: AppColors.brandAmberLight),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Help & BI Operations Guide', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                Text('Replay full 22-step tour or explore 14 BI chapters anytime', style: TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
