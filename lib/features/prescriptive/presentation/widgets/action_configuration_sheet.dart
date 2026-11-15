import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/prescriptive_remote_datasource.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../../data/models/prescriptive_recommendation_model.dart';
import '../providers/prescriptive_provider.dart';
import 'action_success_modal.dart';

/// Modal Bottom Sheet for configuring and confirming an operational action
class ActionConfigurationSheet extends ConsumerStatefulWidget {
  final PrescriptiveRecommendationModel recommendation;
  final VoidCallback? onActionCreated;

  const ActionConfigurationSheet({
    super.key,
    required this.recommendation,
    this.onActionCreated,
  });

  static Future<void> show(
    BuildContext context,
    PrescriptiveRecommendationModel recommendation, {
    VoidCallback? onActionCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActionConfigurationSheet(
        recommendation: recommendation,
        onActionCreated: onActionCreated,
      ),
    );
  }

  @override
  ConsumerState<ActionConfigurationSheet> createState() => _ActionConfigurationSheetState();
}

class _ActionConfigurationSheetState extends ConsumerState<ActionConfigurationSheet> {
  late int _quantity;
  late RecommendationPriority _priority;
  late DateTime _scheduledDate;
  late TimeOfDay _scheduledTime;
  late TextEditingController _notesController;
  late TextEditingController _assigneeController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.recommendation.suggestedQuantity;
    _priority = widget.recommendation.priority;

    final now = DateTime.now();
    // Default scheduled time: next available hour or tomorrow morning
    if (widget.recommendation.actionClassification == ActionClassification.scheduled) {
      _scheduledDate = DateTime(now.year, now.month, now.day);
      _scheduledTime = TimeOfDay(hour: (now.hour + 2) % 24, minute: 0);
    } else {
      _scheduledDate = now;
      _scheduledTime = TimeOfDay.fromDateTime(now);
    }

    _notesController = TextEditingController();
    _assigneeController = TextEditingController(
      text: widget.recommendation.actionType == PrescriptiveActionType.roastBatch
          ? 'Hiro (Head Roaster)'
          : (widget.recommendation.actionType == PrescriptiveActionType.restockRawBeans
              ? 'Marco (Station Lead)'
              : 'Admin Lead'),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.brandAmber,
              onPrimary: Colors.black,
              surface: AppColors.darkSurfaceElevated,
              onSurface: AppColors.darkTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.brandAmber,
              onPrimary: Colors.black,
              surface: AppColors.darkSurfaceElevated,
              onSurface: AppColors.darkTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final currentUser = ref.read(currentUserProvider);
    final creatorName = currentUser != null
        ? '${currentUser.role.name.toUpperCase()} (${currentUser.fullName})'
        : 'Admin';

    final scheduledDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    final request = CreatePrescriptiveActionRequest(
      recommendationId: widget.recommendation.id,
      actionType: widget.recommendation.actionType,
      classification: widget.recommendation.actionClassification,
      priority: _priority,
      title: '${widget.recommendation.actionType.displayName}: ${widget.recommendation.targetProductName ?? widget.recommendation.title}',
      description: 'Execution of recommendation: ${widget.recommendation.title}',
      targetProductId: widget.recommendation.relatedProductId,
      targetProductName: widget.recommendation.targetProductName,
      targetQuantity: _quantity,
      targetUnit: widget.recommendation.suggestedUnit,
      scheduledAt: scheduledDateTime,
      createdBy: creatorName,
      assignedTo: _assigneeController.text.trim().isNotEmpty ? _assigneeController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      supportingMetric: widget.recommendation.supportingMetric,
      evidenceRationale: widget.recommendation.explanation,
    );

    final result = await ref.read(prescriptiveActionsNotifierProvider.notifier).createAction(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (createdAction) {
        Navigator.of(context).pop(); // Close sheet
        widget.onActionCreated?.call();

        // Show evidence-based success modal
        ActionSuccessModal.show(context, createdAction);
      },
      failure: (err) {
        AppToast.error(context, 'Failed to create action: ${err.message}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rec = widget.recommendation;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.vSpaceMd,

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getActionIcon(rec.actionType),
                    size: 20,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONFIGURE OPERATIONAL ACTION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rec.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vSpaceMd,

            // Supporting Evidence Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFFBF8F2),
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 16,
                    color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Evidence: ${rec.supportingMetric}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vSpaceMd,

            // Target Product & Quantity Section
            Text(
              'Target Quantity (${rec.suggestedUnit})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    borderRadius: AppRadius.radiusSm,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_quantity ${rec.suggestedUnit}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (rec.targetProductName != null)
                  Expanded(
                    child: Text(
                      rec.targetProductName!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            AppSpacing.vSpaceMd,

            // Priority Selector
            Text(
              'Action Priority',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: RecommendationPriority.values.map((prio) {
                final isSelected = _priority == prio;
                final isLast = prio == RecommendationPriority.values.last;
                final color = prio == RecommendationPriority.high
                    ? AppColors.error
                    : (prio == RecommendationPriority.medium ? AppColors.warning : AppColors.info);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = prio),
                    child: Container(
                      margin: EdgeInsets.only(right: isLast ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.18) : Colors.transparent,
                        borderRadius: AppRadius.radiusSm,
                        border: Border.all(
                          color: isSelected
                              ? color
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          prio.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? color
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            AppSpacing.vSpaceMd,

            // Date & Time Scheduling (For Scheduled Actions)
            if (rec.actionClassification == ActionClassification.scheduled) ...[
              Text(
                'Schedule Execution Date & Time',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        '${_scheduledDate.month}/${_scheduledDate.day}/${_scheduledDate.year}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        foregroundColor:
                            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 16),
                      label: Text(
                        _scheduledTime.format(context),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        foregroundColor:
                            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceMd,
            ],

            // Assigned Staff / Roaster
            Text(
              'Assignee / Station',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _assigneeController,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Head Roaster Hiro / Station Lead',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor:
                    isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusSm,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusSm,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
            ),
            AppSpacing.vSpaceMd,

            // Notes / Batch Profile Instructions
            Text(
              'Operational Notes & Instructions (Optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Medium roast profile Agtron 58, 200°C drum temp',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor:
                    isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusSm,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusSm,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
            ),
            AppSpacing.vSpaceLg,

            // Submit Button
            AppButton.primary(
              text: _isSubmitting
                  ? 'Scheduling Action...'
                  : (rec.actionClassification == ActionClassification.queue
                      ? 'Queue Operational Action'
                      : 'Confirm & Schedule Action'),
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    ),
  );
}

  IconData _getActionIcon(PrescriptiveActionType type) {
    return switch (type) {
      PrescriptiveActionType.roastBatch => Icons.local_fire_department_rounded,
      PrescriptiveActionType.restockRawBeans => Icons.inventory_2_rounded,
      PrescriptiveActionType.menuPromotion => Icons.campaign_rounded,
      PrescriptiveActionType.operationalWorkflow => Icons.storefront_rounded,
      PrescriptiveActionType.informational => Icons.info_outline_rounded,
    };
  }
}
