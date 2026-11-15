import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../products/data/models/product_model.dart';
import '../../../sales/data/models/sales_record_model.dart';
import '../../data/models/pos_checkout_request.dart';
import '../../data/models/pos_receipt_model.dart';

/// Clean Domain Repository Contract for Point of Sale
abstract class PosRepository {
  /// Real-time stream of catalog products
  Stream<List<ProductModel>> watchProducts();

  /// Atomically complete and persist a counter sale transaction
  Future<Result<PosReceiptModel, AppFailure>> completeSaleTransaction(PosCheckoutRequest request);

  /// Fetch recent POS walk-in transactions
  Future<Result<List<SalesRecordModel>, AppFailure>> getRecentPosTransactions({int limit = 20});
}
