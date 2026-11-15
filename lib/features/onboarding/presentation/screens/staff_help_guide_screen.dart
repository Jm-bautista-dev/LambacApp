import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/datasources/staff_tutorial_data.dart';
import '../../data/models/staff_tutorial_step_model.dart';
import '../providers/staff_tutorial_provider.dart';
import '../spotlight/barista_spotlight_provider.dart';

/// Production Barista & Staff Help & Operations Guide Hub
class StaffHelpGuideScreen extends ConsumerStatefulWidget {
  const StaffHelpGuideScreen({super.key});

  @override
  ConsumerState<StaffHelpGuideScreen> createState() => _StaffHelpGuideScreenState();
}

class _StaffHelpGuideScreenState extends ConsumerState<StaffHelpGuideScreen> {
  StaffTutorialCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _launchTutorialStep(int stepIndex) {
    ref.read(baristaSpotlightProvider.notifier).startTour(
          isReplay: true,
          startStep: stepIndex,
        );
    context.go(AppRoutes.staffOrders);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tutorialState = ref.watch(staffTutorialNotifierProvider);
    final allSteps = StaffTutorialData.steps;

    final filteredSteps = allSteps.where((step) {
      if (_selectedCategory != null && step.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = step.title.toLowerCase().contains(query);
        final matchesSubtitle = step.subtitle.toLowerCase().contains(query);
        final matchesArea = step.highlightArea.toLowerCase().contains(query);
        final matchesPoints = step.keyPoints.any((p) => p.toLowerCase().contains(query));
        return matchesTitle || matchesSubtitle || matchesArea || matchesPoints;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF110E0C) : const Color(0xFFF7F9F8),
      appBar: const LambacAppBar(
        title: 'Help & Operations Guide',
        subtitle: 'Barista SOP, ticket workflows & POS guides',
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 720,
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // --------------------------------------------------------------
              // 1. Replay Interactive Operations Hero Card
              // --------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF17241C) : const Color(0xFF1E2F24),
                  borderRadius: AppRadius.radiusXl,
                  border: Border.all(
                    color: AppColors.matchaSage,
                    width: 1.2,
                  ),
                  boxShadow: isDark ? AppShadows.cardDark : AppShadows.elevatedLight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.matchaSage,
                            borderRadius: AppRadius.radiusPill,
                          ),
                          child: const Text(
                            'STAFF OPERATIONS SOP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (tutorialState.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Certified',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    AppSpacing.vSpaceMd,
                    const Text(
                      'Barista & Staff Operations Walkthrough',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    AppSpacing.vSpaceXs,
                    const Text(
                      'Replay the full 20-step interactive training covering live order queues, brewing handoffs, POS entry, and customer concierge.',
                      style: TextStyle(
                        color: Color(0xFFD4E2D8),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    AppSpacing.vSpaceLg,
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.primary(
                            text: 'Live Spotlight Tour',
                            leadingIcon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                            onPressed: () {
                              ref.read(baristaSpotlightProvider.notifier).startTour();
                              context.go(AppRoutes.staffOrders);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton.secondary(
                            text: 'SOP Walkthrough',
                            leadingIcon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                            onPressed: () => _launchTutorialStep(0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              AppSpacing.vSpaceXl,

              // --------------------------------------------------------------
              // 2. Search & Filter Bar
              // --------------------------------------------------------------
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search operations guide (e.g., POS, pickup, refund)...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.radiusLg,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.radiusLg,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),

              AppSpacing.vSpaceMd,

              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildCategoryFilterChip(
                      label: 'All Topics (${allSteps.length})',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                      isDark: isDark,
                    ),
                    ...StaffTutorialCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildCategoryFilterChip(
                          label: cat.displayName,
                          icon: cat.icon,
                          isSelected: _selectedCategory == cat,
                          onTap: () => setState(() => _selectedCategory = cat),
                          isDark: isDark,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              AppSpacing.vSpaceLg,

              // --------------------------------------------------------------
              // 3. Step-by-Step Interactive Guide Directory
              // --------------------------------------------------------------
              Text(
                'OPERATIONAL TOPICS (${filteredSteps.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              AppSpacing.vSpaceSm,

              if (filteredSteps.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, size: 36, color: AppColors.matchaSageLight),
                      AppSpacing.vSpaceSm,
                      Text(
                        'No operational topics match "$_searchQuery"',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filteredSteps.map((step) {
                  final globalIndex = allSteps.indexOf(step);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => _launchTutorialStep(globalIndex),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.matchaSage.withValues(alpha: isDark ? 0.25 : 0.15),
                              borderRadius: AppRadius.radiusMd,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              step.icon,
                              size: 18,
                              color: AppColors.matchaSageLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'STEP ${step.stepNumber}',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: AppColors.matchaSageLight,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${step.category.displayName}',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.matchaSageLight,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              AppSpacing.vSpaceXl,

              // --------------------------------------------------------------
              // 4. Standard Operating Procedures (SOP) & FAQs
              // --------------------------------------------------------------
              Text(
                'STANDARD OPERATING PROCEDURES (SOP)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              AppSpacing.vSpaceSm,

              _buildSopAccordion(
                title: 'When should I change order status to "Ready for Pickup"?',
                content:
                    'Only mark an order as "Ready for Pickup" after the beverages/beans are completely brewed, packaged, placed on the pickup counter/shelf, and verified. Once marked, the customer immediately receives a push notification.',
                isDark: isDark,
              ),
              _buildSopAccordion(
                title: 'How does Pay-at-Counter settlement work?',
                content:
                    'When customers select Pay-at-Counter, their order arrives in the Queue as unpaid. Do NOT release drinks until payment (Cash, GCash QR, or Card) has been physically tendered and confirmed at the register.',
                isDark: isDark,
              ),
              _buildSopAccordion(
                title: 'How to handle customer inquiries in Concierge Chat?',
                content:
                    'Lambac AI automatically responds to routine questions (hours, location, brewing recipes). When a customer requests order adjustments or special bean reservations, staff can reply directly in the shared conversation.',
                isDark: isDark,
              ),
              _buildSopAccordion(
                title: 'How are customer mobile pickup orders synchronized?',
                content:
                    'All customer pickup orders arrive instantly in the Queue tab. Advancing order status (Preparing, Ready for Pickup, Completed) updates customer live order tracking in real time.',
                isDark: isDark,
              ),

              AppSpacing.vSpaceXxl,

              // --------------------------------------------------------------
              // 5. Direct Quick Action Hub
              // --------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: AppRadius.radiusLg,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.matchaSage,
                      child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Lead Support?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Open Concierge chat to coordinate with store supervisors or technical support.',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton.primary(
                      text: 'Open Chat',
                      size: AppButtonSize.small,
                      onPressed: () => context.push(AppRoutes.staffChat),
                    ),
                  ],
                ),
              ),

              AppSpacing.vSpaceXxl,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.matchaSage
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: AppRadius.radiusPill,
          border: Border.all(
            color: isSelected
                ? AppColors.matchaSage
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSopAccordion({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: AppRadius.radiusMd,
        child: ExpansionTile(
          collapsedBackgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          backgroundColor: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF9FBF9),
          iconColor: AppColors.matchaSageLight,
          collapsedIconColor: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
