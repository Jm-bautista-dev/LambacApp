import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../providers/prescriptive_provider.dart';
import 'prescriptive_action_card.dart';

/// Historical Audit Ledger for Completed, Cancelled & Skipped Prescriptive Actions
class PrescriptiveHistoryView extends ConsumerStatefulWidget {
  const PrescriptiveHistoryView({super.key});

  @override
  ConsumerState<PrescriptiveHistoryView> createState() => _PrescriptiveHistoryViewState();
}

class _PrescriptiveHistoryViewState extends ConsumerState<PrescriptiveHistoryView> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final history = ref.watch(prescriptiveHistoryProvider);
    final actionsAsync = ref.watch(prescriptiveActionsNotifierProvider);

    final filtered = switch (_selectedFilter) {
      'Completed' => history.where((a) => a.status == PrescriptiveActionStatus.completed).toList(),
      'Cancelled' => history.where((a) => a.status == PrescriptiveActionStatus.cancelled).toList(),
      _ => history,
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
                label: 'All History (${history.length})',
                isSelected: _selectedFilter == 'All',
                isSmall: true,
                onSelected: (_) => setState(() => _selectedFilter = 'All'),
              ),
              const SizedBox(width: 6),
              AppChip(
                label: 'Completed',
                isSelected: _selectedFilter == 'Completed',
                isSmall: true,
                onSelected: (_) => setState(() => _selectedFilter = 'Completed'),
              ),
              const SizedBox(width: 6),
              AppChip(
                label: 'Cancelled',
                isSelected: _selectedFilter == 'Cancelled',
                isSmall: true,
                onSelected: (_) => setState(() => _selectedFilter = 'Cancelled'),
              ),
            ],
          ),
        ),

        // History List
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
                    return PrescriptiveActionCard(action: action);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Failed to load history: $err',
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
                Icons.history_toggle_off_rounded,
                size: 40,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
            AppSpacing.vSpaceMd,
            Text(
              'No Action History Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Completed and cancelled prescriptive actions will be preserved in this immutable audit ledger.',
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
