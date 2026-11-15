import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/app.dart';
import 'package:lambac_app/core/config/app_config.dart';
import 'package:lambac_app/core/config/flavor_provider.dart';
import 'package:lambac_app/core/widgets/buttons/app_button.dart';
import 'package:lambac_app/core/widgets/cards/app_card.dart';
import 'package:lambac_app/core/widgets/chips/app_chip.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  testWidgets('Lambac App boots up and renders root widget tree', (WidgetTester tester) async {
    final inMemoryStorage = InMemoryStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.development()),
          storageServiceProvider.overrideWithValue(inMemoryStorage),
        ],
        child: const LambacApp(),
      ),
    );

    // Initial pump (renders splash screen)
    expect(find.byType(LambacApp), findsOneWidget);
    expect(find.text('LAMBAC'), findsOneWidget);
    expect(find.text('COFFEE ROASTERY'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Design system AppButton renders and responds to tap', (WidgetTester tester) async {
    bool wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            text: 'Order Single Origin',
            onPressed: () => wasPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Order Single Origin'), findsOneWidget);
    await tester.tap(find.text('Order Single Origin'));
    expect(wasPressed, isTrue);
  });

  testWidgets('Design system AppCard and AppChip render properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCard(
            child: AppChip(
              label: 'Anaerobic Light Roast',
              isSelected: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Anaerobic Light Roast'), findsOneWidget);
  });
}
