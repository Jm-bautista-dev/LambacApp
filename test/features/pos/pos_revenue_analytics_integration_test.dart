import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_item_model.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_model.dart';

void main() {
  group('POS Revenue & Analytics Integration Tests', () {
    test('POS sales use SalesChannel.walkIn and mobile pickup orders use SalesChannel.mobileApp', () {
      final now = DateTime.now();

      final walkInSale = SalesRecordModel(
        id: 'sale_pos_1',
        transactionNumber: 'TX-POS-2026-0001',
        channel: SalesChannel.walkIn,
        items: const [
          SalesRecordItemModel(
            id: 'item_1',
            productId: 'tokyo-blend',
            productName: 'Tokyo Kissaten Signature Blend',
            snapshotUnitPrice: 380.0,
            quantity: 2,
            totalPrice: 760.0,
          ),
        ],
        subtotal: 760.0,
        totalAmount: 760.0,
        paymentMethod: 'Cash',
        createdAt: now,
      );

      final mobileOrderSale = SalesRecordModel(
        id: 'sale_ord_999',
        transactionNumber: 'TX-MOB-999',
        channel: SalesChannel.mobileApp,
        orderId: 'ord_999',
        items: const [
          SalesRecordItemModel(
            id: 'item_2',
            productId: 'benguet-typica',
            productName: 'Benguet Arabica Typica Heirloom',
            snapshotUnitPrice: 420.0,
            quantity: 1,
            totalPrice: 420.0,
          ),
        ],
        subtotal: 420.0,
        totalAmount: 420.0,
        paymentMethod: 'GCash',
        createdAt: now,
      );

      expect(walkInSale.isWalkIn, isTrue);
      expect(walkInSale.isMobileApp, isFalse);
      expect(walkInSale.channel, SalesChannel.walkIn);

      expect(mobileOrderSale.isMobileApp, isTrue);
      expect(mobileOrderSale.isWalkIn, isFalse);
      expect(mobileOrderSale.channel, SalesChannel.mobileApp);
    });

    test('Revenue aggregation accurately sums walk-in and mobile sales without double-counting', () {
      final sales = [
        // POS Sale 1
        SalesRecordModel(
          id: 'sale_pos_1',
          transactionNumber: 'TX-POS-01',
          channel: SalesChannel.walkIn,
          items: const [],
          subtotal: 500.0,
          totalAmount: 500.0,
          paymentMethod: 'Cash',
          createdAt: DateTime.now(),
        ),
        // POS Sale 2
        SalesRecordModel(
          id: 'sale_pos_2',
          transactionNumber: 'TX-POS-02',
          channel: SalesChannel.walkIn,
          items: const [],
          subtotal: 750.0,
          totalAmount: 750.0,
          paymentMethod: 'GCash',
          createdAt: DateTime.now(),
        ),
        // Mobile App Sale
        SalesRecordModel(
          id: 'sale_ord_10',
          transactionNumber: 'TX-MOB-10',
          channel: SalesChannel.mobileApp,
          orderId: 'ord_10',
          items: const [],
          subtotal: 420.0,
          totalAmount: 420.0,
          paymentMethod: 'GCash',
          createdAt: DateTime.now(),
        ),
      ];

      final totalRevenue = sales.where((s) => !s.isVoided).fold(0.0, (sum, s) => sum + s.totalAmount);
      final walkInRevenue = sales.where((s) => s.isWalkIn && !s.isVoided).fold(0.0, (sum, s) => sum + s.totalAmount);
      final mobileRevenue = sales.where((s) => s.isMobileApp && !s.isVoided).fold(0.0, (sum, s) => sum + s.totalAmount);

      expect(totalRevenue, 1670.0);
      expect(walkInRevenue, 1250.0);
      expect(mobileRevenue, 420.0);
      expect(walkInRevenue + mobileRevenue, totalRevenue);
    });
  });
}
