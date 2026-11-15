import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../data/datasources/firebase_sales_remote_datasource.dart';
import '../../data/datasources/mock_sales_remote_datasource.dart';
import '../../data/datasources/sales_remote_datasource.dart';
import '../../data/models/create_walk_in_sale_request.dart';
import '../../data/models/sales_channel.dart';
import '../../data/models/sales_record_model.dart';
import '../../data/models/void_sale_request.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/repositories/sales_repository.dart';

/// Provider for Sales Remote Data Source
final salesRemoteDataSourceProvider = Provider<SalesRemoteDataSource>((ref) {
  try {
    if (Firebase.apps.isEmpty) {
      return MockSalesRemoteDataSource();
    }
  } catch (_) {
    return MockSalesRemoteDataSource();
  }
  return FirebaseSalesRemoteDataSource();
});

/// Provider for Domain SalesRepository
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final remoteDataSource = ref.watch(salesRemoteDataSourceProvider);
  return SalesRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Active Sales Channel Filter Provider (null = All, mobileApp, walkIn)
final salesChannelFilterProvider = StateProvider<SalesChannel?>((ref) => null);

/// Active Sales Date Range Filter Provider
final salesDateRangeFilterProvider = StateProvider<String>((ref) => '30D');

/// Active Sales Search Query Provider
final salesSearchQueryProvider = StateProvider<String>((ref) => '');

/// Sales State Container
class SalesState extends Equatable {
  final bool isLoading;
  final List<SalesRecordModel> sales;
  final AppFailure? failure;

  const SalesState({
    this.isLoading = false,
    this.sales = const [],
    this.failure,
  });

  SalesState copyWith({
    bool? isLoading,
    List<SalesRecordModel>? sales,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return SalesState(
      isLoading: isLoading ?? this.isLoading,
      sales: sales ?? this.sales,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  double get totalRevenue => sales.where((s) => !s.isVoided).fold(0.0, (sum, s) => sum + s.totalAmount);
  double get mobileRevenue => sales.where((s) => s.isMobileApp && !s.isVoided).fold(0.0, (sum, s) => sum + s.totalAmount);
  double get walkInRevenue => sales.where((s) => s.isWalkIn && !s.isVoided).fold(0.0, (sum, s) => sum + s.totalAmount);

  @override
  List<Object?> get props => [isLoading, sales, failure];
}

/// Global Sales StateNotifier Provider
final salesNotifierProvider = StateNotifierProvider<SalesNotifier, SalesState>((ref) {
  final repository = ref.watch(salesRepositoryProvider);
  final channel = ref.watch(salesChannelFilterProvider);
  final dateRange = ref.watch(salesDateRangeFilterProvider);
  final searchQuery = ref.watch(salesSearchQueryProvider);

  return SalesNotifier(
    repository: repository,
    channel: channel,
    dateRange: dateRange,
    searchQuery: searchQuery,
  );
});

class SalesNotifier extends StateNotifier<SalesState> {
  final SalesRepository _repository;
  final SalesChannel? _channel;
  final String _dateRange;
  final String _searchQuery;

  SalesNotifier({
    required SalesRepository repository,
    SalesChannel? channel,
    required String dateRange,
    required String searchQuery,
  })  : _repository = repository,
        _channel = channel,
        _dateRange = dateRange,
        _searchQuery = searchQuery,
        super(const SalesState()) {
    loadSales();
  }

  Future<void> loadSales() async {
    state = state.copyWith(isLoading: true, clearFailure: true);

    final result = await _repository.getSalesRecords(
      channel: _channel,
      dateRange: _dateRange,
      searchQuery: _searchQuery,
    );

    result.when(
      success: (sales) {
        state = state.copyWith(isLoading: false, sales: sales, clearFailure: true);
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
      },
    );
  }

  Future<Result<SalesRecordModel, AppFailure>> recordWalkInSale(CreateWalkInSaleRequest request) async {
    final result = await _repository.recordWalkInSale(request);
    if (result.isSuccess) {
      await loadSales();
    }
    return result;
  }

  Future<Result<SalesRecordModel, AppFailure>> voidSaleRecord(VoidSaleRequest request) async {
    final result = await _repository.voidSaleRecord(request);
    if (result.isSuccess) {
      await loadSales();
    }
    return result;
  }
}
