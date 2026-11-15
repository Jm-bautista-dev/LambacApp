import 'package:equatable/equatable.dart';
import '../../../sales/data/models/sales_record_item_model.dart';
import '../../../sales/data/models/sales_record_model.dart';

/// High-fidelity POS Transaction Receipt Model
class PosReceiptModel extends Equatable {
  final String receiptNumber;
  final String saleId;
  final DateTime createdAt;
  final String staffName;
  final String staffId;
  final String? customerName;
  final String? customerPhone;
  final List<SalesRecordItemModel> items;
  final double subtotal;
  final double discountAmount;
  final String discountType;
  final double totalAmount;
  final String paymentMethod;
  final double? tenderedAmount;
  final double? changeAmount;
  final String? notes;

  const PosReceiptModel({
    required this.receiptNumber,
    required this.saleId,
    required this.createdAt,
    required this.staffName,
    required this.staffId,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.discountType = 'none',
    required this.totalAmount,
    required this.paymentMethod,
    this.tenderedAmount,
    this.changeAmount,
    this.notes,
  });

  factory PosReceiptModel.fromSaleRecord(
    SalesRecordModel sale, {
    double? tenderedAmount,
    double? changeAmount,
    double discountAmount = 0.0,
    String discountType = 'none',
  }) {
    return PosReceiptModel(
      receiptNumber: sale.transactionNumber,
      saleId: sale.id,
      createdAt: sale.createdAt,
      staffName: sale.recordedByStaffName ?? 'Staff Member',
      staffId: sale.recordedByStaffId ?? 'staff_unknown',
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      items: sale.items,
      subtotal: sale.subtotal,
      discountAmount: discountAmount,
      discountType: discountType,
      totalAmount: sale.totalAmount,
      paymentMethod: sale.paymentMethod,
      tenderedAmount: tenderedAmount,
      changeAmount: changeAmount,
      notes: sale.notes,
    );
  }

  int get totalItemCount => items.fold<int>(0, (sum, i) => sum + i.quantity);

  /// Generates a clean text receipt for copying or sharing
  String toShareableSummary() {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('       LAMBAC COFFEE ROASTERY           ');
    buffer.writeln('    Session Road Flagship Roastery      ');
    buffer.writeln('========================================');
    buffer.writeln('Receipt #: $receiptNumber');
    buffer.writeln('Date/Time: ${createdAt.toLocal().toString().substring(0, 19)}');
    buffer.writeln('Cashier:   $staffName');
    if (customerName != null && customerName!.isNotEmpty) {
      buffer.writeln('Customer:  $customerName');
    }
    buffer.writeln('----------------------------------------');
    for (final item in items) {
      final desc = [
        item.productName,
        if (item.size != null) '(${item.size})',
        if (item.grind != null) '[${item.grind}]',
      ].join(' ');
      buffer.writeln('${item.quantity}x $desc');
      buffer.writeln('    @ ₱${item.snapshotUnitPrice.toStringAsFixed(2)}  = ₱${item.totalPrice.toStringAsFixed(2)}');
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('Subtotal:      ₱${subtotal.toStringAsFixed(2)}');
    if (discountAmount > 0) {
      buffer.writeln('Discount:     -₱${discountAmount.toStringAsFixed(2)} ($discountType)');
    }
    buffer.writeln('TOTAL CHARGED: ₱${totalAmount.toStringAsFixed(2)}');
    buffer.writeln('Payment:       $paymentMethod');
    if (tenderedAmount != null) {
      buffer.writeln('Tendered:      ₱${tenderedAmount!.toStringAsFixed(2)}');
      buffer.writeln('Change:        ₱${(changeAmount ?? 0.0).toStringAsFixed(2)}');
    }
    buffer.writeln('========================================');
    buffer.writeln('   Thank you for supporting artisanal   ');
    buffer.writeln('      Philippine Coffee Roasters!       ');
    buffer.writeln('========================================');
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
        receiptNumber,
        saleId,
        createdAt,
        staffName,
        staffId,
        customerName,
        customerPhone,
        items,
        subtotal,
        discountAmount,
        discountType,
        totalAmount,
        paymentMethod,
        tenderedAmount,
        changeAmount,
        notes,
      ];
}
