import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../data/models/sales_record_model.dart';
import '../../data/models/void_sale_request.dart';
import '../providers/sales_provider.dart';
import 'sales_channel_badge.dart';

/// Modal Bottom Sheet displaying Sales Transaction Audit Details & Void Action
class SalesRecordDetailSheet extends ConsumerStatefulWidget {
  final SalesRecordModel sale;

  const SalesRecordDetailSheet({
    super.key,
    required this.sale,
  });

  static Future<void> show(BuildContext context, SalesRecordModel sale) {
    return AppBottomSheet.show<void>(
      context,
      title: 'Transaction Audit Receipt',
      child: SalesRecordDetailSheet(sale: sale),
    );
  }

  @override
  ConsumerState<SalesRecordDetailSheet> createState() => _SalesRecordDetailSheetState();
}

class _SalesRecordDetailSheetState extends ConsumerState<SalesRecordDetailSheet> {
  final TextEditingController _voidReasonController = TextEditingController();
  bool _showVoidForm = false;
  bool _isVoiding = false;

  @override
  void dispose() {
    _voidReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleVoid() async {
    final reason = _voidReasonController.text.trim();
    if (reason.isEmpty) {
      AppToast.error(context, 'Please specify reason for voiding transaction.');
      return;
    }

    setState(() => _isVoiding = true);

    final result = await ref.read(salesNotifierProvider.notifier).voidSaleRecord(
          VoidSaleRequest(saleId: widget.sale.id, voidReason: reason),
        );

    setState(() => _isVoiding = false);

    if (!mounted) return;

    result.when(
      success: (voided) {
        AppToast.info(context, 'Transaction voided with audit log.');
        Navigator.of(context).pop();
      },
      failure: (failure) {
        AppToast.error(context, failure.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sale = widget.sale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Transaction Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.transactionNumber,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  ),
                ),
                Text(
                  _formatDateTime(sale.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            SalesChannelBadge(channel: sale.channel),
          ],
        ),
        const Divider(height: 24),

        // Customer Info & Staff Audit
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildAuditRow('Customer Reference', sale.customerName ?? 'Walk-In Customer', isDark),
              if (sale.customerPhone != null) ...[
                const SizedBox(height: 4),
                _buildAuditRow('Mobile Number', sale.customerPhone!, isDark),
              ],
              const SizedBox(height: 4),
              _buildAuditRow('Payment Method', sale.paymentMethod, isDark),
              if (sale.recordedByStaffName != null) ...[
                const SizedBox(height: 4),
                _buildAuditRow('Recorded By Staff', sale.recordedByStaffName!, isDark),
              ],
            ],
          ),
        ),
        AppSpacing.vSpaceLg,

        // Items Snapshot List
        Text(
          'Line Items (${sale.totalItemCount})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        AppSpacing.vSpaceSm,
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: sale.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity}x ${item.productName}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Price Snapshot: ${CurrencyFormatter.format(item.snapshotUnitPrice)} ${item.size != null ? "• ${item.size}" : ""}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.totalPrice),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        AppSpacing.vSpaceLg,

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Transaction Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            Text(
              CurrencyFormatter.format(sale.totalAmount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              ),
            ),
          ],
        ),
        AppSpacing.vSpaceLg,

        // Void Correction Action
        if (sale.isVoided)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'VOIDED TRANSACTION: "${sale.voidReason ?? "Audit Correction"}"',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          )
        else if (_showVoidForm) ...[
          AppTextField(
            label: 'Reason for Void / Correction',
            hint: 'e.g. Wrong items entered, customer return...',
            controller: _voidReasonController,
          ),
          AppSpacing.vSpaceMd,
          AppButton.outlined(
            text: 'Confirm Void Transaction',
            isLoading: _isVoiding,
            onPressed: _isVoiding ? null : _handleVoid,
          ),
        ] else
          TextButton(
            onPressed: () => setState(() => _showVoidForm = true),
            child: const Text('Void / Correct Record', style: TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        AppSpacing.vSpaceMd,
      ],
    );
  }

  Widget _buildAuditRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
