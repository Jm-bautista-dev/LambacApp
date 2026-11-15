import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../models/create_walk_in_sale_request.dart';
import '../models/sales_channel.dart';
import '../models/sales_record_model.dart';
import '../models/void_sale_request.dart';

/// Contract for Remote Centralized Sales API
abstract class SalesRemoteDataSource {
  Future<Result<List<SalesRecordModel>, AppFailure>> getSalesRecords({
    SalesChannel? channel,
    String? dateRange,
    String? searchQuery,
  });

  Future<Result<SalesRecordModel, AppFailure>> recordWalkInSale(CreateWalkInSaleRequest request);

  Future<Result<SalesRecordModel, AppFailure>> voidSaleRecord(VoidSaleRequest request);
}

/// Concrete Dio-based implementation
class SalesRemoteDataSourceImpl implements SalesRemoteDataSource {
  final ApiClient _apiClient;

  SalesRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<List<SalesRecordModel>, AppFailure>> getSalesRecords({
    SalesChannel? channel,
    String? dateRange,
    String? searchQuery,
  }) {
    final queryParams = <String, String>{
      if (channel != null) 'channel': channel.name,
      if (dateRange != null) 'date_range': dateRange,
      if (searchQuery != null && searchQuery.isNotEmpty) 'q': searchQuery,
    };

    return _apiClient.get(
      '/admin/sales',
      queryParameters: queryParams,
      requiresAuth: true,
      decoder: (data) {
        final list = data is List ? data : (data['sales'] ?? data['data']) as List;
        return list.map((item) => SalesRecordModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<Result<SalesRecordModel, AppFailure>> recordWalkInSale(CreateWalkInSaleRequest request) {
    return _apiClient.post(
      '/admin/sales/walk-in',
      data: request.toJson(),
      requiresAuth: true,
      decoder: (data) => SalesRecordModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<SalesRecordModel, AppFailure>> voidSaleRecord(VoidSaleRequest request) {
    return _apiClient.post(
      '/admin/sales/${request.saleId}/void',
      data: request.toJson(),
      requiresAuth: true,
      decoder: (data) => SalesRecordModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
