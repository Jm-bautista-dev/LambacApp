import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../providers/prescriptive_provider.dart';
import 'prescriptive_action_card.dart';

/// Dedicated Prescriptive Schedule View showing upcoming actions grouped chronologically
class PrescriptiveScheduleView extends ConsumerStatefulWidget {
  const PrescriptiveScheduleView({super.key});

  @override
  ConsumerState<PrescriptiveScheduleView> createState() => _PrescriptiveScheduleViewState();
}

class _PrescriptiveScheduleViewState extends ConsumerState<PrescriptiveScheduleView> {
  PrescriptiveActionType? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final schedule = ref.watch(prescriptiveScheduleProvider);
    final actionsAsync = ref.watch(prescriptiveActionsNotifierProvider);

    final filtered = _selectedTypeFilter == null
        ? schedule
        : schedule.where((a) => a.actionType == _selectedTypeFilter).toList();

    return Column(
      children: [
        // Action Type Filter Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              AppChip(
                label: 'All Scheduled (${schedule.length})',
                isSelected: _selectedTypeFilter == null,
                isSmall: true,
                onSelected: (_) => setState(() => _selectedTypeFilter = null),
              ),
              const SizedBox(width: 6),
              AppChip(
                label: 'Roast Batches',
                isSelected: _selectedTypeFilter == PrescriptiveActionType.roastBatch,
                isSmall: true,
                onSelected: (_) => setState(() => _selectedTypeFilter = PrescriptiveActionType.roastBatch),
              ),
              const SizedBox(width: 6),
              AppChip(
                label: 'Raw Bean Restock',
                isSelected: _selectedTypeFilter == PrescriptiveActionType.restockRawBeans,
                isSmall: true,
                onSelected: (_) => setState(() => _selectedTypeFilter = PrescriptiveActionType.restockRawBeans),
              ),
              const SizedBox(width: 6),
              AppChip(
                label: 'Menu Promos',
                isSelected: _selectedTypeFilter == PrescriptiveActionType.menuPromotion,
                isSmall: true,
                onSelected: (_) => setState(() => _selectedTypeFilter = PrescriptiveActionType.menuPromotion),
              ),
            ],
          ),
        ),

        // Scheduled Content
        Expanded(
          child: actionsAsync.when(
            data: (_) {
              if (filtered.isEmpty) {
                return _buildEmptyState(isDark);
              }

              final groups = _groupByDate(filtered);

              return RefreshIndicator(
                onRefresh: () async => ref.read(prescriptiveActionsNotifierProvider.notifier).loadActions(),
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                child: ListView.builder(
                  padding: AppSpacing.screenPadding,
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.brandAmber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                group.title.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Cards in group
                        ...group.actions.map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PrescriptiveActionCard(
                              action: action,
                              onStart: () {
                                ref.read(prescriptiveActionsNotifierProvider.notifier).updateStatus(
                                      actionId: action.id,
                                      toStatus: PrescriptiveActionStatus.inProgress,
                                      note: 'Started by operator from Schedule',
                                    );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Failed to load schedule: $err',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<({String title, List<PrescriptiveActionModel> actions})> _groupByDate(
      List<PrescriptiveActionModel> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final todayActions = <PrescriptiveActionModel>[];
    final tomorrowActions = <PrescriptiveActionModel>[];
    final thisWeekActions = <PrescriptiveActionModel>[];
    final upcomingActions = <PrescriptiveActionModel>[];

    for (final a in list) {
      final date = a.scheduledAt ?? a.createdAt;
      final actionDate = DateTime(date.year, date.month, date.day);

      if (actionDate == today) {
        todayActions.add(a);
      } else if (actionDate == tomorrow) {
        tomorrowActions.add(a);
      } else if (actionDate.isAfter(tomorrow) && actionDate.isBefore(weekEnd)) {
        thisWeekActions.add(a);
      } else {
        upcomingActions.add(a);
      }
    }

    final groups = <({String title, List<PrescriptiveActionModel> actions})>[];
    if (todayActions.isNotEmpty) groups.add((title: 'Today', actions: todayActions));
    if (tomorrowActions.isNotEmpty) groups.add((title: 'Tomorrow', actions: tomorrowActions));
    if (thisWeekActions.isNotEmpty) groups.add((title: 'This Week', actions: thisWeekActions));
    if (upcomingActions.isNotEmpty) groups.add((title: 'Upcoming', actions: upcomingActions));

    if (groups.isEmpty && list.isNotEmpty) {
      groups.add((title: 'All Scheduled', actions: list));
    }

    return groups;
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 40,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
            AppSpacing.vSpaceMd,
            Text(
              'No Scheduled Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Actions scheduled from the Prescriptive Recommendations tab will appear in this timeline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
