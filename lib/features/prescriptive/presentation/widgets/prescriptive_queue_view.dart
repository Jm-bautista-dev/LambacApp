import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../../data/models/prescriptive_recommendation_model.dart';
import '../providers/prescriptive_provider.dart';
import 'prescriptive_action_card.dart';

/// Operational Action Queue answering "What actions need attention right now?"
class PrescriptiveQueueView extends ConsumerStatefulWidget {
  const PrescriptiveQueueView({super.key});

  @override
  ConsumerState<PrescriptiveQueueView> createState() => _PrescriptiveQueueViewState();
}

class _PrescriptiveQueueViewState extends ConsumerState<PrescriptiveQueueView> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final queue = ref.watch(prescriptiveQueueProvider);
    final actionsAsync = ref.watch(prescriptiveActionsNotifierProvider);

    final filtered = switch (_selectedFilter) {
      'High Priority' => queue.where((a) => a.priority == RecommendationPriority.high).toList(),
      'In Progress' => queue.where((a) => a.status == PrescriptiveActionStatus.inProgress).toList(),
      'Queued' => queue.where((a) => a.status == PrescriptiveActionStatus.queued).toList(),
      'Scheduled' => queue.where((a) => a.status == PrescriptiveActionStatus.scheduled).toList(),
      _ => queue,
    };

    return Column(
      children: [
        // Filter Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              AppChip(
                label: 'All Queue (${queue.length})',
                isSelected: _selectedFilter == 'All',
                isSmall: true,
                onSelected: (_) => setState(() => _selectedFilter = 'All'),
              ),
              const SizedBox(width: 6),
              AppChip(
                label: 'High Priority',
                isSelected: _selectedFilter == 'High Priority',
                isSmall: true,
                onSelected: (_) => setState(() => _selectedFilter = 'High Priority'),
              ),
              const SizedBox(width: 6),
              AppChip(
                label: 'In Progress',
                isSelected: _selectedFilter == 'In Progress',
                isSmall: true,
                onSelected: (_) => setState(() => _selectedFilter = 'In Progress'),
              ),
              const SizedBox(width: 6),
              AppChip(
                label: 'Queued',
                isSelected: _selectedFilter == 'Queued',
                isSmall: true,
                onSelected: (_) => setState(() => _selectedFilter = 'Queued'),
              ),
              const SizedBox(width: 6),
              AppChip(
                label: 'Scheduled',
                isSelected: _selectedFilter == 'Scheduled',
                isSmall: true,
                onSelected: (_) => setState(() => _selectedFilter = 'Scheduled'),
              ),
            ],
          ),
        ),

        // Queue List
        Expanded(
          child: actionsAsync.when(
            data: (_) {
              if (filtered.isEmpty) {
                return _buildEmptyState(isDark);
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.read(prescriptiveActionsNotifierProvider.notifier).loadActions(),
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                child: ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => AppSpacing.vSpaceSm,
                  itemBuilder: (context, index) {
                    final action = filtered[index];
                    return PrescriptiveActionCard(
                      action: action,
                      onStart: () {
                        ref.read(prescriptiveActionsNotifierProvider.notifier).updateStatus(
                              actionId: action.id,
                              toStatus: PrescriptiveActionStatus.inProgress,
                              note: 'Started by operator from Queue',
                            );
                      },
                      onComplete: () {
                        ref.read(prescriptiveActionsNotifierProvider.notifier).updateStatus(
                              actionId: action.id,
                              toStatus: PrescriptiveActionStatus.completed,
                              note: 'Completed by operator from Queue',
                            );
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Failed to load queue: $err',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
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
                Icons.task_alt_rounded,
                size: 40,
                color: AppColors.success.withOpacity(0.8),
              ),
            ),
            AppSpacing.vSpaceMd,
            Text(
              'Action Queue Clear',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All operational tasks and roast batches are up to date.',
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
