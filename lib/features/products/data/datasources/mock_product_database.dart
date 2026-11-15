import '../models/product_category_model.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';

/// Central Authoritative In-Memory Product Database for Lambac Roastery
/// Shared across Customer, Admin, Order, Cart, and Analytics services.
class MockProductDatabase {
  static final MockProductDatabase _instance = MockProductDatabase._internal();
  factory MockProductDatabase() => _instance;

  final List<ProductModel> _products = [];
  final Set<String> _favoriteIds = {'mt-apo-honey', 'tokyo-blend'};

  MockProductDatabase._internal() {
    resetToDefaults();
  }

  static const List<ProductVariantModel> _standardSizeVariants = [
    ProductVariantModel(id: 'size-250g', name: '250g Bag', priceDelta: 0.0, isDefault: true),
    ProductVariantModel(id: 'size-500g', name: '500g Bag', priceDelta: 420.0),
    ProductVariantModel(id: 'size-1kg', name: '1kg Roastery Pack', priceDelta: 1100.0),
  ];

  static const List<ProductVariantModel> _standardGrindVariants = [
    ProductVariantModel(id: 'grind-whole', name: 'Whole Bean (Original)', isDefault: true),
    ProductVariantModel(id: 'grind-espresso', name: 'Espresso (Fine Grind)'),
    ProductVariantModel(id: 'grind-v60', name: 'V60 / Pourover (Medium-Fine)'),
    ProductVariantModel(id: 'grind-aeropress', name: 'Aeropress / Moka Pot'),
    ProductVariantModel(id: 'grind-french', name: 'French Press / Cold Brew (Coarse)'),
  ];

  static const List<ProductCategoryModel> categories = [
    ProductCategoryModel(
      id: 'all',
      name: 'All Roasts',
      slug: 'all',
      sortOrder: 0,
    ),
    ProductCategoryModel(
      id: 'single-origin',
      name: 'Single Origin',
      slug: 'single-origin',
      sortOrder: 1,
    ),
    ProductCategoryModel(
      id: 'micro-lot',
      name: 'Anaerobic Lots',
      slug: 'micro-lot',
      sortOrder: 2,
    ),
    ProductCategoryModel(
      id: 'blends',
      name: 'House Blends',
      slug: 'blends',
      sortOrder: 3,
    ),
    ProductCategoryModel(
      id: 'cold-brew',
      name: 'Cold Brews',
      slug: 'cold-brew',
      sortOrder: 4,
    ),
    ProductCategoryModel(
      id: 'drip-kits',
      name: 'Pour-Over Kits',
      slug: 'drip-kits',
      sortOrder: 5,
    ),
  ];

