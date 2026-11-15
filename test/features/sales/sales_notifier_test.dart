import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:lambac_app/features/sales/presentation/providers/sales_provider.dart';

void main() {
  group('Sales State & Provider Unit Tests', () {
    late MockSalesRemoteDataSource remoteDataSource;
    late SalesRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockSalesRemoteDataSource();
      repository = SalesRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('salesChannelFilterProvider updates filtered transaction state', () async {
      final container = ProviderContainer(
        overrides: [
          salesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(salesNotifierProvider.notifier).loadSales();
      final salesState = container.read(salesNotifierProvider);
      expect(salesState.isLoading, isFalse);

      // Filter by Mobile App channel
      container.read(salesChannelFilterProvider.notifier).state = SalesChannel.mobileApp;
      await container.read(salesNotifierProvider.notifier).loadSales();
      final filteredState = container.read(salesNotifierProvider);
      expect(filteredState.sales.every((s) => s.channel == SalesChannel.mobileApp), isTrue);
    });
  });
}
