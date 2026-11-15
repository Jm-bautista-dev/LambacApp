import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../data/models/create_walk_in_sale_request.dart';
import '../../data/models/sales_channel.dart';
import '../../data/models/sales_record_model.dart';
import '../../data/models/void_sale_request.dart';

/// Clean Domain Repository Contract for Centralized Sales Management
abstract class SalesRepository {
  Future<Result<List<SalesRecordModel>, AppFailure>> getSalesRecords({
    SalesChannel? channel,
    String? dateRange,
    String? searchQuery,
  });

  Future<Result<SalesRecordModel, AppFailure>> recordWalkInSale(CreateWalkInSaleRequest request);

  Future<Result<SalesRecordModel, AppFailure>> voidSaleRecord(VoidSaleRequest request);
}
