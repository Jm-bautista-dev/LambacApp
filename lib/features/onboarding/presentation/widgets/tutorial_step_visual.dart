import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/models/tutorial_step_model.dart';

/// Renders luxury interactive visual previews for each tutorial step
class TutorialStepVisual extends StatelessWidget {
  final TutorialVisualType visualType;
  final bool isDark;

  const TutorialStepVisual({
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
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1512) : const Color(0xFFF7F3EE),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.9,
          ),
          boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(context).width - 64).clamp(240.0, 560.0),
              ),
              child: _buildVisualContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualContent(BuildContext context) {
    return switch (visualType) {
      TutorialVisualType.welcomeBanner => _buildWelcomeVisual(),
      TutorialVisualType.guestAuthCard => _buildGuestAuthVisual(),
      TutorialVisualType.navigationBarSimulator => _buildNavigationBarVisual(),
      TutorialVisualType.homeEditorialHeader => _buildHomeHeaderVisual(),
      TutorialVisualType.productCatalogCard => _buildProductCatalogVisual(),
      TutorialVisualType.productSensoryDetails => _buildSensoryDetailsVisual(),
      TutorialVisualType.sizeGrindCustomizer => _buildSizeGrindVisual(),
      TutorialVisualType.cartManagementDemo => _buildCartDemoVisual(),
      TutorialVisualType.pickupOnlyModel => _buildPickupOnlyVisual(),
      TutorialVisualType.pickupSchedulerDemo => _buildPickupSchedulerVisual(),
      TutorialVisualType.payAtCounterBadge => _buildPayAtCounterVisual(),
      TutorialVisualType.orderStatusTracker => _buildOrderStatusVisual(),
      TutorialVisualType.realtimeReceiptView => _buildReceiptVisual(),
      TutorialVisualType.notificationCenterAlert => _buildNotificationVisual(),
      TutorialVisualType.conciergeChatDemo => _buildConciergeChatVisual(),
      TutorialVisualType.aiAssistantDemo => _buildAiAssistantVisual(),
      TutorialVisualType.reviewsRatingCard => _buildReviewsVisual(),
      TutorialVisualType.memberLoyaltyCard => _buildLoyaltyVisual(),
      TutorialVisualType.helpReplayCard => _buildHelpReplayVisual(),
    };
  }

  Widget _buildWelcomeVisual() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.coffee_rounded,
            size: 30,
            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'LAMBAC COFFEE ROASTERY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        Text(
          'Artisan Japanese-Inspired Craftsmanship',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestAuthVisual() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.explore_outlined, size: 16, color: AppColors.cremaGold),
                    const SizedBox(width: 4),
                    Text(
                      'Guest Mode',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '• Browse Menu\n• View Tasting Notes\n• Inspect Prices',
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.35,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.arrow_forward_rounded,
          size: 16,
          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A201A) : const Color(0xFFF3ECE1),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 16, color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
                    const SizedBox(width: 4),
                    Text(
                      'Member Account',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '• Place Pickup Orders\n• Earn Beans Points\n• 1-on-1 Barista Chat',
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.35,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBarVisual() {
    final tabs = [
      (Icons.home_rounded, 'Home', false),
      (Icons.coffee_rounded, 'Roastery', false),
      (Icons.shopping_bag_rounded, 'Cart', true),
      (Icons.receipt_long_rounded, 'Orders', false),
      (Icons.person_rounded, 'Profile', false),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          final isCart = tab.$3;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    tab.$1,
                    size: 20,
                    color: isCart
                        ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  if (isCart)
                    Positioned(
                      top: -3,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                tab.$2,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCart ? FontWeight.w700 : FontWeight.w500,
                  color: isCart
                      ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHomeHeaderVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.brandAmber,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('L', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ohayō • Good morning',
                      style: TextStyle(fontSize: 9, color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
                    ),
                    Text(
                      'Coffee Enthusiast',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Icon(Icons.dark_mode_outlined, size: 14, color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: const Icon(Icons.notifications_active_rounded, size: 14, color: AppColors.brandAmber),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261D17) : const Color(0xFFEFE9DF),
              borderRadius: AppRadius.radiusPill,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Featured Harvest: Mt. Apo Honey', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                Text('Direct Trade ★', style: TextStyle(fontSize: 9, color: AppColors.brandAmber, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCatalogVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2E221A),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.coffee_rounded, color: AppColors.cremaGold, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.brandAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('LIGHT-MEDIUM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.brandAmber)),
                    ),
                    const SizedBox(width: 4),
                    const Text('MOUNT APO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Anaerobic Honey Reserve',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Wild raspberry, dark honey, cacao nibs',
                  style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Text(
            '₱480',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensoryDetailsVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSpecBadge('Elevation', '1,500 MASL', Icons.terrain_rounded),
        _buildSpecBadge('Process', 'Anaerobic Honey', Icons.water_drop_rounded),
        _buildSpecBadge('Varietal', 'Catimor / Typica', Icons.nature_rounded),
      ],
    );
  }

  Widget _buildSpecBadge(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
          const SizedBox(height: 3),
          Text(title, style: TextStyle(fontSize: 8.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          Text(val, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        ],
      ),
    );
  }

  Widget _buildSizeGrindVisual() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Size: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            _buildOptionPill('250g (Base)', true),
            const SizedBox(width: 4),
            _buildOptionPill('500g (+₱420)', false),
            const SizedBox(width: 4),
            _buildOptionPill('1kg (+₱900)', false),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text('Grind: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            _buildOptionPill('Whole Bean', true),
            const SizedBox(width: 4),
            _buildOptionPill('Espresso', false),
            const SizedBox(width: 4),
            _buildOptionPill('V60 Pourover', false),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionPill(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? AppColors.brandAmber : AppColors.brandAmber)
            : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface),
        borderRadius: AppRadius.radiusPill,
        border: Border.all(
          color: selected ? AppColors.brandAmber : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
      ),
    );
  }

  Widget _buildCartDemoVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mt. Apo Honey (250g, Whole Bean)',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₱480.00 × 1 bag',
                style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: AppRadius.radiusPill,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.remove, size: 12),
                SizedBox(width: 6),
                Text('1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                SizedBox(width: 6),
                Icon(Icons.add, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupOnlyVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D17) : const Color(0xFFF3ECE1),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront_rounded, size: 30, color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ROASTERY PICKUP ONLY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.brandAmber,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lambac Flagship Roastery • Ready at Counter',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Zero courier delays • Maximum bean freshness',
                  style: TextStyle(fontSize: 8.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupSchedulerVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildScheduleChip('+1 HOUR', 'Quick Prep', true),
        _buildScheduleChip('+3 HOURS', 'Afternoon', false),
        _buildScheduleChip('+5 HOURS', 'Evening', false),
        _buildScheduleChip('CUSTOM', 'Pick Slot', false),
      ],
    );
  }

  Widget _buildScheduleChip(String title, String subtitle, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.brandAmber : AppColors.brandAmber)
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isSelected ? AppColors.brandAmber : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 7.5,
              color: isSelected ? Colors.white70 : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayAtCounterVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E281E) : const Color(0xFFEEF7EE),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.success.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.point_of_sale_rounded, color: AppColors.success, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PAY AT COUNTER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'No online charge. Pay via Cash, GCash, or Card upon collection.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusVisual() {
    final stages = ['Placed', 'Confirmed', 'Preparing', 'Ready', 'Done'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(stages.length, (i) {
        final isDone = i <= 2;
        final isCurrent = i == 2;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? AppColors.brandAmber : (isDark ? AppColors.darkSurface : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? AppColors.brandAmber : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Text('${i + 1}', style: const TextStyle(fontSize: 8)),
            ),
            const SizedBox(height: 3),
            Text(
              stages[i],
              style: TextStyle(
                fontSize: 8,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? AppColors.brandAmber : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildReceiptVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order #LMB-8921',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                ),
              ),
              const SizedBox(height: 2),
              Text('Status: READY FOR PICKUP', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success)),
              Text('Pickup: Today • 3:30 PM', style: TextStyle(fontSize: 8.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: AppRadius.radiusPill,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.receipt_long, size: 12, color: AppColors.brandAmber),
                SizedBox(width: 3),
                Text('Receipt', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandAmber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, size: 16, color: AppColors.brandAmber),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order Ready for Pickup!',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Your Mount Apo Honey Reserve is packaged and waiting at counter.',
                  style: TextStyle(fontSize: 8.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConciergeChatVisual() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E221A) : const Color(0xFFF0EAE1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Barista: We recommend a 1:16 ratio on V60 for Mount Apo!', style: TextStyle(fontSize: 9)),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.brandAmber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('You: Perfect! Please grind medium-fine for pourover.', style: TextStyle(fontSize: 9, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildAiAssistantVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.cremaGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, size: 16, color: AppColors.brandAmber),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Lambac AI Coffee Concierge', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text(
                  'Specialized in Lambac roast profiles, brew guides & order policies.',
                  style: TextStyle(fontSize: 8.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('4.9', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.cremaGold)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star_rounded, size: 12, color: AppColors.cremaGold),
                Icon(Icons.star_rounded, size: 12, color: AppColors.cremaGold),
                Icon(Icons.star_rounded, size: 12, color: AppColors.cremaGold),
                Icon(Icons.star_rounded, size: 12, color: AppColors.cremaGold),
                Icon(Icons.star_rounded, size: 12, color: AppColors.cremaGold),
              ],
            ),
            const SizedBox(height: 2),
            Text('48 Roastery Reviews', style: TextStyle(fontSize: 8, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('★ V60 Pourover Tag', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.brandAmber)),
              SizedBox(height: 2),
              Text('"Incredible jasmine aroma & silky honey finish."', style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyVisual() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D17) : const Color(0xFFF3ECE1),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: AppColors.cremaGold, size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '120 Coffee Beans',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Text('Gold Tier Member', style: TextStyle(fontSize: 9, color: AppColors.brandAmber, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandAmber,
              borderRadius: AppRadius.radiusPill,
            ),
            child: const Text('Redeem Rewards', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpReplayVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.help_center_rounded, size: 24, color: AppColors.brandAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile → Help & Guide',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Replay this guide or explore quick reference sheets anytime.',
                  style: TextStyle(fontSize: 8.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
