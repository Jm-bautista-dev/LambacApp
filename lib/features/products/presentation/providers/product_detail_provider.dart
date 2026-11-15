import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import 'categories_provider.dart';

/// FutureProvider family for retrieving product detail by ID or slug
final productDetailProvider = FutureProvider.family<ProductModel, String>((ref, productId) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProductById(productId);

  return result.when<ProductModel>(
    success: (product) => product,
    failure: (failure) => throw Exception(failure.message),
  );
});
