import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../providers/prescriptive_provider.dart';
import '../widgets/action_audit_timeline.dart';

/// Comprehensive Action Detail Screen with Audit Trail & Lifecycle Controls
class PrescriptiveActionDetailScreen extends ConsumerStatefulWidget {
  final String actionId;

  const PrescriptiveActionDetailScreen({
    super.key,
    required this.actionId,
  });

  @override
  ConsumerState<PrescriptiveActionDetailScreen> createState() =>
      _PrescriptiveActionDetailScreenState();
}

class _PrescriptiveActionDetailScreenState
    extends ConsumerState<PrescriptiveActionDetailScreen> {
  bool _isProcessing = false;

  Future<void> _handleStart(PrescriptiveActionModel action) async {
    setState(() => _isProcessing = true);
    final result = await ref
        .read(prescriptiveActionsNotifierProvider.notifier)
        .updateStatus(
          actionId: action.id,
          toStatus: PrescriptiveActionStatus.inProgress,
          note: 'Operator started execution of ${action.title}',
        );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    result.when(
      success: (_) => AppToast.success(context, 'Action marked as In Progress.'),
      failure: (err) => AppToast.error(context, err.message),
    );
  }

  Future<void> _handleComplete(PrescriptiveActionModel action) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        title: const Text('Complete Operational Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark "${action.title}" (${action.targetQuantity} ${action.targetUnit}) as completed?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Completion note (e.g. Yield 12 bags, Agtron 58)',
                hintStyle: TextStyle(fontSize: 12),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Completion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      final result = await ref
          .read(prescriptiveActionsNotifierProvider.notifier)
          .updateStatus(
            actionId: action.id,
            toStatus: PrescriptiveActionStatus.completed,
            note: noteController.text.trim().isNotEmpty
                ? noteController.text.trim()
                : 'Action successfully completed by operator',
          );
      if (!mounted) return;
      setState(() => _isProcessing = false);

      result.when(
        success: (_) => AppToast.success(
          context,
          'Action completed. Performance impact will be evaluated using subsequent sales data.',
        ),
        failure: (err) => AppToast.error(context, err.message),
      );
    }
  }

  Future<void> _handleReschedule(PrescriptiveActionModel action) async {
    final now = DateTime.now();
    DateTime pickedDate = action.scheduledAt ?? now.add(const Duration(days: 1));
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(action.scheduledAt ?? now);
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceElevated,
            title: const Text('Reschedule Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a new date and time for "${action.title}":',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: pickedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                            );
                            if (d != null) {
                              setDialogState(() => pickedDate = d);
                            }
                          },
                          child: Text('${pickedDate.month}/${pickedDate.day}/${pickedDate.year}', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: pickedTime,
                            );
                            if (t != null) {
                              setDialogState(() => pickedTime = t);
                            }
                          },
                          child: Text(pickedTime.format(ctx), style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Reason for rescheduling (Optional)',
                      hintStyle: TextStyle(fontSize: 12),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAmber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Confirm Reschedule'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      final newScheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      setState(() => _isProcessing = true);
      final result = await ref
          .read(prescriptiveActionsNotifierProvider.notifier)
          .reschedule(
            actionId: action.id,
            newScheduledAt: newScheduledAt,
            reason: reasonController.text.trim().isNotEmpty
                ? reasonController.text.trim()
                : null,
          );
      if (!mounted) return;
      setState(() => _isProcessing = false);

      result.when(
        success: (_) => AppToast.success(context, 'Action rescheduled successfully.'),
        failure: (err) => AppToast.error(context, err.message),
      );
    }
  }

  Future<void> _handleCancel(PrescriptiveActionModel action) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        title: const Text('Cancel Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel "${action.title}"?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Cancellation reason (e.g. Schedule conflict)',
                hintStyle: TextStyle(fontSize: 12),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Action'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Action'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      final result = await ref
          .read(prescriptiveActionsNotifierProvider.notifier)
          .cancel(
            actionId: action.id,
            reason: reasonController.text.trim().isNotEmpty
                ? reasonController.text.trim()
                : null,
          );
      if (!mounted) return;
      setState(() => _isProcessing = false);

      result.when(
        success: (_) => AppToast.info(context, 'Action cancelled.'),
        failure: (err) => AppToast.error(context, err.message),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final actionsAsync = ref.watch(prescriptiveActionsNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        title: 'Action #${widget.actionId}',
        subtitle: 'Prescriptive Decision Execution',
      ),
      body: actionsAsync.when(
        data: (actions) {
          final action = actions.cast<PrescriptiveActionModel?>().firstWhere(
                (a) => a?.id == widget.actionId,
                orElse: () => null,
              );

          if (action == null) {
            return const AppErrorView(
              title: 'Action Not Found',
              message: 'The requested prescriptive action record could not be found.',
            );
          }

          final statusColor = switch (action.status) {
            PrescriptiveActionStatus.completed => AppColors.success,
            PrescriptiveActionStatus.inProgress => AppColors.brandAmber,
            PrescriptiveActionStatus.cancelled => AppColors.error,
            PrescriptiveActionStatus.scheduled => AppColors.info,
            _ => AppColors.cremaGold,
          };

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Header Card
              AppCard.elevated(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: AppRadius.radiusPill,
                          ),
                          child: Text(
                            action.status.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: AppRadius.radiusPill,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Text(
                            '${action.priority.name.toUpperCase()} PRIORITY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSpaceMd,
                    Text(
                      action.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.description,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildMetaRow('Target Quantity', '${action.targetQuantity} ${action.targetUnit}', isDark),
                    if (action.targetProductName != null)
                      _buildMetaRow('Target Product', action.targetProductName!, isDark),
                    if (action.scheduledAt != null)
                      _buildMetaRow('Scheduled Time', _formatDateTime(action.scheduledAt!), isDark),
                    if (action.assignedTo != null)
                      _buildMetaRow('Assigned To', action.assignedTo!, isDark),
                    _buildMetaRow('Created By', action.createdBy, isDark),
                    _buildMetaRow('Created Date', _formatDateTime(action.createdAt), isDark),
                    if (action.completedAt != null)
                      _buildMetaRow('Completed Date', _formatDateTime(action.completedAt!), isDark, highlightColor: AppColors.success),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              // Traceability & Evidence Card
              AppCard.elevated(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 16,
                          color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PRESCRIPTIVE ORIGIN & EVIDENCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSpaceSm,
                    Text(
                      action.evidenceRationale,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFFAF6EE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Supporting Metric: ${action.supportingMetric}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              // Audit Trail Card
              AppCard.elevated(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'OPERATIONAL AUDIT TRAIL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSpaceMd,
                    ActionAuditTimeline(auditLogs: action.auditLogs),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              // Operational Lifecycle Actions
              if (action.status == PrescriptiveActionStatus.scheduled ||
                  action.status == PrescriptiveActionStatus.queued) ...[
                AppButton.primary(
                  text: 'Mark In Progress',
                  isLoading: _isProcessing,
                  onPressed: () => _handleStart(action),
                ),
                AppSpacing.vSpaceSm,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          foregroundColor:
                              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        onPressed: () => _handleReschedule(action),
                        child: const Text('Reschedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: () => _handleCancel(action),
                        child: const Text('Cancel Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ] else if (action.status == PrescriptiveActionStatus.inProgress) ...[
                AppButton.primary(
                  text: 'Mark as Completed',
                  isLoading: _isProcessing,
                  onPressed: () => _handleComplete(action),
                ),
                AppSpacing.vSpaceSm,
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                  ),
                  onPressed: () => _handleCancel(action),
                  child: const Center(
                    child: Text('Cancel Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else if (action.status == PrescriptiveActionStatus.completed) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 20, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Action completed. Performance impact will be evaluated using subsequent sales data.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (action.status == PrescriptiveActionStatus.cancelled) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, size: 20, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Action cancelled. Record archived in Prescriptive History.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              AppSpacing.vSpaceXxl,
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorView(
          title: 'Unable to Load Action',
          message: err.toString(),
          onRetry: () => ref.read(prescriptiveActionsNotifierProvider.notifier).loadActions(),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlightColor ??
                    (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, ${dt.year} · $hour:$min $period';
  }
}
