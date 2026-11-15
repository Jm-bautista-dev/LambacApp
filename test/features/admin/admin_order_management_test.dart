import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';

void main() {
  group('Admin Order Management Unit Tests', () {
    late MockAdminRemoteDataSource remoteDataSource;
    late AdminRepositoryImpl adminRepository;

    setUp(() {
      remoteDataSource = MockAdminRemoteDataSource();
      adminRepository = AdminRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('updateOrderStatus transitions order from pending to preparing', () async {
      final result = await adminRepository.updateOrderStatus('ord_lmb_1082', OrderStatus.preparing);

      expect(result.isSuccess, isTrue);
      final updated = result.dataOrNull!;
      expect(updated.status, equals(OrderStatus.preparing));
    });

    test('updateOrderStatus transitions order to readyForPickup', () async {
      final result = await adminRepository.updateOrderStatus('ord_lmb_1082', OrderStatus.readyForPickup);

      expect(result.isSuccess, isTrue);
      final updated = result.dataOrNull!;
      expect(updated.status, equals(OrderStatus.readyForPickup));
    });
  });
}
