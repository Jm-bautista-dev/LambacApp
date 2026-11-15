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
import '../../data/datasources/admin_tutorial_data.dart';
import '../../data/models/admin_tutorial_step_model.dart';
import '../providers/admin_tutorial_provider.dart';
import '../spotlight/admin_spotlight_provider.dart';
import 'admin_tutorial_screen.dart';

/// Production Administrator & Business Intelligence Help & Operations Guide Hub
class AdminHelpGuideScreen extends ConsumerStatefulWidget {
  const AdminHelpGuideScreen({super.key});

  @override
  ConsumerState<AdminHelpGuideScreen> createState() => _AdminHelpGuideScreenState();
}

class _AdminHelpGuideScreenState extends ConsumerState<AdminHelpGuideScreen> {
  AdminTutorialChapter? _selectedChapter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _launchTutorialStep(int stepIndex) {
    ref.read(adminSpotlightProvider.notifier).startTour(
          isReplay: true,
          startStep: stepIndex,
        );
    context.go(AppRoutes.adminDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tutorialState = ref.watch(adminTutorialNotifierProvider);
    final allSteps = AdminTutorialData.steps;

    final filteredSteps = allSteps.where((step) {
      if (_selectedChapter != null && step.chapter != _selectedChapter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = step.title.toLowerCase().contains(query);
        final matchesSubtitle = step.subtitle.toLowerCase().contains(query);
        final matchesArea = step.highlightArea.toLowerCase().contains(query);
        final matchesChapter = step.chapter.displayName.toLowerCase().contains(query);
        final matchesPoints = step.keyPoints.any((p) => p.toLowerCase().contains(query));
        return matchesTitle || matchesSubtitle || matchesArea || matchesChapter || matchesPoints;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF100D0B) : const Color(0xFFFAF7F2),
      appBar: const LambacAppBar(
        title: 'BI & Executive System Guide',
        subtitle: 'Roastery operations, forecasting & prescriptive SOP',
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 760,
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // --------------------------------------------------------------
              // 1. Replay Interactive Tour Hero Card
              // --------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2C1E14), const Color(0xFF1C130D)]
                        : [const Color(0xFF332014), const Color(0xFF22140A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.radiusXl,
                  border: Border.all(
                    color: AppColors.brandAmber.withValues(alpha: 0.6),
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
                            color: AppColors.brandAmber,
                            borderRadius: AppRadius.radiusPill,
                          ),
                          child: const Text(
                            'EXECUTIVE BI HUB',
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
                              color: AppColors.cremaGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.cremaGold.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, color: AppColors.cremaGold, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: AppColors.cremaGold,
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
                      'Executive System & BI Walkthrough',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    AppSpacing.vSpaceXs,
                    const Text(
                      'Replay the full 22-step executive tour covering executive KPIs, staff oversight, full single-origin catalog, 4-tier BI pipeline, and prescriptive actions.',
                      style: TextStyle(
                        color: Color(0xFFEADBCE),
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
                              ref.read(adminSpotlightProvider.notifier).startTour();
                              context.go(AppRoutes.adminDashboard);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton.outlined(
                            text: '22-Step SOP Guide',
                            leadingIcon: const Icon(Icons.menu_book_rounded, size: 18),
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
                  hintText: 'Search BI, forecasting, staff or SOP guide...',
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

              // Chapter Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildChapterFilterChip(
                      label: 'All Chapters (${allSteps.length})',
                      isSelected: _selectedChapter == null,
                      onTap: () => setState(() => _selectedChapter = null),
                      isDark: isDark,
                    ),
                    ...AdminTutorialChapter.values.map((chapter) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildChapterFilterChip(
                          label: chapter.displayName,
                          icon: chapter.icon,
                          isSelected: _selectedChapter == chapter,
                          onTap: () => setState(() => _selectedChapter = chapter),
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
                'EXECUTIVE CHAPTERS & MODULES (${filteredSteps.length})',
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
                      const Icon(Icons.search_off_rounded, size: 36, color: AppColors.brandAmberLight),
                      AppSpacing.vSpaceSm,
                      Text(
                        'No executive guide modules match "$_searchQuery"',
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.brandAmber.withValues(alpha: isDark ? 0.25 : 0.15),
                              borderRadius: AppRadius.radiusMd,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              step.icon,
                              size: 19,
                              color: AppColors.brandAmberLight,
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
                                        color: AppColors.brandAmberLight,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '• ${step.chapter.displayName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                        ),
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
                            color: AppColors.brandAmberLight,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              AppSpacing.vSpaceXl,

              // --------------------------------------------------------------
              // 4. Standard Operating Procedures (SOP) & BI Analytics FAQs
              // --------------------------------------------------------------
              Text(
                'EXECUTIVE SOPS & BI METHODOLOGY FAQS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              AppSpacing.vSpaceSm,

              _buildSopAccordion(
                title: 'How do date filters calculate time horizons in BI?',
                content:
                    '• Today: Current calendar business day starting at 00:00.\n'
                    '• 7 Days: Current day plus preceding 6 historical days (7 calendar days total).\n'
                    '• 15 Days: Current day plus preceding 14 historical days.\n'
                    '• 30 Days: Current day plus preceding 29 historical days.\n\n'
                    'Selecting a filter recalculates the underlying aggregation across sales receipts, units sold, and average order value (AOV) in real time.',
                isDark: isDark,
              ),
              _buildSopAccordion(
                title: 'What does MAPE mean and how should it be interpreted?',
                content:
                    'Mean Absolute Percentage Error (MAPE) quantifies relative forecast error, expressing the average deviation between forecasted demand and actual sales as a percentage. It represents forecast error rather than absolute model perfection. Lower MAPE indicates closer alignment with historical demand patterns.',
                isDark: isDark,
              ),
              _buildSopAccordion(
                title: 'How does the system handle insufficient historical sales data?',
                content:
                    'When a newly introduced single-origin bean or seasonal blend has fewer historical sales transactions than the statistical minimum, the system displays an explicit "Insufficient Historical Data" indicator rather than fabricating inaccurate projections.',
                isDark: isDark,
              ),
              _buildSopAccordion(
                title: 'What is the complete Prescriptive Analytics lifecycle?',
                content:
                    '1. Prescriptive Engine generates a data-driven recommendation based on descriptive velocity and forecasting spikes.\n'
                    '2. Administrator reviews supporting metrics, priority, and rationale.\n'
                    '3. Administrator selects "Schedule" (calendar planned) or "Add to Queue" (immediate operational task).\n'
                    '4. Staff executes the action (roast batch, cold brew prep, reorder).\n'
                    '5. Action is marked Completed and logged in Action History for full audit traceability.',
                isDark: isDark,
              ),
              _buildSopAccordion(
                title: 'How does Staff account provisioning and security work?',
                content:
                    'Administrators create employee profiles by providing legal name, official email, and assigned operational role (Barista / Staff). New staff members are issued a temporary credential and are enforced to establish a private secure password on their initial login. Admin can toggle account activation status or revoke access instantly.',
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
                      backgroundColor: AppColors.brandAmber,
                      child: Icon(Icons.insights_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need BI Support?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Open the Executive Inbox to coordinate with roastery supervisors or data operations.',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton.primary(
                      text: 'Open Inbox',
                      size: AppButtonSize.small,
                      onPressed: () => context.push(AppRoutes.staffInbox),
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

  Widget _buildChapterFilterChip({
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
              ? AppColors.brandAmber
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: AppRadius.radiusPill,
          border: Border.all(
            color: isSelected
                ? AppColors.brandAmber
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
          backgroundColor: isDark ? const Color(0xFF1E1612) : const Color(0xFFFBF8F4),
          iconColor: AppColors.brandAmberLight,
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
