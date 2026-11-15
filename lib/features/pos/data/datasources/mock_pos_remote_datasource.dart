import 'dart:async';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../products/data/datasources/mock_product_database.dart';
import '../../../products/data/models/product_model.dart';
import '../../../sales/data/datasources/mock_sales_remote_datasource.dart';
import '../../../sales/data/models/sales_channel.dart';
import '../../../sales/data/models/sales_record_model.dart';
import '../models/pos_checkout_request.dart';
import '../models/pos_receipt_model.dart';
import 'pos_remote_datasource.dart';

/// In-Memory Mock POS Remote Data Source for fast testing & offline preview
class MockPosRemoteDataSource implements PosRemoteDataSource {
  final MockProductDatabase _productDb = MockProductDatabase();
  final MockSalesRemoteDataSource _salesDataSource = MockSalesRemoteDataSource();
  final StreamController<List<ProductModel>> _controller =
      StreamController<List<ProductModel>>.broadcast();

  final List<ProductModel> _mockProducts = [];

  MockPosRemoteDataSource() {
    _mockProducts.addAll(_productDb.getAllProducts());
  }

  @override
  Stream<List<ProductModel>> watchProducts() {
    // Emit initial cached list immediately
    Timer.run(() {
      if (!_controller.isClosed) {
        _controller.add(List.unmodifiable(_mockProducts));
      }
    });
    return _controller.stream;
  }

  /// Simulate an Admin updating a product price or image at runtime
  void simulateAdminUpdateProduct(ProductModel updated) {
    final idx = _mockProducts.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _mockProducts[idx] = updated;
    } else {
      _mockProducts.add(updated);
    }
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_mockProducts));
    }
  }

  @override
  Future<Result<PosReceiptModel, AppFailure>> completeSaleTransaction(PosCheckoutRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (request.items.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Cart cannot be empty.'),
      );
    }

    if (request.paymentMethod.toLowerCase() == 'cash' &&
        (request.tenderedAmount == null || request.tenderedAmount! < request.totalAmount)) {
      return const Result.failure(
        ValidationFailure(
          message: 'Tendered cash amount must be greater than or equal to total charged.',
        ),
      );
    }

    final saleId = 'sale_${request.idempotencyKey}';
    final existingSales = _salesDataSource.getAllSales(includeVoided: true);
    final existingIndex = existingSales.indexWhere((s) => s.id == saleId);
    if (existingIndex != -1) {
      return Result.success(
        PosReceiptModel.fromSaleRecord(
          existingSales[existingIndex],
          tenderedAmount: request.tenderedAmount,
          changeAmount: request.changeAmount,
          discountAmount: request.discountAmount,
          discountType: request.discountType,
        ),
      );
    }

    // Check price and stock validation
    for (final item in request.items) {
      final p = _mockProducts.firstWhere(
        (p) => p.id == item.product.id,
        orElse: () => throw Exception("Product '${item.product.name}' was not found."),
      );

      final currentProduct = _productDb.getProductById(item.product.id) ?? p;

      if (!p.isEnabled || p.isSoldOut || !currentProduct.isEnabled) {
        return Result.failure(
          ValidationFailure(message: "Product '${p.name}' is sold out or unavailable."),
        );
      }

      if (currentProduct.stockQuantity < item.quantity) {
        return Result.failure(
          ValidationFailure(
            message: "Insufficient stock for '${p.name}'. Requested: ${item.quantity}, Available: ${currentProduct.stockQuantity}.",
          ),
        );
      }

      final sizeDelta = item.sizeVariant?.priceDelta ?? 0.0;
      final grindDelta = item.grindVariant?.priceDelta ?? 0.0;
      final currentExpected = p.basePrice + sizeDelta + grindDelta;

      if ((currentExpected - item.capturedUnitPrice).abs() > 0.01) {
        return Result.failure(
          ValidationFailure(
            message: "Price discrepancy detected for '${p.name}'. Please update cart prices.",
          ),
        );
      }
    }

    // Atomically decrement stock
    for (final item in request.items) {
      _productDb.updateStock(item.product.id, -item.quantity);
    }

    final now = DateTime.now();
    final txNum = 'TX-POS-${now.year}-${request.idempotencyKey.substring(0, request.idempotencyKey.length.clamp(0, 6)).toUpperCase()}';

    final saleRecord = SalesRecordModel(
      id: saleId,
      transactionNumber: txNum,
      channel: SalesChannel.walkIn,
      customerName: request.customerName,
      customerPhone: request.customerPhone,
      items: request.toSalesRecordItems(),
      subtotal: request.subtotal,
      totalAmount: request.totalAmount,
      paymentMethod: request.paymentMethod,
      notes: request.notes,
      recordedByStaffId: request.staffId,
      recordedByStaffName: request.staffName,
      createdAt: now,
    );

    // Persist into mock sales datasource
    _salesDataSource.recordDirectSale(saleRecord);

    return Result.success(
      PosReceiptModel.fromSaleRecord(
        saleRecord,
        tenderedAmount: request.tenderedAmount,
        changeAmount: request.changeAmount,
        discountAmount: request.discountAmount,
        discountType: request.discountType,
      ),
    );
  }

  @override
  Future<Result<List<SalesRecordModel>, AppFailure>> getRecentPosTransactions({int limit = 20}) async {
    final res = await _salesDataSource.getSalesRecords(channel: SalesChannel.walkIn);
    return res;
  }

  void dispose() {
    _controller.close();
  }
}
