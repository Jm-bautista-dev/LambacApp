import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/buttons/app_scale_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../data/models/create_walk_in_sale_request.dart';
import '../../data/models/sales_record_item_model.dart';
import '../providers/sales_provider.dart';

/// Fast POS Entry Modal Sheet for Barista Staff Walk-In Sales
class RecordWalkInSaleSheet extends ConsumerStatefulWidget {
  const RecordWalkInSaleSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      title: 'Record Store Walk-In Sale',
      child: const RecordWalkInSaleSheet(),
    );
  }

  @override
  ConsumerState<RecordWalkInSaleSheet> createState() => _RecordWalkInSaleSheetState();
}

class _RecordWalkInSaleSheetState extends ConsumerState<RecordWalkInSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<SalesRecordItemModel> _selectedItems = [];
  String _paymentMethod = 'Cash';
  bool _isSubmitting = false;

  final List<String> _paymentMethods = ['Cash', 'GCash', 'Maya', 'Card'];

  double get _totalAmount => _selectedItems.fold(0.0, (sum, i) => sum + i.totalPrice);

  void _addItemToCart(ProductModel product) {
    final existingIdx = _selectedItems.indexWhere((i) => i.productId == product.id);

    if (existingIdx != -1) {
      final existing = _selectedItems[existingIdx];
      final updated = SalesRecordItemModel(
        id: existing.id,
        productId: existing.productId,
        productName: existing.productName,
        snapshotUnitPrice: existing.snapshotUnitPrice,
        quantity: existing.quantity + 1,
        totalPrice: existing.snapshotUnitPrice * (existing.quantity + 1),
      );
      setState(() => _selectedItems[existingIdx] = updated);
    } else {
      final item = SalesRecordItemModel(
        id: 'pos_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        snapshotUnitPrice: product.basePrice,
        quantity: 1,
        totalPrice: product.basePrice,
      );
      setState(() => _selectedItems.add(item));
    }
  }

  void _decrementItem(String id) {
    final idx = _selectedItems.indexWhere((i) => i.id == id);
    if (idx == -1) return;

    final existing = _selectedItems[idx];
    if (existing.quantity > 1) {
      final updated = SalesRecordItemModel(
        id: existing.id,
        productId: existing.productId,
        productName: existing.productName,
        snapshotUnitPrice: existing.snapshotUnitPrice,
        quantity: existing.quantity - 1,
        totalPrice: existing.snapshotUnitPrice * (existing.quantity - 1),
      );
      setState(() => _selectedItems[idx] = updated);
    } else {
      setState(() => _selectedItems.removeAt(idx));
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedItems.isEmpty) {
      AppToast.error(context, 'Please select at least 1 product.');
      return;
    }

    setState(() => _isSubmitting = true);

    final request = CreateWalkInSaleRequest(
      customerName: _customerNameController.text.trim(),
      items: _selectedItems,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim(),
    );

    final result = await ref.read(salesNotifierProvider.notifier).recordWalkInSale(request);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    result.when(
      success: (sale) {
        AppToast.success(context, 'Walk-in transaction ${sale.transactionNumber} recorded!');
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

    final productsState = ref.watch(productsNotifierProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Select Roast Products Quick Grid
          Text(
            'Select Products from Menu',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          AppSpacing.vSpaceSm,
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: productsState.products.length,
              itemBuilder: (context, index) {
                final product = productsState.products[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppScaleButton(
                    onPressed: () => _addItemToCart(product),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            CurrencyFormatter.format(product.basePrice),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          AppSpacing.vSpaceLg,

          // Selected Items Snapshot
          if (_selectedItems.isNotEmpty) ...[
            Text(
              'Recorded Items Snapshot (${_selectedItems.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            AppSpacing.vSpaceSm,
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: _selectedItems.map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.productName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalPrice),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.error),
                          onPressed: () => _decrementItem(item.id),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            AppSpacing.vSpaceLg,
          ],

          // Customer Ref & Payment Method
          AppTextField(
            label: 'Customer Name / Reference (Optional)',
            hint: 'Walk-In Customer',
            controller: _customerNameController,
          ),
          AppSpacing.vSpaceMd,

          DropdownButtonFormField<String>(
            value: _paymentMethods.contains(_paymentMethod) ? _paymentMethod : _paymentMethods.first,
            decoration: const InputDecoration(labelText: 'Payment Method'),
            items: _paymentMethods.map((pm) {
              return DropdownMenuItem(value: pm, child: Text(pm, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _paymentMethod = val);
            },
          ),
          AppSpacing.vSpaceXxl,

          // Submit Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction Total', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  Text(
                    CurrencyFormatter.format(_totalAmount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              AppButton.primary(
                text: 'Record Walk-In Sale',
                isLoading: _isSubmitting,
                isFullWidth: false,
                width: 190,
                onPressed: _isSubmitting ? null : _handleSubmit,
              ),
            ],
          ),
          AppSpacing.vSpaceMd,
        ],
      ),
    );
  }
}
