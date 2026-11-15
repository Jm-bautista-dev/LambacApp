import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../products/data/models/product_model.dart';
import '../../../sales/data/models/sales_record_model.dart';
import '../models/pos_checkout_request.dart';
import '../models/pos_receipt_model.dart';

/// Contract for Point of Sale operations and real-time product streaming
abstract class PosRemoteDataSource {
  /// Real-time stream of all catalog products directly from the database
  Stream<List<ProductModel>> watchProducts();

  /// Execute an atomic, concurrency-safe counter transaction with stock updates
  Future<Result<PosReceiptModel, AppFailure>> completeSaleTransaction(PosCheckoutRequest request);

  /// Fetch recent POS walk-in transactions
  Future<Result<List<SalesRecordModel>, AppFailure>> getRecentPosTransactions({int limit = 20});
}
