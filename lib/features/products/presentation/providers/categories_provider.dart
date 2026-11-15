import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/storage_service.dart';
import '../../data/datasources/firebase_product_remote_datasource.dart';
import '../../data/datasources/mock_product_remote_datasource.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/product_category_model.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';

/// Provider for Product Remote Data Source (Cloud Firestore Production Data Source)
final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  try {
    if (Firebase.apps.isEmpty) {
      return MockProductRemoteDataSource();
    }
  } catch (_) {
    return MockProductRemoteDataSource();
  }
  return FirebaseProductRemoteDataSource();
});

/// Provider for Domain ProductRepository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final remoteDataSource = ref.watch(productRemoteDataSourceProvider);
  final storageService = ref.watch(storageServiceProvider);

  return ProductRepositoryImpl(
    remoteDataSource: remoteDataSource,
    storageService: storageService,
  );
});

/// Provider for backend-driven product categories list
final categoriesProvider = FutureProvider<List<ProductCategoryModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getCategories();
  return result.dataOrNull ?? [];
});
