import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/pos/data/datasources/mock_pos_remote_datasource.dart';
import 'package:lambac_app/features/pos/data/models/pos_cart_item_model.dart';
import 'package:lambac_app/features/pos/data/models/pos_checkout_request.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';

void main() {
  group('POS Checkout & Atomic Persistence Tests', () {
    late MockPosRemoteDataSource remoteDataSource;

    const sampleProduct = ProductModel(
      id: 'tokyo-blend',
      name: 'Tokyo Kissaten Signature Blend',
      slug: 'tokyo-blend',
      origin: 'Mount Apo & Benguet Blend',
      description: 'Rich dark roast blend.',
      basePrice: 380.0,
      categoryId: 'coffee',
      categoryName: 'Coffee',
      roastLevel: 'Dark Roast',
      tastingNotes: 'Dark Chocolate, Roasted Walnut',
      stockQuantity: 25,
      isEnabled: true,
    );

    setUp(() {
      remoteDataSource = MockPosRemoteDataSource();
    });

    test('Completing sale produces confirmed receipt and frozen line items', () async {
      final cartItem = PosCartItemModel.fromProduct(
        product: sampleProduct,
        quantity: 2,
      );

      final request = PosCheckoutRequest(
        items: [cartItem],
        paymentMethod: 'Cash',
        tenderedAmount: 1000.0,
        changeAmount: 240.0,
        staffId: 'staff_hiro_123',
        staffName: 'Barista Hiro',
        customerName: 'Kenji Walk-in',
        idempotencyKey: 'tx_test_001',
      );

      final result = await remoteDataSource.completeSaleTransaction(request);

      expect(result.isSuccess, isTrue);
      final receipt = result.dataOrNull!;

      expect(receipt.receiptNumber.startsWith('TX-POS-'), isTrue);
      expect(receipt.totalAmount, 760.0);
      expect(receipt.staffName, 'Barista Hiro');
      expect(receipt.customerName, 'Kenji Walk-in');
      expect(receipt.paymentMethod, 'Cash');
      expect(receipt.tenderedAmount, 1000.0);
      expect(receipt.changeAmount, 240.0);
      expect(receipt.items.length, 1);
      expect(receipt.items.first.snapshotUnitPrice, 380.0);
      expect(receipt.items.first.totalPrice, 760.0);
    });

    test('Cash payment rejects insufficient tendered cash', () async {
      final cartItem = PosCartItemModel.fromProduct(
        product: sampleProduct,
        quantity: 1, // ₱380.00
      );

      final request = PosCheckoutRequest(
        items: [cartItem],
        paymentMethod: 'Cash',
        tenderedAmount: 300.0, // Insufficient!
        changeAmount: 0.0,
        staffId: 'staff_hiro_123',
        staffName: 'Barista Hiro',
        idempotencyKey: 'tx_test_002',
      );

      final result = await remoteDataSource.completeSaleTransaction(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message.contains('Tendered cash amount must be greater than or equal'), isTrue);
    });

    test('Non-cash payment methods (GCash, Maya, Card) complete without cash tender', () async {
      final cartItem = PosCartItemModel.fromProduct(
        product: sampleProduct,
        quantity: 1,
      );

      final request = PosCheckoutRequest(
        items: [cartItem],
        paymentMethod: 'GCash',
        staffId: 'staff_hiro_123',
        staffName: 'Barista Hiro',
        idempotencyKey: 'tx_test_003',
      );

      final result = await remoteDataSource.completeSaleTransaction(request);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.paymentMethod, 'GCash');
    });

    test('Rejects checkout if product in cart has unconfirmed price change', () async {
      // Create cart item with stale price
      final cartItem = PosCartItemModel(
        id: 'tokyo-blend_default_default',
        product: sampleProduct,
        capturedUnitPrice: 300.0, // Stale! Live price is 380.0
        currentLiveUnitPrice: 380.0,
        isPriceStale: true,
        quantity: 1,
      );

      final request = PosCheckoutRequest(
        items: [cartItem],
        paymentMethod: 'GCash',
        staffId: 'staff_hiro_123',
        staffName: 'Barista Hiro',
        idempotencyKey: 'tx_test_004',
      );

      final result = await remoteDataSource.completeSaleTransaction(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message.contains('Price discrepancy detected'), isTrue);
    });

    test('Rejects checkout if product is sold out or disabled', () async {
      final disabledProduct = sampleProduct.copyWith(isEnabled: false);
      remoteDataSource.simulateAdminUpdateProduct(disabledProduct);

      final cartItem = PosCartItemModel.fromProduct(
        product: disabledProduct,
        quantity: 1,
      );

      final request = PosCheckoutRequest(
        items: [cartItem],
        paymentMethod: 'Cash',
        tenderedAmount: 500.0,
        staffId: 'staff_hiro_123',
        staffName: 'Barista Hiro',
        idempotencyKey: 'tx_test_005',
      );

      final result = await remoteDataSource.completeSaleTransaction(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message.contains('sold out or unavailable'), isTrue);
    });
  });
}
