import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import 'categories_provider.dart';

/// Provider for Customer's favorite product IDs set
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return FavoritesNotifier(repository: repository, currentUser: currentUser);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final ProductRepository _repository;
  final UserModel? _currentUser;

  FavoritesNotifier({
    required ProductRepository repository,
    UserModel? currentUser,
  })  : _repository = repository,
        _currentUser = currentUser,
        super(const <String>{}) {
    if (currentUser != null && !currentUser.isGuest) {
      _loadFavorites();
    }
  }

  void reset() {
    state = const <String>{};
  }

  Future<void> _loadFavorites() async {
    final result = await _repository.getFavorites();
    if (!mounted) return;
    if (result.isSuccess) {
      final List<ProductModel> list = result.dataOrNull ?? [];
      final ids = list.map((p) => p.id).toSet();
      state = ids;
    }
  }

  Future<bool> toggleFavorite(String productId) async {
    if (_currentUser == null || _currentUser.isGuest) return false;

    final currentlyFav = state.contains(productId);

    // Optimistic UI update
    if (currentlyFav) {
      state = {...state}..remove(productId);
    } else {
      state = {...state, productId};
    }

    final result = await _repository.toggleFavorite(productId);

    result.when(
      success: (isFav) {
        if (isFav) {
          state = {...state, productId};
        } else {
          state = {...state}..remove(productId);
        }
      },
      failure: (failure) {
        // Revert on error
        if (currentlyFav) {
          state = {...state, productId};
        } else {
          state = {...state}..remove(productId);
        }
      },
    );

    return state.contains(productId);
  }

  bool isFavorite(String productId) => state.contains(productId);
}
