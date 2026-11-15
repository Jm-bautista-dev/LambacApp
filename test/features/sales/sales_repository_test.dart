import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/models/create_walk_in_sale_request.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_item_model.dart';
import 'package:lambac_app/features/sales/data/models/void_sale_request.dart';
import 'package:lambac_app/features/sales/data/repositories/sales_repository_impl.dart';

void main() {
  group('Centralized Sales Repository Unit Tests', () {
    late MockSalesRemoteDataSource remoteDataSource;
    late SalesRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockSalesRemoteDataSource();
      repository = SalesRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('getSalesRecords retrieves customer mobile app pickup transactions', () async {
      final result = await repository.getSalesRecords();

      expect(result.isSuccess, isTrue);
      final sales = result.dataOrNull!;
      expect(sales.length, greaterThanOrEqualTo(2));
      expect(sales.every((s) => s.channel == SalesChannel.mobileApp), isTrue);
    });

    test('getSalesRecords filters transactions by SalesChannel.mobileApp', () async {
      final result = await repository.getSalesRecords(channel: SalesChannel.mobileApp);

      expect(result.isSuccess, isTrue);
      final sales = result.dataOrNull!;
      expect(sales.every((s) => s.channel == SalesChannel.mobileApp), isTrue);
    });

    test('recordWalkInSale is temporarily disabled and returns ForbiddenFailure', () async {
      final request = const CreateWalkInSaleRequest(
        customerName: 'Customer (Counter)',
        paymentMethod: 'Cash',
        items: [
          SalesRecordItemModel(
            id: 'pos_item_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            size: '250g Bag',
            snapshotUnitPrice: 480.0,
            quantity: 2,
            totalPrice: 960.0,
          ),
        ],
      );

      final result = await repository.recordWalkInSale(request);

      expect(result.isFailure, isTrue);
    });

    test('voidSaleRecord marks transaction as voided with audit reason', () async {
      final request = const VoidSaleRequest(
        saleId: 'sale_8092',
        voidReason: 'Customer requested order cancellation',
      );

      final result = await repository.voidSaleRecord(request);

      expect(result.isSuccess, isTrue);
      final voided = result.dataOrNull!;
      expect(voided.isVoided, isTrue);
      expect(voided.voidReason, equals('Customer requested order cancellation'));
    });
  });
}
