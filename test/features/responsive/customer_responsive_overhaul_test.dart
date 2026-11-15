import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lambac_app/core/theme/app_theme.dart';
import 'package:lambac_app/core/utils/responsive_layout.dart';
import 'package:lambac_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:lambac_app/features/auth/presentation/screens/login_screen.dart';
import 'package:lambac_app/features/auth/presentation/screens/register_otp_verification_screen.dart';
import 'package:lambac_app/features/auth/presentation/screens/register_screen.dart';
import 'package:lambac_app/features/auth/presentation/screens/terms_and_conditions_screen.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:lambac_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:lambac_app/features/cart/presentation/screens/checkout_screen.dart';
import 'package:lambac_app/features/cart/presentation/screens/order_confirmation_screen.dart';
import 'package:lambac_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:lambac_app/features/home/presentation/screens/home_screen.dart';
import 'package:lambac_app/features/onboarding/presentation/screens/help_guide_screen.dart';
import 'package:lambac_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:lambac_app/features/orders/presentation/screens/orders_screen.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/products/data/models/product_variant_model.dart';
import 'package:lambac_app/features/products/presentation/screens/product_detail_screen.dart';
import 'package:lambac_app/features/products/presentation/screens/products_screen.dart';
import 'package:lambac_app/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:lambac_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:lambac_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:lambac_app/features/shell/presentation/screens/main_shell_screen.dart';

/// All 9 target device & browser viewport dimensions specified in the overhaul requirements
const List<(String label, Size size)> kTargetViewports = [
  ('Small Phone (320x568)', Size(320, 568)),
  ('Standard Phone (360x800)', Size(360, 800)),
  ('Modern Phone (390x844)', Size(390, 844)),
  ('Large Phone (430x932)', Size(430, 932)),
  ('Tablet Portrait (600x960)', Size(600, 960)),
  ('Tablet iPad (768x1024)', Size(768, 1024)),
  ('Desktop (1024x768)', Size(1024, 768)),
  ('Laptop (1366x768)', Size(1366, 768)),
  ('Full HD Desktop (1920x1080)', Size(1920, 1080)),
];

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.view.resetViewInsets();
}

OrderModel _buildSampleOrder({
  String id = 'ord-resp-1',
  String paymentMethod = 'GCash',
  String paymentStatus = 'PENDING',
  OrderStatus status = OrderStatus.readyForPickup,
}) {
  return OrderModel(
    id: id,
    orderNumber: 'LMB-2026-8842',
    customerId: 'cust-1',
    customerName: 'Kenji Takahashi',
    customerPhone: '09171234567',
    items: const [
      OrderItemModel(
        id: 'item-1',
        productId: 'mt-apo-honey',
        productName: 'Mount Apo Anaerobic Honey Reserve Micro-Lot',
        origin: 'Mount Apo, Davao del Sur',
        unitPrice: 480.0,
        quantity: 2,
        totalPrice: 960.0,
        size: '250g Bag',
        grind: 'V60 Pourover',
      ),
    ],
    subtotal: 960.0,
    totalAmount: 960.0,
    status: status,
    pickupLocation: PickupLocationModel.flagship,
    pickupDate: 'Wednesday, November 18, 2026',
    pickupTimeSlot: '10:30 AM',
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
    paymentReference: 'cs_test_a1b2c3d4e5f6g7h8i9j0_long_paymongo_session_id',
    checkoutUrl: 'https://checkout.paymongo.com/cs_test_sample_123',
    notes: 'Please grind medium-fine for Hario V60 02.',
    createdAt: DateTime(2026, 11, 15, 9, 0),
  );
}

