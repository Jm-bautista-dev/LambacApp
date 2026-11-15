import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_remote_datasource.dart';
import 'package:lambac_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:lambac_app/features/products/presentation/providers/categories_provider.dart';
import 'package:lambac_app/features/products/presentation/screens/product_detail_screen.dart';
import 'package:lambac_app/features/products/presentation/screens/products_screen.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  late InMemoryStorageService storageService;
  late MockProductRemoteDataSource remoteDataSource;
  late ProductRepositoryImpl productRepository;

  setUp(() {
    storageService = InMemoryStorageService();
    remoteDataSource = MockProductRemoteDataSource();
    productRepository = ProductRepositoryImpl(
      remoteDataSource: remoteDataSource,
      storageService: storageService,
    );
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(productRepository),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Product Catalog Screens Widget Tests', () {
    testWidgets('ProductsScreen renders search bar and loads product cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const ProductsScreen()));

      expect(find.text('Micro-Lot Coffee Catalog'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Mount Apo Anaerobic Honey Reserve'), findsWidgets);
      expect(find.text('Benguet Arabica Typica Heirloom'), findsWidgets);
    });

    testWidgets('ProductDetailScreen renders tasting notes, variants, and Add to Cart CTA', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          const ProductDetailScreen(productId: 'mt-apo-honey'),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Mount Apo Anaerobic Honey Reserve'), findsOneWidget);
      expect(find.text('Sensory Tasting Notes'), findsOneWidget);
      expect(find.text('Select Bag Size'), findsOneWidget);
      expect(find.text('Select Grind Size'), findsOneWidget);
      expect(find.textContaining('Add • ₱480.00'), findsOneWidget);
    });

    testWidgets('ProductDetailScreen disables Add to Cart when product is Out of Stock', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          const ProductDetailScreen(productId: 'colombia-geisha-rare'),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Colombia Huila Geisha Micro-Lot'), findsOneWidget);
      expect(find.text('Sold Out • Next Batch Soon'), findsOneWidget);
      expect(find.text('Sold Out'), findsWidgets);
    });
  });
}