  void resetToDefaults() {
    _products.clear();
    _products.addAll([
      const ProductModel(
        id: 'mt-apo-honey',
        name: 'Mount Apo Anaerobic Honey Reserve',
        slug: 'mt-apo-honey',
        origin: 'Davao del Sur, Philippines',
        description: 'Hand-picked Catimor cherries fermented anaerobically in stainless tanks for 72 hours before slow drying on raised bamboo African beds. Yields exceptional floral aromas and tropical sweetness.',
        basePrice: 480.0,
        imageUrl: 'https://images.unsplash.com/photo-1587734195503-904fca47e0e9?q=80&w=800&auto=format&fit=crop',
        categoryId: 'micro-lot',
        categoryName: 'Anaerobic Lots',
        roastLevel: 'Light-Medium Roast',
        tastingNotes: 'Wild raspberry, mountain blossom honey, cacao nibs & silky bergamot finish.',
        elevation: '1,500 MASL',
        process: 'Anaerobic Honey (72h)',
        varietal: 'Catimor & Red Bourbon',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 18,
        isFeatured: true,
        sizeVariants: _standardSizeVariants,
        grindVariants: _standardGrindVariants,
      ),
      const ProductModel(
        id: 'benguet-typica',
        name: 'Benguet Arabica Typica Heirloom',
        slug: 'benguet-typica',
        origin: 'Atok, Benguet Highlands',
        description: 'Traditional heritage Typica shade-grown in the pine forests of Atok Benguet at high altitudes. Features a clean, velvety mouthfeel and balanced stone fruit sweetness.',
        basePrice: 420.0,
        imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?q=80&w=800&auto=format&fit=crop',
        categoryId: 'single-origin',
        categoryName: 'Single Origin',
        roastLevel: 'Medium Roast',
        tastingNotes: 'Brown sugar, roasted macadamia nut, sweet orange & crisp malic acidity.',
        elevation: '1,650 MASL',
        process: 'Washed Extended',
        varietal: 'Typica Heirloom',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 24,
        isFeatured: true,
        sizeVariants: _standardSizeVariants,
        grindVariants: _standardGrindVariants,
      ),
      const ProductModel(
        id: 'tokyo-blend',
        name: 'Tokyo Kissaten Signature Blend',
        slug: 'tokyo-blend',
        origin: 'Lambac Roastery House Blend',
        description: 'Our deep, nostalgic Japanese kissaten style blend. Combining dense high-grown Benguet Arabica with natural process Bukidnon beans for a rich, syrupy body with zero bitter astringency.',
        basePrice: 380.0,
        imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=800&auto=format&fit=crop',
        categoryId: 'blends',
        categoryName: 'House Blends',
        roastLevel: 'Dark Roast (French)',
        tastingNotes: 'Dark chocolate fudge, toasted almond, pipe tobacco & molasses sweetness.',
        elevation: '1,400+ MASL',
        process: 'Post-Roast Blend',
        varietal: 'Arabica Blend',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 40,
        isFeatured: true,
        sizeVariants: _standardSizeVariants,
        grindVariants: _standardGrindVariants,
      ),
      const ProductModel(
        id: 'sagada-natural',
        name: 'Sagada Peaberry Micro-Lot Reserve',
        slug: 'sagada-natural',
        origin: 'Sagada, Mountain Province',
        description: 'Rare single-bean peaberry cherries hand-sorted from high-altitude Sagada farms. Concentrated flavor intensity with a sweet, lingering cocoa and herbal tea finish.',
        basePrice: 520.0,
        imageUrl: 'https://images.unsplash.com/photo-1611854779393-1b2da9d400fe?q=80&w=800&auto=format&fit=crop',
        categoryId: 'micro-lot',
        categoryName: 'Anaerobic Lots',
        roastLevel: 'Medium-Light Roast',
        tastingNotes: 'Lemongrass, dark cherry, roasted pine nut & dark cacao finish.',
        elevation: '1,700 MASL',
        process: 'Natural Sun-Dried',
        varietal: 'Peaberry Arabica',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 12,
        isFeatured: false,
        sizeVariants: _standardSizeVariants,
        grindVariants: _standardGrindVariants,
      ),
      const ProductModel(
        id: 'bukidnon-anaerobic',
        name: 'Bukidnon Mount Kitanglad Natural',
        slug: 'bukidnon-anaerobic',
        origin: 'Bukidnon, Mindanao',
        description: 'Grown on the rich volcanic slopes of Mount Kitanglad. Natural processing imparts intense winey fruitiness and a clean caramel sweetness that shines on pourover.',
        basePrice: 450.0,
        imageUrl: 'https://images.unsplash.com/photo-1518832553480-cd0e625ed3e6?q=80&w=800&auto=format&fit=crop',
        categoryId: 'single-origin',
        categoryName: 'Single Origin',
        roastLevel: 'Light Roast',
        tastingNotes: 'Ripe strawberry, passionfruit syrup, jasmine & sugarcane finish.',
        elevation: '1,600 MASL',
        process: 'Full Natural (Slow Dried)',
        varietal: 'Mundo Novo & Catimor',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 20,
        isFeatured: false,
        sizeVariants: _standardSizeVariants,
        grindVariants: _standardGrindVariants,
      ),
      const ProductModel(
        id: 'barako-premium',
        name: 'Batangas Liberica Barako Heritage',
        slug: 'barako-premium',
        origin: 'Lipa, Batangas',
        description: 'Giant-leaf Liberica beans from old-growth trees in Batangas. Bold, aromatic, woody cup with a sweet jackfruit aftertaste that redefines Philippine Barako coffee.',
        basePrice: 350.0,
        imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=800&auto=format&fit=crop',
        categoryId: 'single-origin',
        categoryName: 'Single Origin',
        roastLevel: 'Dark Roast',
        tastingNotes: 'Jackfruit, toasted wood, dark cocoa & smoky sweet spice.',
        elevation: '400 MASL',
        process: 'Traditional Washed',
        varietal: 'Coffea Liberica',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 30,
        isFeatured: false,
        sizeVariants: _standardSizeVariants,
        grindVariants: _standardGrindVariants,
      ),
      const ProductModel(
        id: 'colombia-geisha-rare',
        name: 'Colombia Huila Geisha Micro-Lot',
        slug: 'colombia-geisha-rare',
        origin: 'Huila, Colombia',
        description: 'Ultra-exclusive micro-lot with intense floral, bergamot, and peach notes.',
        basePrice: 650.0,
        imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=800&auto=format&fit=crop',
        categoryId: 'micro-lot',
        categoryName: 'Anaerobic Lots',
        roastLevel: 'Light Roast',
        tastingNotes: 'Bergamot, jasmine, white peach & raw honey finish.',
        isEnabled: false,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.outOfStock,
        stockQuantity: 0,
        isFeatured: false,
        sizeVariants: _standardSizeVariants,
        grindVariants: _standardGrindVariants,
      ),
      const ProductModel(
        id: 'cold-brew-concentrate',
        name: 'Lambac Nitro Cold Brew Concentrate',
        slug: 'cold-brew-concentrate',
        origin: 'Baguio City, Philippines',
        description: 'Slow-steeped for 24 hours at 4°C using our signature dark roast.',
        basePrice: 280.0,
        imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?q=80&w=800&auto=format&fit=crop',
        categoryId: 'cold-brew',
        categoryName: 'Cold Brews',
        roastLevel: 'Dark Roast',
        tastingNotes: 'Dark chocolate, cacao nibs & silky cream finish.',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 25,
        isFeatured: false,
        sizeVariants: _standardSizeVariants,
        grindVariants: _standardGrindVariants,
      ),
      const ProductModel(
        id: 'drip-bag-box',
        name: 'Signature Drip Bag Craft Box',
        slug: 'drip-bag-box',
        origin: 'Cordillera Highlands',
        description: 'Single-serve nitro-flushed pour-over drip bags for travel and office brewing.',
        basePrice: 320.0,
        imageUrl: 'https://images.unsplash.com/photo-1511920170033-f8396924c348?q=80&w=800&auto=format&fit=crop',
        categoryId: 'drip-kits',
        categoryName: 'Pour-Over Kits',
        roastLevel: 'Medium Roast',
        tastingNotes: 'Toffee, brown sugar & roasted hazelnut.',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 30,
        isFeatured: false,
        sizeVariants: _standardSizeVariants,
        grindVariants: _standardGrindVariants,
      ),
    ]);
  }

