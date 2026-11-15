import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../../../shared/models/user_model.dart';
import '../models/product_category_model.dart';
import '../models/product_model.dart';
import 'mock_product_database.dart';
import 'product_remote_datasource.dart';

/// Production Cloud Firestore Data Source for Product Catalog and Categories
class FirebaseProductRemoteDataSource implements ProductRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productsSubscription;
  final List<ProductModel> _cachedProducts = [];
  final Set<String> _localFavorites = {'mt-apo-honey', 'tokyo-blend'};
  final StreamController<List<ProductModel>> _productsStreamController =
      StreamController<List<ProductModel>>.broadcast();

  bool _isSeeded = false;

  FirebaseProductRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _initRealtimeSync();
  }

  /// Real-time stream of catalog products
  Stream<List<ProductModel>> get productsStream => _productsStreamController.stream;

  void _initRealtimeSync() {
    try {
      // Bounded live query to keep a fresh window of hot products without memory bloat
      _productsSubscription = _firestore
          .collection('products')
          .where('customer_visibility', isEqualTo: 'visible')
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        final items = snapshot.docs.map((doc) => _mapDocToProduct(doc)).toList();
        _cachedProducts
          ..clear()
          ..addAll(items);

        if (!_productsStreamController.isClosed) {
          _productsStreamController.add(List.unmodifiable(_cachedProducts));
        }
      }, onError: (Object error) {
        // Fallback or offline ignore
      });
    } catch (_) {}
  }

  void dispose() {
    _productsSubscription?.cancel();
    _productsStreamController.close();
  }

  // ===========================================================================
  // IDEMPOTENT SEEDING MECHANISM
  // ===========================================================================

  /// Seeds default categories and products to Cloud Firestore if not already present.
  /// Strictly idempotent and restricted to authenticated Administrator sessions so
  /// customer or guest browsers never trigger 403 Permission Denied commits.
  Future<void> seedInitialCatalogIfEmpty({bool force = false}) async {
    if (_isSeeded && !force) return;

    final user = _auth.currentUser;
    if (user == null) {
      _isSeeded = true;
      return;
    }

    try {
      final isAdmin = await _isCallerAdmin(user.uid, user.email);
      if (!isAdmin) {
        _isSeeded = true;
        return;
      }

      // 1. Seed Categories if empty
      final categoriesSnap = await _firestore.collection('categories').limit(1).get();
      if (categoriesSnap.docs.isEmpty || force) {
        final batch = _firestore.batch();
        for (final cat in MockProductDatabase.categories) {
          final docRef = _firestore.collection('categories').doc(cat.id);
          batch.set(docRef, cat.toJson(), SetOptions(merge: true));
        }
        await batch.commit();
      }

      // 2. Seed Products if empty
      final productsSnap = await _firestore.collection('products').limit(1).get();
      if (productsSnap.docs.isEmpty || force) {
        final batch = _firestore.batch();
        final defaultProducts = MockProductDatabase().getAllProducts();
        final nowIso = DateTime.now().toIso8601String();

        for (final product in defaultProducts) {
          final docRef = _firestore.collection('products').doc(product.id);
          final map = product.toJson();
          map['created_at'] = product.createdAt?.toIso8601String() ?? nowIso;
          map['updated_at'] = nowIso;
          batch.set(docRef, map, SetOptions(merge: true));
        }
        await batch.commit();
      }

      _isSeeded = true;
    } catch (_) {
      _isSeeded = true;
    }
  }

  Future<bool> _isCallerAdmin(String uid, String? email) async {
    if (email == 'jmbautista0228@gmail.com' || email == 'jmbautistaa0428@gmail.com') {
      return true;
    }
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final role = UserRole.fromString(doc.data()?['role']?.toString());
      return role == UserRole.admin;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // CUSTOMER CATALOG OPERATIONS
  // ===========================================================================

  @override
  Future<Result<PaginatedList<ProductModel>, AppFailure>> getProducts({
    String? categoryId,
    String? search,
    String? roastLevel,
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
  }) async {
    try {
      await seedInitialCatalogIfEmpty();

      // Use single-field equality filter on 'customer_visibility' so Cloud Firestore
      // uses its built-in automatic single-field index and never fails with
      // PRECONDITION_FAILED when composite indexes are not deployed.
      final snapshot = await _firestore
          .collection('products')
          .where('customer_visibility', isEqualTo: 'visible')
          .get();

      List<ProductModel> allVisible;
      if (snapshot.docs.isNotEmpty) {
        allVisible = snapshot.docs.map((doc) => _mapDocToProduct(doc)).toList();
      } else {
        // Fallback to default seed catalog if Firestore is empty and current session (e.g. guest) lacks write permission to seed
        allVisible = MockProductDatabase().getCustomerVisibleProducts();
      }

      // Filter: Category
      if (categoryId != null && categoryId != 'all' && categoryId.isNotEmpty) {
        allVisible = allVisible.where((p) => p.categoryId == categoryId).toList();
      }

      // Filter: Roast Level
      if (roastLevel != null && roastLevel != 'all' && roastLevel.isNotEmpty) {
        allVisible = allVisible.where((p) => p.roastLevel == roastLevel).toList();
      }

      // Filter: Search across multiple fields (name, origin, tastingNotes, categoryName)
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        allVisible = allVisible.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.origin.toLowerCase().contains(q) ||
              p.tastingNotes.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q);
        }).toList();
      }

      // Stable deterministic ordering by name, then document ID tie-breaker
      allVisible.sort((a, b) {
        final nameCmp = a.name.compareTo(b.name);
        if (nameCmp != 0) return nameCmp;
        return a.id.compareTo(b.id);
      });

      final totalCount = allVisible.length;

      // Resolve cursor position
      String? cursorId;
      if (lastDocument is DocumentSnapshot) {
        cursorId = lastDocument.id;
      } else if (lastDocument is String && lastDocument.isNotEmpty) {
        cursorId = lastDocument;
      }

      int startIndex = 0;
      if (cursorId != null) {
        final idx = allVisible.indexWhere((p) => p.id == cursorId);
        if (idx != -1) {
          startIndex = idx + 1;
        }
      } else if (page > 1) {
        startIndex = (page - 1) * limit;
      }

      final endIndex = (startIndex + limit) > totalCount ? totalCount : (startIndex + limit);
      var pageItems = startIndex < totalCount
          ? allVisible.sublist(startIndex, endIndex)
          : <ProductModel>[];

      final hasNextPage = endIndex < totalCount;
      final nextCursor = pageItems.isNotEmpty ? pageItems.last.id : null;

      // Merge favorite status
      final favoriteIds = await _getFavoriteIds();
      pageItems = pageItems.map((p) => p.copyWith(isFavorite: favoriteIds.contains(p.id))).toList();

      return Result.success(
        PaginatedList<ProductModel>(
          items: pageItems,
          page: page,
          pageSize: limit,
          totalCount: totalCount,
          hasNextPage: hasNextPage,
          cursor: nextCursor,
        ),
      );
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to load products: $e'));
    }
  }

  @override
  Future<Result<ProductModel, AppFailure>> getProductById(String id) async {
    try {
      final cleanId = id.trim().toLowerCase();

      // 1. Direct document ID lookup
      final doc = await _firestore.collection('products').doc(cleanId).get();
      if (doc.exists) {
        final product = _mapDocToProduct(doc);
        final favoriteIds = await _getFavoriteIds();
        return Result.success(product.copyWith(isFavorite: favoriteIds.contains(product.id)));
      }

      // 2. Slug-based lookup fallback
      final querySnapshot = await _firestore
          .collection('products')
          .where('slug', isEqualTo: cleanId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final product = _mapDocToProduct(querySnapshot.docs.first);
        final favoriteIds = await _getFavoriteIds();
        return Result.success(product.copyWith(isFavorite: favoriteIds.contains(product.id)));
      }

      // 3. In-memory / cache fallback
      final cached = _cachedProducts.cast<ProductModel?>().firstWhere(
            (p) => p?.id.toLowerCase() == cleanId || p?.slug.toLowerCase() == cleanId,
            orElse: () => null,
          );

      if (cached != null) {
        final favoriteIds = await _getFavoriteIds();
        return Result.success(cached.copyWith(isFavorite: favoriteIds.contains(cached.id)));
      }

      return const Result.failure(
        NotFoundFailure(message: 'Product not found in catalog.'),
      );
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to retrieve product: $e'));
    }
  }

  @override
  Future<Result<List<ProductCategoryModel>, AppFailure>> getCategories() async {
    try {
      await seedInitialCatalogIfEmpty();

      final snapshot = await _firestore
          .collection('categories')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) => _mapDocToCategory(doc)).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return Result.success(list);
      }

      return const Result.success(MockProductDatabase.categories);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to load categories: $e'));
    }
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFeaturedProducts() async {
    try {
      final res = await getProducts();
      if (res.isFailure) {
        return Result.failure(res.failureOrNull!);
      }

      final featured = (res.dataOrNull?.items ?? [])
          .where((p) => p.isFeatured && p.customerVisibility == ProductVisibility.visible)
          .toList();

      return Result.success(featured);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to load featured products: $e'));
    }
  }

  @override
  Future<Result<bool, AppFailure>> toggleFavorite(String productId) async {
    try {
      final user = _auth.currentUser;
      final effectiveUserId = user?.uid;

      final isCurrentlyFavorite = _localFavorites.contains(productId);
      final newFavoriteState = !isCurrentlyFavorite;

      if (newFavoriteState) {
        _localFavorites.add(productId);
      } else {
        _localFavorites.remove(productId);
      }

      if (effectiveUserId != null) {
        final userDoc = _firestore.collection('users').doc(effectiveUserId);
        final favDoc = userDoc.collection('favorites').doc(productId);

        if (newFavoriteState) {
          await favDoc.set({
            'product_id': productId,
            'created_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await userDoc.set({
            'favorite_product_ids': FieldValue.arrayUnion([productId]),
          }, SetOptions(merge: true));
        } else {
          await favDoc.delete();

          await userDoc.set({
            'favorite_product_ids': FieldValue.arrayRemove([productId]),
          }, SetOptions(merge: true));
        }
      }

      return Result.success(newFavoriteState);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to update favorite status: $e'));
    }
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFavorites() async {
    try {
      final user = _auth.currentUser;
      final effectiveUserId = user?.uid;

      Set<String> favoriteIds = Set.from(_localFavorites);

      if (effectiveUserId != null) {
        try {
          final favsSnapshot = await _firestore
              .collection('users')
              .doc(effectiveUserId)
              .collection('favorites')
              .get();

          if (favsSnapshot.docs.isNotEmpty) {
            favoriteIds = favsSnapshot.docs.map((d) => d.id).toSet();
          } else {
            final userDoc = await _firestore.collection('users').doc(effectiveUserId).get();
            final idsList = userDoc.data()?['favorite_product_ids'] as List<dynamic>?;
            if (idsList != null && idsList.isNotEmpty) {
              favoriteIds = idsList.map((e) => e.toString()).toSet();
            }
          }
        } catch (_) {}
      }

      final res = await getProducts(limit: 100);
      if (res.isFailure) {
        return Result.failure(res.failureOrNull!);
      }

      final all = res.dataOrNull?.items ?? [];
      // Products disappear from user's active favorite list if no longer available or visible
      final favs = all.where((p) {
        return favoriteIds.contains(p.id) &&
            p.customerVisibility == ProductVisibility.visible &&
            p.isEnabled &&
            p.availability != ProductAvailability.outOfStock;
      }).toList();

      return Result.success(favs);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to load favorites: $e'));
    }
  }

  // ===========================================================================
  // ADMIN PRODUCT MANAGEMENT (CRUD & GOVERNANCE)
  // ===========================================================================

  /// Admin view: returns all products including hidden and sold out items with pagination support
  Future<Result<List<ProductModel>, AppFailure>> getAllProductsAdmin({
    String? search,
    String? categoryId,
    int limit = 50,
    dynamic lastDocument,
  }) async {
    try {
      await seedInitialCatalogIfEmpty();

      Query<Map<String, dynamic>> query = _firestore.collection('products');

      if (categoryId != null && categoryId != 'all' && categoryId.isNotEmpty) {
        query = query.where('category_id', isEqualTo: categoryId);
      }

      final snapshot = await query.get();
      var products = snapshot.docs.map((doc) => _mapDocToProduct(doc)).toList();

      products.sort((a, b) {
        final nameCmp = a.name.compareTo(b.name);
        if (nameCmp != 0) return nameCmp;
        return a.id.compareTo(b.id);
      });

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        products = products.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.origin.toLowerCase().contains(q) ||
              p.tastingNotes.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q);
        }).toList();
      }

      String? cursorId;
      if (lastDocument is DocumentSnapshot) {
        cursorId = lastDocument.id;
      } else if (lastDocument is String && lastDocument.isNotEmpty) {
        cursorId = lastDocument;
      }

      int startIndex = 0;
      if (cursorId != null) {
        final idx = products.indexWhere((p) => p.id == cursorId);
        if (idx != -1) startIndex = idx + 1;
      }

      final endIndex = (startIndex + limit) > products.length ? products.length : (startIndex + limit);
      final sliced = startIndex < products.length ? products.sublist(startIndex, endIndex) : <ProductModel>[];

      return Result.success(sliced);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to retrieve admin product list: $e'));
    }
  }

  /// Admin create: writes new product document with stable ID to Firestore
  Future<Result<ProductModel, AppFailure>> addProduct(ProductModel product) async {
    final authCheck = await _verifyAdminOrStaffAccess();
    if (authCheck != null) return Result.failure(authCheck);

    if (product.name.trim().length < 2 || product.name.trim().length > 120) {
      return const Result.failure(
        ValidationFailure(message: 'Product name must be between 2 and 120 characters.'),
      );
    }
    if (product.basePrice <= 0 || product.basePrice > 50000) {
      return const Result.failure(
        ValidationFailure(message: 'Product price must be greater than 0 and at most ₱50,000.'),
      );
    }
    if (product.stockQuantity < 0 || product.stockQuantity > 1000000) {
      return const Result.failure(
        ValidationFailure(message: 'Stock quantity must be between 0 and 1,000,000.'),
      );
    }
    if (product.description.length > 2000) {
      return const Result.failure(
        ValidationFailure(message: 'Product description cannot exceed 2000 characters.'),
      );
    }

    try {
      final stableId = (product.id.isEmpty || product.id == 'temp_id')
          ? (product.slug.isNotEmpty ? product.slug : 'prod_${DateTime.now().millisecondsSinceEpoch}')
          : product.id;

      final nowIso = DateTime.now().toIso8601String();
      final savedProduct = product.copyWith(
        id: stableId,
        createdAt: product.createdAt ?? DateTime.now(),
      );

      final map = savedProduct.toJson();
      map['created_at'] = nowIso;
      map['updated_at'] = nowIso;

      await _firestore
          .collection('products')
          .doc(stableId)
          .set(map, SetOptions(merge: true));

      return Result.success(savedProduct);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to add product: $e'));
    }
  }

  /// Admin update: updates existing product document in Firestore
  Future<Result<ProductModel, AppFailure>> updateProduct(ProductModel product) async {
    final authCheck = await _verifyAdminOrStaffAccess();
    if (authCheck != null) return Result.failure(authCheck);

    if (product.name.trim().length < 2 || product.name.trim().length > 120) {
      return const Result.failure(
        ValidationFailure(message: 'Product name must be between 2 and 120 characters.'),
      );
    }
    if (product.basePrice <= 0 || product.basePrice > 50000) {
      return const Result.failure(
        ValidationFailure(message: 'Product price must be greater than 0 and at most ₱50,000.'),
      );
    }
    if (product.stockQuantity < 0 || product.stockQuantity > 1000000) {
      return const Result.failure(
        ValidationFailure(message: 'Stock quantity must be between 0 and 1,000,000.'),
      );
    }
    if (product.description.length > 2000) {
      return const Result.failure(
        ValidationFailure(message: 'Product description cannot exceed 2000 characters.'),
      );
    }

    try {
      final nowIso = DateTime.now().toIso8601String();
      final map = product.toJson();
      map['updated_at'] = nowIso;

      await _firestore
          .collection('products')
          .doc(product.id)
          .set(map, SetOptions(merge: true));

      return Result.success(product);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to update product: $e'));
    }
  }

  /// Admin soft-delete / availability governance:
  /// Updates isEnabled, customerVisibility, availability, and stock in Firestore
  Future<Result<bool, AppFailure>> setProductAvailabilityAndVisibility({
    required String productId,
    required bool isEnabled,
    required ProductVisibility customerVisibility,
  }) async {
    final authCheck = await _verifyAdminOrStaffAccess();
    if (authCheck != null) return Result.failure(authCheck);

    try {
      final docRef = _firestore.collection('products').doc(productId);
      final docSnap = await docRef.get();

      int currentStock = 20;
      if (docSnap.exists) {
        final data = docSnap.data();
        currentStock = (data?['stock_quantity'] ?? data?['stock'] ?? 20) as int;
      }

      ProductAvailability newAvailability;
      int newStock = currentStock;

      if (isEnabled) {
        newAvailability = ProductAvailability.available;
        if (newStock <= 0) newStock = 20;
      } else {
        newAvailability = ProductAvailability.outOfStock;
      }

      await docRef.set({
        'is_enabled': isEnabled,
        'customer_visibility': customerVisibility.name,
        'availability': newAvailability.name,
        'stock_quantity': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      return const Result.success(true);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to update product status: $e'));
    }
  }

  /// Admin toggle availability shortcut
  Future<Result<bool, AppFailure>> toggleProductAvailability(String productId, bool isAvailable) async {
    return setProductAvailabilityAndVisibility(
      productId: productId,
      isEnabled: isAvailable,
      customerVisibility: ProductVisibility.visible,
    );
  }

  /// Admin soft delete product: preserves document for audit/order historical integrity
  Future<Result<bool, AppFailure>> deleteProduct(String productId) async {
    return setProductAvailabilityAndVisibility(
      productId: productId,
      isEnabled: false,
      customerVisibility: ProductVisibility.hidden,
    );
  }

  // ===========================================================================
  // HELPERS & AUTHORIZATION
  // ===========================================================================

  Future<Set<String>> _getFavoriteIds() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          final list = data?['favorite_product_ids'] as List<dynamic>?;
          if (list != null) {
            _localFavorites.clear();
            _localFavorites.addAll(list.map((e) => e.toString()));
          }
        }
      } catch (_) {}
    }
    return Set.unmodifiable(_localFavorites);
  }

  Future<AppFailure?> _verifyAdminOrStaffAccess() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const UnauthorizedFailure(
        message: 'Authentication required. Please sign in as an administrator or staff member.',
      );
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return const ForbiddenFailure(
          message: 'Forbidden: User profile not found in directory.',
        );
      }
      final data = doc.data() ?? {};
      final role = UserRole.fromString(data['role']?.toString());
      final isStaffOrAdmin = role == UserRole.admin || role == UserRole.employee;

      if (!isStaffOrAdmin) {
        return const ForbiddenFailure(
          message: 'Forbidden: Product management requires business staff or admin access.',
        );
      }
      return null;
    } catch (e) {
      return const ForbiddenFailure(
        message: 'Forbidden: Access verification failed.',
      );
    }
  }

  ProductModel _mapDocToProduct(DocumentSnapshot doc) {
    final rawData = doc.data() as Map<String, dynamic>? ?? {};
    final map = Map<String, dynamic>.from(rawData);
    map['id'] = doc.id;

    if (map['created_at'] is Timestamp) {
      map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
    }
    if (map['createdAt'] is Timestamp) {
      map['created_at'] = (map['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (map['updated_at'] is Timestamp) {
      map['updated_at'] = (map['updated_at'] as Timestamp).toDate().toIso8601String();
    }
    return ProductModel.fromJson(map);
  }

  ProductCategoryModel _mapDocToCategory(DocumentSnapshot doc) {
    final rawData = doc.data() as Map<String, dynamic>? ?? {};
    final map = Map<String, dynamic>.from(rawData);
    map['id'] = doc.id;
    return ProductCategoryModel.fromJson(map);
  }

  AppFailure _mapFirebaseException(FirebaseException e, [StackTrace? stackTrace]) {
    return ErrorHandler.handle(
      e,
      stackTrace: stackTrace,
      domain: FailureDomain.firestoreAccess,
      operation: 'product_catalog',
    );
  }
}
