import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/theme/app_theme.dart';
import 'package:lambac_app/core/utils/image_validator.dart';
import 'package:lambac_app/features/admin/presentation/widgets/product_image_picker_field.dart';
import 'package:lambac_app/features/products/data/models/product_image_file.dart';

void main() {
  Widget createTestWidget({
    String? initialImageUrl,
    String? errorMessage,
    bool isUploading = false,
    ValueChanged<ProductImageFile?>? onImageSelected,
    ValueChanged<String?>? onUrlChanged,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ProductImagePickerField(
              initialImageUrl: initialImageUrl,
              errorMessage: errorMessage,
              isUploading: isUploading,
              onImageSelected: onImageSelected ?? (_) {},
              onUrlChanged: onUrlChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('ProductImagePickerField UI & Interaction Tests', () {
    testWidgets('1. Renders empty state with restrictions, Camera, Gallery, and Preset chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Header & Badges
      expect(find.text('Product Image'), findsOneWidget);
      expect(find.text('Max 5 MB'), findsOneWidget);

      // Empty State Text
      expect(find.text('Select Product Photograph'), findsOneWidget);
      expect(find.text('JPG · PNG · WebP formats only • Up to 5.0 MB'), findsOneWidget);

      // Action Buttons
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);

      // Presets
      expect(find.text('Quick Preset Photos:'), findsOneWidget);
      expect(find.text('Micro-Lot Beans'), findsOneWidget);
    });

    testWidgets('2. Tapping Gallery selects valid image, updates preview, format badge and file size', (tester) async {
      ProductImageFile? selectedFile;
      String? selectedUrl = 'something';

      await tester.pumpWidget(createTestWidget(
        onImageSelected: (file) => selectedFile = file,
        onUrlChanged: (url) => selectedUrl = url,
      ));
      await tester.pumpAndSettle();

      // Tap Gallery button
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // Verify callback received validated image file
      expect(selectedFile, isNotNull);
      expect(selectedFile!.format, SupportedImageFormat.png);
      expect(selectedUrl, isNull);

      // Verify Preview UI
      expect(find.text('Image Ready'), findsOneWidget);
      expect(find.text('PNG'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Remove'), findsWidgets);
    });

    testWidgets('3. Tapping Camera selects valid JPEG image', (tester) async {
      ProductImageFile? selectedFile;

      await tester.pumpWidget(createTestWidget(
        onImageSelected: (file) => selectedFile = file,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      expect(selectedFile, isNotNull);
      expect(selectedFile!.format, SupportedImageFormat.jpeg);
      expect(find.text('JPEG / JPG'), findsOneWidget);
    });

    testWidgets('4. Tapping Remove clears preview back to empty state', (tester) async {
      ProductImageFile? selectedFile;

      await tester.pumpWidget(createTestWidget(
        onImageSelected: (file) => selectedFile = file,
      ));
      await tester.pumpAndSettle();

      // Pick image
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();
      expect(find.text('Image Ready'), findsOneWidget);

      // Remove image
      await tester.tap(find.text('Remove').first);
      await tester.pumpAndSettle();

      expect(selectedFile, isNull);
      expect(find.text('Select Product Photograph'), findsOneWidget);
    });

    testWidgets('5. Selecting preset chip updates URL and triggers callback', (tester) async {
      String? selectedUrl;

      await tester.pumpWidget(createTestWidget(
        onUrlChanged: (url) => selectedUrl = url,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Micro-Lot Beans'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(selectedUrl, contains('images.unsplash.com'));
      expect(find.text('Image Ready'), findsOneWidget);
      expect(find.text('Web Image'), findsOneWidget);
    });

    testWidgets('6. Displays field-level error banner when errorMessage is provided', (tester) async {
      const errorText = 'Unsupported file type. Please upload a JPG, PNG, or WebP image.';

      await tester.pumpWidget(createTestWidget(errorMessage: errorText));
      await tester.pumpAndSettle();

      expect(find.text(errorText), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('7. Renders spinner and progress status during isUploading', (tester) async {
      await tester.pumpWidget(createTestWidget(isUploading: true));
      await tester.pump(); // do not settle because CircularProgressIndicator is animating

      expect(find.text('Uploading & Validating Product Image...'), findsOneWidget);
      expect(find.text('Verifying magic bytes & generating secure storage key'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
