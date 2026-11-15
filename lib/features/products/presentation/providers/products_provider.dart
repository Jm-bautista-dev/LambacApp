import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import 'categories_provider.dart';

/// State object for Products Catalog
class ProductsState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final dynamic lastDocument;
  final String? loadMoreError;
  final List<ProductModel> products;
  final String selectedCategoryId;
  final String searchQuery;
  final String selectedRoastLevel;
  final bool isGridView;
  final AppFailure? failure;

  const ProductsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.lastDocument,
    this.loadMoreError,
    this.products = const [],
    this.selectedCategoryId = 'all',
    this.searchQuery = '',
    this.selectedRoastLevel = 'all',
    this.isGridView = false,
    this.failure,
  });

  List<ProductModel> get filteredProducts => products;

  ProductsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    dynamic lastDocument,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    List<ProductModel>? products,
    String? selectedCategoryId,
    String? searchQuery,
    String? selectedRoastLevel,
    bool? isGridView,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return ProductsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      lastDocument: lastDocument ?? this.lastDocument,
      loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      products: products ?? this.products,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRoastLevel: selectedRoastLevel ?? this.selectedRoastLevel,
      isGridView: isGridView ?? this.isGridView,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingMore,
        hasMore,
        page,
        lastDocument,
        loadMoreError,
        products,
        selectedCategoryId,
        searchQuery,
        selectedRoastLevel,
        isGridView,
        failure,
      ];
}

/// Provider for Products Catalog StateNotifier
final productsNotifierProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductsNotifier(repository: repository);
});

class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductRepository _repository;
  Timer? _debounceTimer;

  ProductsNotifier({required ProductRepository repository})
      : _repository = repository,
        super(const ProductsState()) {
    loadProducts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  int _searchSequence = 0;

  Future<void> loadProducts({bool isRefresh = false}) async {
    final currentSeq = ++_searchSequence;
    if (!isRefresh) {
      state = state.copyWith(
        isLoading: true,
        clearFailure: true,
        hasMore: true,
        page: 1,
        lastDocument: null,
        clearLoadMoreError: true,
      );
    } else {
      state = state.copyWith(
        hasMore: true,
        page: 1,
        lastDocument: null,
        clearLoadMoreError: true,
      );
    }

    final result = await _repository.getProducts(
      categoryId: state.selectedCategoryId == 'all' ? null : state.selectedCategoryId,
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      roastLevel: state.selectedRoastLevel == 'all' ? null : state.selectedRoastLevel,
      page: 1,
      limit: 20,
      lastDocument: null,
    );

    if (!mounted || currentSeq != _searchSequence) return;

    result.when(
      success: (paginated) {
        if (!mounted || currentSeq != _searchSequence) return;
        state = state.copyWith(
          isLoading: false,
          products: paginated.items,
          hasMore: paginated.hasNextPage,
          page: 1,
          lastDocument: paginated.cursor,
          clearFailure: true,
          clearLoadMoreError: true,
        );
      },
      failure: (failure) {
        if (!mounted || currentSeq != _searchSequence) return;
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
    );
  }

  Future<void> loadMoreProducts() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final currentSeq = _searchSequence;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);

    final nextPage = state.page + 1;
    final result = await _repository.getProducts(
      categoryId: state.selectedCategoryId == 'all' ? null : state.selectedCategoryId,
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      roastLevel: state.selectedRoastLevel == 'all' ? null : state.selectedRoastLevel,
      page: nextPage,
      limit: 20,
      lastDocument: state.lastDocument,
    );

    if (!mounted || currentSeq != _searchSequence) return;

    result.when(
      success: (paginated) {
        if (!mounted || currentSeq != _searchSequence) return;

        // Deduplicate incoming products against existing
        final existingIds = state.products.map((p) => p.id).toSet();
        final newItems = paginated.items.where((p) => !existingIds.contains(p.id)).toList();

        state = state.copyWith(
          isLoadingMore: false,
          products: [...state.products, ...newItems],
          hasMore: paginated.hasNextPage,
          page: nextPage,
          lastDocument: paginated.cursor,
          clearLoadMoreError: true,
        );
      },
      failure: (failure) {
        if (!mounted || currentSeq != _searchSequence) return;
        state = state.copyWith(
          isLoadingMore: false,
          loadMoreError: failure.message,
        );
      },
    );
  }

  void selectCategory(String categoryId) {
    if (state.selectedCategoryId == categoryId) return;
    state = state.copyWith(
      selectedCategoryId: categoryId,
      lastDocument: null,
      page: 1,
      hasMore: true,
    );
    loadProducts();
  }

  void setRoastLevel(String roastLevel) {
    if (state.selectedRoastLevel == roastLevel) return;
    state = state.copyWith(
      selectedRoastLevel: roastLevel,
      lastDocument: null,
      page: 1,
      hasMore: true,
    );
    loadProducts();
  }

  void setSearchQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (state.searchQuery != query) {
        state = state.copyWith(
          searchQuery: query,
          lastDocument: null,
          page: 1,
          hasMore: true,
        );
        loadProducts();
      }
    });
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = state.copyWith(
      searchQuery: '',
      selectedCategoryId: 'all',
      lastDocument: null,
      page: 1,
      hasMore: true,
    );
    loadProducts();
  }

  void toggleViewMode() {
    state = state.copyWith(isGridView: !state.isGridView);
  }
}
