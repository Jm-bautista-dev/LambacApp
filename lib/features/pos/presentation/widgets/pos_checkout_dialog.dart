import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../providers/pos_cart_provider.dart';
import '../providers/pos_checkout_provider.dart';
import 'pos_receipt_dialog.dart';

/// Modal dialog for counter checkout, cash tender calculator, and payment method confirmation
class PosCheckoutDialog extends ConsumerStatefulWidget {
  const PosCheckoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PosCheckoutDialog(),
    );
  }

  @override
  ConsumerState<PosCheckoutDialog> createState() => _PosCheckoutDialogState();
}

class _PosCheckoutDialogState extends ConsumerState<PosCheckoutDialog> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _tenderedController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedPaymentMethod = 'Cash';
  final List<String> _paymentMethods = ['Cash', 'GCash', 'Maya', 'Card'];

  @override
  void initState() {
    super.initState();
    final cart = ref.read(posCartNotifierProvider);
    _customerNameController.text = cart.customerName ?? '';
    _customerPhoneController.text = cart.customerPhone ?? '';
    _notesController.text = cart.notes ?? '';

    // Initialize tendered amount to total for quick one-tap exact cash payment
    _tenderedController.text = cart.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _tenderedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _tenderedAmount {
    return double.tryParse(_tenderedController.text.replaceAll(',', '').trim());
  }

  double? _calculateChange(double total) {
    final tendered = _tenderedAmount;
    if (tendered == null) return null;
    return tendered - total;
  }

  void _selectQuickCashAmount(double amount) {
    _tenderedController.text = amount.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _handleCompleteSale(double total) async {
    final paymentMethod = _selectedPaymentMethod;
    double? tendered;
    double? change;

    if (paymentMethod == 'Cash') {
      tendered = _tenderedAmount;
      if (tendered == null || tendered < total) {
        AppToast.error(context, 'Tendered amount must be at least ${CurrencyFormatter.format(total)}.');
        return;
      }
      change = (tendered - total).clamp(0.0, double.infinity);
    }

    // Update customer info and notes in cart provider
    ref.read(posCartNotifierProvider.notifier)
      ..setCustomerInfo(
        name: _customerNameController.text.trim(),
        phone: _customerPhoneController.text.trim(),
      )
      ..setNotes(_notesController.text.trim());

    final checkoutNotifier = ref.read(posCheckoutNotifierProvider.notifier);
    final result = await checkoutNotifier.submitCheckout(
      paymentMethod: paymentMethod,
      tenderedAmount: tendered,
      changeAmount: change,
    );

    if (!mounted) return;

    result.when(
      success: (receipt) {
        Navigator.of(context).pop(); // Close checkout modal
        PosReceiptDialog.show(context, receipt); // Open confirmed receipt
      },
      failure: (failure) {
        AppToast.error(
          context,
          failure.message.isNotEmpty ? failure.message : 'Transaction submission failed. Please try again.',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(posCartNotifierProvider);
    final checkoutState = ref.watch(posCheckoutNotifierProvider);
    final isSubmitting = checkoutState.isSubmitting;

    final total = cartState.total;
    final change = _calculateChange(total);
    final isCashShort = _selectedPaymentMethod == 'Cash' && (change == null || change < 0);

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandAmber.withValues(alpha: 0.15),
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: const Icon(Icons.point_of_sale_rounded, color: AppColors.brandAmber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete Sale',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '${cartState.itemCount} items • Session Road Flagship',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isSubmitting)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Scrollable Body
              Expanded(
                child: ListView(
                  children: [
                    // Total Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL CHARGED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                              if (cartState.discountAmount > 0)
                                Text(
                                  'Includes ${CurrencyFormatter.format(cartState.discountAmount)} discount',
                                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(total),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Method Picker
                    Text(
                      'PAYMENT METHOD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _paymentMethods.map((method) {
                        final isSelected = _selectedPaymentMethod == method;
                        final icon = switch (method) {
                          'Cash' => Icons.payments_rounded,
                          'GCash' => Icons.phone_android_rounded,
                          'Maya' => Icons.account_balance_wallet_rounded,
                          _ => Icons.credit_card_rounded,
                        };

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: isSubmitting ? null : () => setState(() => _selectedPaymentMethod = method),
                              borderRadius: AppRadius.radiusMd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.brandAmber
                                      : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface),
                                  borderRadius: AppRadius.radiusMd,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.brandAmber
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      method,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected
                                          ? Colors.white
                                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Cash Tender Section (Only visible when Cash is selected)
                    if (_selectedPaymentMethod == 'Cash') ...[
                      const SizedBox(height: 18),
                      Text(
                        'CASH TENDERED (₱)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick Cash Amount Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickCashChip('Exact: ${CurrencyFormatter.format(total)}', total),
                          if (total <= 500) _buildQuickCashChip('₱500', 500),
                          if (total <= 1000) _buildQuickCashChip('₱1,000', 1000),
                          if (total <= 2000) _buildQuickCashChip('₱2,000', 2000),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Tender Input Field
                      TextField(
                        controller: _tenderedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          labelText: 'Amount Received from Customer',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 12),

                      // Change Calculation Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCashShort
                              ? AppColors.error.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: isCashShort ? AppColors.error : AppColors.success,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isCashShort ? 'SHORTFALL' : 'CHANGE DUE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isCashShort ? AppColors.error : AppColors.success,
                              ),
                            ),
                            Text(
                              isCashShort
                                  ? '-${CurrencyFormatter.format((change ?? 0).abs())}'
                                  : CurrencyFormatter.format(change ?? 0.0),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isCashShort ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Customer Information (Optional)
                    Text(
                      'CUSTOMER DETAILS (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: 'Customer Name / Cup Label',
                        hintText: 'e.g. Kenji T.',
                        border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Transaction Notes (Optional)',
                        hintText: 'e.g. Extra hot water on side',
                        border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                      ),
                      onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      text: isSubmitting ? 'Recording Sale...' : 'Confirm Sale',
                      leadingIcon: isSubmitting ? null : const Icon(Icons.check_circle_rounded, size: 18),
                      isLoading: isSubmitting,
                      variant: AppButtonVariant.primary,
                      onPressed: (isSubmitting || isCashShort) ? null : () => _handleCompleteSale(total),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashChip(String label, double amount) {
    final isSelected = (_tenderedAmount != null && (_tenderedAmount! - amount).abs() < 0.01);
    return InkWell(
      onTap: () => _selectQuickCashAmount(amount),
      borderRadius: AppRadius.radiusPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandAmber : Colors.transparent,
          borderRadius: AppRadius.radiusPill,
          border: Border.all(
            color: isSelected ? AppColors.brandAmber : AppColors.brandAmber.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.brandAmber,
          ),
        ),
      ),
    );
  }
}
