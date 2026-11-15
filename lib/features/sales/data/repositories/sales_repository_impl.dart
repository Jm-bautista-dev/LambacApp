import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_remote_datasource.dart';
import '../models/create_walk_in_sale_request.dart';
import '../models/sales_channel.dart';
import '../models/sales_record_model.dart';
import '../models/void_sale_request.dart';

/// Concrete SalesRepository implementation
class SalesRepositoryImpl implements SalesRepository {
  final SalesRemoteDataSource _remoteDataSource;

  SalesRepositoryImpl({required SalesRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<List<SalesRecordModel>, AppFailure>> getSalesRecords({
    SalesChannel? channel,
    String? dateRange,
    String? searchQuery,
  }) {
    return _remoteDataSource.getSalesRecords(
      channel: channel,
      dateRange: dateRange,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<Result<SalesRecordModel, AppFailure>> recordWalkInSale(CreateWalkInSaleRequest request) {
    return _remoteDataSource.recordWalkInSale(request);
  }

  @override
  Future<Result<SalesRecordModel, AppFailure>> voidSaleRecord(VoidSaleRequest request) {
    return _remoteDataSource.voidSaleRecord(request);
  }
}
