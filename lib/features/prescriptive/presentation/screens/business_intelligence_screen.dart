import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../analytics/presentation/widgets/centralized_pipeline_card.dart';
import '../../../analytics/presentation/widgets/data_quality_audit_card.dart';
import '../../../analytics/presentation/widgets/forecast_readiness_card.dart';
import '../../../analytics/presentation/widgets/system_health_status_card.dart';
import '../../../forecasting/presentation/screens/forecasting_screen.dart';
import '../../data/models/prescriptive_recommendation_model.dart';
import '../providers/prescriptive_provider.dart';
import '../widgets/prescriptive_history_view.dart';
import '../widgets/prescriptive_queue_view.dart';
import '../widgets/prescriptive_schedule_view.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/unified_bi_tabs.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';

/// Unified Business Intelligence Hub (Overview Pipeline + Descriptive + Forecasting + Prescriptive + Data Quality)
class BusinessIntelligenceScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final int initialPrescriptiveSubTab;

  const BusinessIntelligenceScreen({
    super.key,
    this.initialTabIndex = 0, // Default to Overview Pipeline
    this.initialPrescriptiveSubTab = 0, // Default to Recommendations
  });

  @override
  ConsumerState<BusinessIntelligenceScreen> createState() => _BusinessIntelligenceScreenState();
}

