import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/models/staff_tutorial_step_model.dart';

/// Renders luxury interactive operational visual previews for each Barista / Staff tutorial step
class StaffTutorialStepVisual extends StatelessWidget {
  final StaffTutorialVisualType visualType;
  final bool isDark;

  const StaffTutorialStepVisual({
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
          color: isDark ? const Color(0xFF161B18) : const Color(0xFFF2F7F4),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isDark ? AppColors.matchaSage.withValues(alpha: 0.3) : AppColors.matchaSage.withValues(alpha: 0.25),
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
      StaffTutorialVisualType.operationsWelcomeBanner => _buildOperationsWelcomeVisual(),
      StaffTutorialVisualType.staffNavigationBarSimulator => _buildNavigationBarVisual(),
      StaffTutorialVisualType.operationsKpiMetrics => _buildKpiMetricsVisual(),
      StaffTutorialVisualType.statusFilterTabsDemo => _buildStatusTabsVisual(),
      StaffTutorialVisualType.orderCardInspection => _buildOrderCardVisual(),
      StaffTutorialVisualType.acceptOrderStep => _buildAcceptOrderVisual(),
      StaffTutorialVisualType.preparingRoastingStep => _buildPreparingVisual(),
      StaffTutorialVisualType.markPreparedStep => _buildMarkPreparedVisual(),
      StaffTutorialVisualType.readyForPickupStep => _buildReadyPickupVisual(),
      StaffTutorialVisualType.handOffCompletedStep => _buildHandOffVisual(),
      StaffTutorialVisualType.realtimeSyncExplanation => _buildRealtimeSyncVisual(),
      StaffTutorialVisualType.payAtCounterSettlement => _buildPayAtCounterVisual(),
      StaffTutorialVisualType.walkInPosDemo => _buildWalkInPosVisual(),
      StaffTutorialVisualType.conciergeSharedInbox => _buildConciergeInboxVisual(),
      StaffTutorialVisualType.aiBaristaHandoffDemo => _buildAiHandoffVisual(),
      StaffTutorialVisualType.operationalNotifications => _buildNotificationsVisual(),
      StaffTutorialVisualType.staffProfileStation => _buildStationProfileVisual(),
      StaffTutorialVisualType.staffHelpReplayCard => _buildHelpReplayVisual(),
      StaffTutorialVisualType.operationalSafetyRules => _buildSafetyRulesVisual(),
    };
  }

