import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';

void main() {
  group('Admin Product Management Unit Tests', () {
    late MockAdminRemoteDataSource remoteDataSource;
    late AdminRepositoryImpl adminRepository;

    setUp(() {
      MockUserDatabase().seedDefaultUsers();
      MockUserDatabase().setCurrentUser(
        MockUserDatabase().getByEmail('jmbautista0228@gmail.com')!.user,
      );
      remoteDataSource = MockAdminRemoteDataSource();
      adminRepository = AdminRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('getBusinessMetrics returns sales, order counts, and popular products', () async {
      final result = await adminRepository.getBusinessMetrics();

      expect(result.isSuccess, isTrue);
      final metrics = result.dataOrNull!;
      expect(metrics.todaySales, greaterThanOrEqualTo(0.0));
      expect(metrics.todayOrdersCount, greaterThanOrEqualTo(0));
      expect(metrics.popularProducts.isNotEmpty, isTrue);
    });

    test('addProduct creates new roast product in business catalog', () async {
      const newProduct = ProductModel(
        id: 'temp_id',
        name: 'Bukidnon Miravalles Geisha',
        slug: 'bukidnon-geisha',
        origin: 'Bukidnon, Philippines',
        description: 'Single-estate Geisha harvest',
        basePrice: 650.0,
        categoryId: 'micro-lot',
        categoryName: 'Anaerobic Lots',
        roastLevel: 'Light Roast',
        tastingNotes: 'White floral, honey, nectarine',
      );

      final result = await adminRepository.addProduct(newProduct);

      expect(result.isSuccess, isTrue);
      final saved = result.dataOrNull!;
      expect(saved.name, equals('Bukidnon Miravalles Geisha'));
      expect(saved.id, startsWith('prod_new_'));
    });

    test('toggleProductAvailability updates roast availability state', () async {
      final result = await adminRepository.toggleProductAvailability('mt-apo-honey', false);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isFalse);
    });
  });
}