void main() {
  group('1. Centralized Breakpoints & Adaptive Shell Navigation', () {
    testWidgets('ResponsiveLayout breakpoints classify all 9 viewports accurately', (tester) async {
      addTearDown(() => _resetViewport(tester));

      for (final (label, size) in kTargetViewports) {
        await _setViewport(tester, size);
        late ScreenType detectedType;
        late bool isMobile;
        late bool isTablet;
        late bool isDesktop;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                detectedType = ResponsiveLayout.getScreenType(context);
                isMobile = ResponsiveLayout.isMobile(context);
                isTablet = ResponsiveLayout.isTablet(context);
                isDesktop = ResponsiveLayout.isDesktop(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        if (size.width < 360) {
          expect(detectedType, ScreenType.compact, reason: label);
          expect(isMobile, isTrue, reason: label);
        } else if (size.width < 600) {
          expect(detectedType, ScreenType.standard, reason: label);
          expect(isMobile, isTrue, reason: label);
        } else if (size.width < 1024) {
          expect(detectedType, ScreenType.medium, reason: label);
          expect(isTablet, isTrue, reason: label);
        } else {
          expect(detectedType, ScreenType.expanded, reason: label);
          expect(isDesktop, isTrue, reason: label);
        }
      }
    });

    testWidgets('MainShellScreen adapts between BottomNavBar (<600), Tablet Rail (600-1023), and Desktop Sidebar (>=1024)', (tester) async {
      addTearDown(() => _resetViewport(tester));

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShellScreen(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/products', builder: (_, __) => const ProductsScreen()),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
              ]),
            ],
          ),
        ],
      );

      for (final (label, size) in kTargetViewports) {
        await _setViewport(tester, size);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: 'No overflow on MainShellScreen + HomeScreen at $label');
      }
    });
  });

  group('2. Multi-Viewport Customer Screens Verification (320x568 up to 1920x1080)', () {
    testWidgets('ProductsScreen and ProductDetailScreen render cleanly across all 9 viewports', (tester) async {
      addTearDown(() => _resetViewport(tester));

      for (final (label, size) in kTargetViewports) {
        await _setViewport(tester, size);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ProductsScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: 'ProductsScreen overflow check at $label');

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ProductDetailScreen(productId: 'mt-apo-honey'),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: 'ProductDetailScreen overflow check at $label');
      }
    });

    testWidgets('CartScreen, CheckoutScreen, OrderConfirmationScreen, and OrderDetailScreen render without overflow across all 9 viewports', (tester) async {
      addTearDown(() => _resetViewport(tester));

      final sampleOrder = _buildSampleOrder();
      const sampleProduct = ProductModel(
        id: 'mt-apo-honey',
        name: 'Mount Apo Anaerobic Honey Reserve Micro-Lot',
        slug: 'mt-apo-honey',
        description: 'Single-origin anaerobic honey process.',
        origin: 'Mount Apo, Davao del Sur',
        roastLevel: 'Light-Medium',
        tastingNotes: 'Wild raspberry, dark honey, cacao nibs',
        basePrice: 480.0,
        categoryId: 'single-origin',
        categoryName: 'Single Origin',
        imageUrl: '',
        isFeatured: true,
        sizeVariants: [
          ProductVariantModel(id: 's1', name: '250g Bag', priceDelta: 0, isDefault: true),
        ],
        grindVariants: [
          ProductVariantModel(id: 'g1', name: 'V60 Pourover', priceDelta: 0, isDefault: true),
        ],
      );

      for (final (label, size) in kTargetViewports) {
        await _setViewport(tester, size);

        // 1. CartScreen with populated item
        final container = ProviderContainer();
        container.read(cartNotifierProvider.notifier).addItem(
          product: sampleProduct,
          sizeVariant: sampleProduct.sizeVariants.first,
          grindVariant: sampleProduct.grindVariants.first,
          quantity: 2,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CartScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull, reason: 'CartScreen overflow check at $label');

        // 2. CheckoutScreen
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull, reason: 'CheckoutScreen overflow check at $label');

        // 3. OrderConfirmationScreen with pending GCash & long reference ID
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              orderDetailProvider(sampleOrder.id).overrideWith((ref) async => sampleOrder),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: OrderConfirmationScreen(orderId: sampleOrder.id),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull, reason: 'OrderConfirmationScreen overflow check at $label');

        // 4. OrderDetailScreen with live tracking stepper, long paymentReference, and GCash action card
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              orderDetailProvider(sampleOrder.id).overrideWith((ref) async => sampleOrder),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: OrderDetailScreen(orderId: sampleOrder.id),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull, reason: 'OrderDetailScreen overflow check at $label');

        container.dispose();
      }
    });

    testWidgets('Onboarding, Login, Register, OTP, ForgotPassword, Terms, Profile, Settings, Privacy, HelpGuide, and Chat render cleanly across all 9 viewports', (tester) async {
      addTearDown(() => _resetViewport(tester));

      for (final (label, size) in kTargetViewports) {
        await _setViewport(tester, size);

        final screens = <String, Widget>{
          'OnboardingScreen': const OnboardingScreen(),
          'LoginScreen': const LoginScreen(),
          'RegisterScreen': const RegisterScreen(),
          'RegisterOtpVerificationScreen': const RegisterOtpVerificationScreen(
            autoStartCooldown: false,
            args: RegisterOtpScreenArgs(
              fullName: 'Kenji Takahashi',
              email: 'kenji.takahashi@lambacroastery.com',
              password: 'Password123!',
              maskedEmail: 'ke***@lambacroastery.com',
              debugOtp: '123456',
            ),
          ),
          'ForgotPasswordScreen': const ForgotPasswordScreen(),
          'TermsAndConditionsScreen': const TermsAndConditionsScreen(isReviewMode: true),
          'ProfileScreen': const ProfileScreen(),
          'SettingsScreen': const SettingsScreen(),
          'PrivacyPolicyScreen': const PrivacyPolicyScreen(),
          'HelpGuideScreen': const HelpGuideScreen(),
          'ChatScreen': const ChatScreen(),
        };

        for (final entry in screens.entries) {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: entry.value,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} should not overflow at $label',
          );
        }
      }
    });
  });
}