  // 1. Operations Welcome
  Widget _buildOperationsWelcomeVisual() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.matchaSage,
              width: 2.0,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.coffee_maker_rounded,
            size: 28,
            color: AppColors.matchaSageLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'LAMBAC OPERATIONS HUB',
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
            color: AppColors.matchaSage.withValues(alpha: 0.2),
            borderRadius: AppRadius.radiusPill,
          ),
          child: const Text(
            'BARISTA & STAFF COMMAND CENTER',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.matchaSageLight,
            ),
          ),
        ),
      ],
    );
  }

  // 2. Staff Navigation Bar
  Widget _buildNavigationBarVisual() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2823) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: AppColors.matchaSage.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavTabItem(Icons.receipt_long_rounded, 'Queue', true),
          _buildNavTabItem(Icons.point_of_sale_rounded, 'POS', false),
          _buildNavTabItem(Icons.chat_bubble_outline_rounded, 'Concierge', false),
          _buildNavTabItem(Icons.badge_outlined, 'My Shift', false),
        ],
      ),
    );
  }

  Widget _buildNavTabItem(IconData icon, String label, bool isSelected) {
    final color = isSelected ? AppColors.matchaSageLight : (isDark ? Colors.white54 : Colors.black45);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.matchaSage.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: AppRadius.radiusSm,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  // 3. Operational KPI Metrics
  Widget _buildKpiMetricsVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMetricPill('New', '3', AppColors.warning),
        _buildMetricPill('Prep', '2', AppColors.brandAmber),
        _buildMetricPill('Ready', '4', AppColors.info),
        _buildMetricPill('Done', '18', AppColors.success),
      ],
    );
  }

  Widget _buildMetricPill(String title, String count, Color accent) {
    return Container(
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Status Filter Tabs
  Widget _buildStatusTabsVisual() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All Orders (27)', false),
          const SizedBox(width: 6),
          _buildFilterChip('Pending (3)', true, accent: AppColors.warning),
          const SizedBox(width: 6),
          _buildFilterChip('In Prep (2)', false, accent: AppColors.brandAmber),
          const SizedBox(width: 6),
          _buildFilterChip('Ready (4)', false, accent: AppColors.info),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool active, {Color? accent}) {
    final actColor = accent ?? AppColors.matchaSage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? actColor.withValues(alpha: 0.25)
            : (isDark ? const Color(0xFF1E2822) : Colors.white),
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

  // 5. Order Card Inspection
  Widget _buildOrderCardVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.matchaSage.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ORDER #1042',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.matchaSageLight),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: const Text(
                  'CONFIRMED',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '2x Kyoto Pour-Over (Medium Roast, V60 Grind)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 12, color: AppColors.matchaSageLight),
              const SizedBox(width: 4),
              Text(
                'Pickup at 10:30 AM • Alex Morgan',
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Accept Order Step
  Widget _buildAcceptOrderVisual() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Incoming Ticket',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
              ),
              const SizedBox(height: 2),
              Text(
                'Order #1045 • 1x Nitro Cold Brew',
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.matchaSage,
            borderRadius: AppRadius.radiusMd,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'Accept Order',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 7. Preparing / Roasting Step
  Widget _buildPreparingVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandAmber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brandAmber, width: 1.5),
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            size: 26,
            color: AppColors.brandAmber,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'IN PREPARATION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandAmber),
            ),
            const SizedBox(height: 2),
            Text(
              'Grinding & Brewing in Progress',
              style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: AppRadius.radiusSm,
              ),
              child: const Text(
                'Est. Prep Time: 4 mins',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.matchaSageLight),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 8. Mark Prepared Step
  Widget _buildMarkPreparedVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChecklistItem('Extraction yield verified', true),
          _buildChecklistItem('Cup labeled with Order #1042', true),
          _buildChecklistItem('Temperature & presentation QC passed', true),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            size: 16,
            color: AppColors.matchaSageLight,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 9. Ready For Pickup Step
  Widget _buildReadyPickupVisual() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.info, width: 1.5),
          ),
          child: const Icon(Icons.notifications_active_rounded, size: 24, color: AppColors.info),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'READY FOR PICKUP',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.info),
              ),
              const SizedBox(height: 2),
              Text(
                'Customer app displays pickup ready alert',
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 2),
              const Text(
                'Station Shelf #2 • Awaiting Customer',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.matchaSageLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 10. Hand Off Completed Step
  Widget _buildHandOffVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.handshake_rounded, size: 22, color: AppColors.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HANDED OFF & COMPLETED',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
                ),
                Text(
                  'Order verified with customer & marked fulfilled',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 11. Real-time Sync Explanation
  Widget _buildRealtimeSyncVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSyncNode(Icons.badge_rounded, 'Staff Action', AppColors.matchaSageLight),
        const Icon(Icons.sync_alt_rounded, size: 18, color: AppColors.brandAmberLight),
        _buildSyncNode(Icons.cloud_done_rounded, 'Cloud Sync', AppColors.brandAmber),
        const Icon(Icons.sync_alt_rounded, size: 18, color: AppColors.brandAmberLight),
        _buildSyncNode(Icons.smartphone_rounded, 'Customer App', AppColors.info),
      ],
    );
  }

  Widget _buildSyncNode(IconData icon, String label, Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  // 12. Pay At Counter Settlement
  Widget _buildPayAtCounterVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D18) : const Color(0xFFFFF7F0),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.brandAmber, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.brandAmber),
              SizedBox(width: 6),
              Text(
                'ORDER PLACED ≠ ORDER PAID',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.brandAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPayMethodTag('💵 Cash'),
              _buildPayMethodTag('📱 GCash / QR'),
              _buildPayMethodTag('💳 Card Terminal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayMethodTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  // 13. Walk-In POS Demo
  Widget _buildWalkInPosVisual() {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WALK-IN QUICK TILL',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.matchaSageLight),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildQuickAddButton('Espresso'),
                  const SizedBox(width: 4),
                  _buildQuickAddButton('Latte'),
                  const SizedBox(width: 4),
                  _buildQuickAddButton('Cold Brew'),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.matchaSage,
            borderRadius: AppRadius.radiusMd,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total', style: TextStyle(fontSize: 9, color: Colors.white70)),
              Text('₱380.00', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButton(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: AppColors.matchaSage.withValues(alpha: 0.4)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  // 14. Concierge Shared Inbox
  Widget _buildConciergeInboxVisual() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInboxTile('Alex Morgan', 'Can I change my pickup to 11:00 AM?', '1m ago', true),
        const SizedBox(height: 4),
        _buildInboxTile('Maria Santos', 'Thanks for grinding medium-fine!', '14m ago', false),
      ],
    );
  }

  Widget _buildInboxTile(String sender, String message, String time, bool unread) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(
          color: unread ? AppColors.matchaSage : (isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.matchaSage.withValues(alpha: 0.3),
            child: Text(sender[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sender, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    Text(time, style: TextStyle(fontSize: 8, color: isDark ? Colors.white54 : Colors.black45)),
                  ],
                ),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 15. AI + Barista Handoff
  Widget _buildAiHandoffVisual() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChatBubble('AI Concierge: Store opens at 7 AM daily.', isAi: true),
        const SizedBox(height: 4),
        _buildChatBubble('Barista Jordan: I have held your beans at the bar!', isAi: false),
      ],
    );
  }

  Widget _buildChatBubble(String text, {required bool isAi}) {
    final bg = isAi
        ? (isDark ? const Color(0xFF1B2329) : const Color(0xFFEBF3F8))
        : (isDark ? const Color(0xFF1A261E) : const Color(0xFFEAF5EE));
    final icon = isAi ? Icons.auto_awesome_rounded : Icons.coffee_rounded;
    final color = isAi ? Colors.blueAccent : AppColors.matchaSageLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // 16. Operational Notifications
  Widget _buildNotificationsVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.brandAmber),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_active_rounded, size: 22, color: AppColors.brandAmber),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NEW ORDER #1046 RECEIVED',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.brandAmber),
                ),
                Text(
                  'Customer requested pickup in 15 mins • 2 items',
                  style: TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 17. Staff Profile & Station
  Widget _buildStationProfileVisual() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.matchaSage,
          child: Icon(Icons.badge_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Barista Staff Station',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              Text(
                'Role: Certified Barista • Station 1',
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 2),
              const Text(
                'Active Permissions: Queue, POS, Inbox',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.matchaSageLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 18. Help & Operations Guide Replay
  Widget _buildHelpReplayVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.matchaSage.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 24, color: AppColors.matchaSageLight),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Help & Operations Guide',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Replay 20-Step Barista SOP anytime from My Shift',
                  style: TextStyle(fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 19. Operational Safety Rules
  Widget _buildSafetyRulesVisual() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSafetyBullet('1. Verify Pay-at-Counter before handing drinks.'),
        _buildSafetyBullet('2. Update order stage only when physically started.'),
        _buildSafetyBullet('3. Check special grind & temperature customer notes.'),
      ],
    );
  }

  Widget _buildSafetyBullet(String rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.matchaSageLight),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rule,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
