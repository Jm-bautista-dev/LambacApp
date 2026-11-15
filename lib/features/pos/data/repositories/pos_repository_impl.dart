import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../products/data/models/product_model.dart';
import '../../../sales/data/models/sales_record_model.dart';
import '../../domain/repositories/pos_repository.dart';
import '../datasources/pos_remote_datasource.dart';
import '../models/pos_checkout_request.dart';
import '../models/pos_receipt_model.dart';

/// Concrete implementation of PosRepository
class PosRepositoryImpl implements PosRepository {
  final PosRemoteDataSource _remoteDataSource;

  PosRepositoryImpl({required PosRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<ProductModel>> watchProducts() {
    return _remoteDataSource.watchProducts();
  }

  @override
  Future<Result<PosReceiptModel, AppFailure>> completeSaleTransaction(PosCheckoutRequest request) {
    return _remoteDataSource.completeSaleTransaction(request);
  }

  @override
  Future<Result<List<SalesRecordModel>, AppFailure>> getRecentPosTransactions({int limit = 20}) {
    return _remoteDataSource.getRecentPosTransactions(limit: limit);
  }
}
