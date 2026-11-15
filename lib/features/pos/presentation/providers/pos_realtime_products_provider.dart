import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/data/models/product_model.dart';
import 'pos_repository_provider.dart';

/// Real-Time Product Catalog Stream Provider
/// Automatically subscribes to Firestore snapshot updates.
/// Any Admin price modification, new product creation, availability toggle,
/// or image change immediately streams to all active POS sessions.
final posProductsStreamProvider = StreamProvider.autoDispose<List<ProductModel>>((ref) {
  final repository = ref.watch(posRepositoryProvider);
  return repository.watchProducts();
});

/// Active Category Filter for POS Screen ('all', 'coffee', 'espresso', etc.)
final posSelectedCategoryProvider = StateProvider.autoDispose<String>((ref) => 'all');

/// Active Search Query for POS Catalog
final posSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Filtered products derived from real-time stream + category chip + search query
final posFilteredProductsProvider = Provider.autoDispose<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(posProductsStreamProvider);
  final selectedCategory = ref.watch(posSelectedCategoryProvider);
  final searchQuery = ref.watch(posSearchQueryProvider).trim().toLowerCase();

  final allProducts = productsAsync.maybeWhen(
    data: (items) => items,
    orElse: () => const <ProductModel>[],
  );

  var list = allProducts;

  // Filter by category
  if (selectedCategory != 'all' && selectedCategory.isNotEmpty) {
    list = list.where((p) => p.categoryId.toLowerCase() == selectedCategory.toLowerCase()).toList();
  }

  // Filter by search query
  if (searchQuery.isNotEmpty) {
    list = list.where((p) {
      return p.name.toLowerCase().contains(searchQuery) ||
          p.origin.toLowerCase().contains(searchQuery) ||
          p.categoryName.toLowerCase().contains(searchQuery) ||
          p.tastingNotes.toLowerCase().contains(searchQuery);
    }).toList();
  }

  // Stable sort: Available products first, then by name
  final sorted = List<ProductModel>.from(list);
  sorted.sort((a, b) {
    if (a.isSoldOut && !b.isSoldOut) return 1;
    if (!a.isSoldOut && b.isSoldOut) return -1;
    return a.name.compareTo(b.name);
  });

  return sorted;
});

/// Live Synchronization Indicator State (true when stream is connected and healthy)
final posLiveSyncStatusProvider = Provider.autoDispose<bool>((ref) {
  final productsAsync = ref.watch(posProductsStreamProvider);
  return productsAsync.hasValue && !productsAsync.hasError;
});