class _BusinessIntelligenceScreenState extends ConsumerState<BusinessIntelligenceScreen> {
  late int _selectedTab;
  late int _selectedPrescriptiveSubTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _selectedPrescriptiveSubTab = widget.initialPrescriptiveSubTab;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final recommendationsAsync = ref.watch(prescriptiveRecommendationsProvider);
    final priorityFilter = ref.watch(prescriptivePriorityFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        showBackButton: false,
        title: 'Business Intelligence Hub',
        subtitle: 'Lambac Coffee Roastery',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh All Analytics',
            onPressed: () {
              ref.refresh(prescriptiveRecommendationsProvider);
              ref.read(prescriptiveActionsNotifierProvider.notifier).loadActions();
            },
          ),
        ],
      ),
      body: CinematicRoasteryBackground.subtle(
        showAmbientParticles: false,
        showFloatingBean: false,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 860,
            child: Column(
            children: [
              // Segmented BI Switcher Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: UnifiedBiTabs(
                  key: SpotlightKeys.adminBiTabs,
                  selectedIndex: _selectedTab,
                  onTabSelected: (index) => setState(() => _selectedTab = index),
                ),
              ),

              // View Area
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    // Tab 0: Overview & Pipeline Architecture
                    _buildOverviewPipelineTab(context, isDark),

                    // Tab 1: Descriptive Analytics ("What Happened?")
                    const AnalyticsScreen(showAppBar: false),

                    // Tab 2: Forecasting / ML ("What May Happen?")
                    const ForecastingScreen(showAppBar: false),

                    // Tab 3: Prescriptive Analytics & Action Management ("What Should We Do?")
                    _buildPrescriptiveHub(context, isDark, recommendationsAsync, priorityFilter),

                    // Tab 4: Data Quality & Forecast Readiness
                    _buildDataQualityTab(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildOverviewPipelineTab(BuildContext context, bool isDark) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Container(
          key: SpotlightKeys.adminForecastingCard,
          child: const CentralizedPipelineCard(),
        ),
        AppSpacing.vSpaceLg,
        Container(
          key: SpotlightKeys.adminPrescriptiveCard,
          child: const DataQualityAuditCard(),
        ),
        AppSpacing.vSpaceLg,
        const SystemHealthStatusCard(),
        AppSpacing.vSpaceLg,
        const ForecastReadinessCard(),
        AppSpacing.vSpaceXxl,
      ],
    );
  }

  Widget _buildPrescriptiveHub(
    BuildContext context,
    bool isDark,
    AsyncValue<List<PrescriptiveRecommendationModel>> recommendationsAsync,
    RecommendationPriority? priorityFilter,
  ) {
    final scheduleCount = ref.watch(prescriptiveScheduleProvider).length;
    final queueCount = ref.watch(prescriptiveQueueProvider).length;

    final subTabs = [
      (label: 'Recommendations', icon: Icons.lightbulb_outline_rounded, count: null),
      (label: 'Schedule', icon: Icons.calendar_month_rounded, count: scheduleCount),
      (label: 'Action Queue', icon: Icons.playlist_play_rounded, count: queueCount),
      (label: 'History & Audit', icon: Icons.history_rounded, count: null),
    ];

    return Column(
      children: [
        // Prescriptive Sub-Module Navigation Switcher
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: List.generate(subTabs.length, (idx) {
                  final isSelected = _selectedPrescriptiveSubTab == idx;
                  final item = subTabs[idx];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedPrescriptiveSubTab = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.brandAmber.withOpacity(0.2) : AppColors.brandAmber.withOpacity(0.15))
                            : Colors.transparent,
                        borderRadius: AppRadius.radiusSm,
                        border: isSelected
                            ? Border.all(
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                width: 1.0,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 13,
                            color: isSelected
                                ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                          if (item.count != null && item.count! > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppColors.brandAmber : AppColors.brandAmberDark)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${item.count}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        // Sub-Tab Content View Area
        Expanded(
          child: IndexedStack(
            index: _selectedPrescriptiveSubTab,
            children: [
              // Sub-Tab 0: Recommendations List
              _buildRecommendationsSubTab(context, isDark, recommendationsAsync, priorityFilter),

              // Sub-Tab 1: Dedicated Action Schedule
              const PrescriptiveScheduleView(),

              // Sub-Tab 2: Operational Action Queue
              const PrescriptiveQueueView(),

              // Sub-Tab 3: History & Audit Log
              const PrescriptiveHistoryView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSubTab(
    BuildContext context,
    bool isDark,
    AsyncValue<List<PrescriptiveRecommendationModel>> recommendationsAsync,
    RecommendationPriority? priorityFilter,
  ) {
    return recommendationsAsync.when(
      data: (recommendations) {
        final filtered = priorityFilter == null
            ? recommendations
            : recommendations.where((r) => r.priority == priorityFilter).toList();

        return Column(
          children: [
            // Priority Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  AppChip(
                    label: 'All Priorities (${recommendations.length})',
                    isSelected: priorityFilter == null,
                    isSmall: true,
                    onSelected: (_) {
                      ref.read(prescriptivePriorityFilterProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 6),
                  AppChip(
                    label: 'High Priority',
                    isSelected: priorityFilter == RecommendationPriority.high,
                    isSmall: true,
                    onSelected: (_) {
                      ref.read(prescriptivePriorityFilterProvider.notifier).state =
                          RecommendationPriority.high;
                    },
                  ),
                  const SizedBox(width: 6),
                  AppChip(
                    label: 'Medium Priority',
                    isSelected: priorityFilter == RecommendationPriority.medium,
                    isSmall: true,
                    onSelected: (_) {
                      ref.read(prescriptivePriorityFilterProvider.notifier).state =
                          RecommendationPriority.medium;
                    },
                  ),
                  const SizedBox(width: 6),
                  AppChip(
                    label: 'Low Priority',
                    isSelected: priorityFilter == RecommendationPriority.low,
                    isSmall: true,
                    onSelected: (_) {
                      ref.read(prescriptivePriorityFilterProvider.notifier).state =
                          RecommendationPriority.low;
                    },
                  ),
                ],
              ),
            ),

            // Recommendations List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(prescriptiveRecommendationsProvider);
                  ref.read(prescriptiveActionsNotifierProvider.notifier).loadActions();
                },
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                child: ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => AppSpacing.vSpaceLg,
                  itemBuilder: (context, index) {
                    return RecommendationCard(
                      recommendation: filtered[index],
                      onNavigateToSchedule: () {
                        setState(() => _selectedPrescriptiveSubTab = 1);
                      },
                      onNavigateToQueue: () {
                        setState(() => _selectedPrescriptiveSubTab = 2);
                      },
                      onNavigateToHistory: () {
                        setState(() => _selectedPrescriptiveSubTab = 3);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorView(
        title: 'Unable to Load Recommendations',
        message: err.toString(),
        onRetry: () => ref.refresh(prescriptiveRecommendationsProvider),
      ),
    );
  }

  Widget _buildDataQualityTab(BuildContext context, bool isDark) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: const [
        DataQualityAuditCard(),
        AppSpacing.vSpaceLg,
        ForecastReadinessCard(),
        AppSpacing.vSpaceLg,
        SystemHealthStatusCard(),
        AppSpacing.vSpaceXxl,
      ],
    );
  }
}