  /// All products (for Admin, Analytics, Forecasting)
  List<ProductModel> getAllProducts() {
    return _products.map((p) => p.copyWith(isFavorite: _favoriteIds.contains(p.id))).toList();
  }

  /// Only customer visible products (excluding hidden ones)
  List<ProductModel> getCustomerVisibleProducts() {
    return _products
        .where((p) => p.customerVisibility == ProductVisibility.visible)
        .map((p) => p.copyWith(isFavorite: _favoriteIds.contains(p.id)))
        .toList();
  }

  ProductModel? getProductById(String id) {
    try {
      final cleanId = id.trim().toLowerCase();
      final product = _products.firstWhere(
        (p) =>
            p.id.toLowerCase() == cleanId ||
            p.slug.toLowerCase() == cleanId ||
            p.id.toLowerCase().startsWith(cleanId) ||
            cleanId.startsWith(p.id.toLowerCase()),
      );
      return product.copyWith(isFavorite: _favoriteIds.contains(product.id));
    } catch (_) {
      return null;
    }
  }

  ProductModel addProduct(ProductModel product) {
    final newId = product.id.isEmpty || product.id == 'temp_id'
        ? 'prod_new_${DateTime.now().millisecondsSinceEpoch}'
        : product.id;
    final saved = product.copyWith(id: newId);
    _products.add(saved);
    return saved;
  }

  ProductModel updateProduct(ProductModel product) {
    final index = _products.indexWhere((p) => p.id == product.id || p.slug == product.slug);
    if (index >= 0) {
      _products[index] = product;
      return product;
    } else {
      _products.add(product);
      return product;
    }
  }

  /// Update Product Availability and Customer Visibility State
  bool setProductStatus({
    required String productId,
    required bool isEnabled,
    required ProductVisibility customerVisibility,
  }) {
    final index = _products.indexWhere((p) => p.id == productId || p.slug == productId);
    if (index < 0) return false;

    final existing = _products[index];

    ProductAvailability newAvailability;
    int newStock = existing.stockQuantity;

    if (isEnabled) {
      // Re-enabled product becomes Available
      newAvailability = ProductAvailability.available;
      if (newStock <= 0) newStock = 20;
    } else {
      // Disabled product is marked outOfStock (whether visible/sold out or hidden)
      newAvailability = ProductAvailability.outOfStock;
    }

    final updated = existing.copyWith(
      isEnabled: isEnabled,
      customerVisibility: customerVisibility,
      availability: newAvailability,
      stockQuantity: newStock,
    );

    _products[index] = updated;
    return true;
  }

  /// Atomically adjust product stock quantity and update availability
  bool updateStock(String productId, int quantityDelta) {
    final index = _products.indexWhere((p) => p.id == productId || p.slug == productId);
    if (index < 0) return false;

    final existing = _products[index];
    final newStock = (existing.stockQuantity + quantityDelta).clamp(0, 999999);
    final newAvailability = newStock == 0
        ? ProductAvailability.outOfStock
        : (newStock <= 5 ? ProductAvailability.lowStock : ProductAvailability.available);

    final updated = existing.copyWith(
      stockQuantity: newStock,
      availability: newAvailability,
    );

    _products[index] = updated;
    return true;
  }

  bool toggleFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      return false;
    } else {
      _favoriteIds.add(productId);
      return true;
    }
  }

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  void resetForTesting() {
    resetToDefaults();
  }
}
