import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/routing/app_routes.dart';

void main() {
  group('Routing Architecture Tests', () {
    test('AppRoutes constant paths and names', () {
      expect(AppRoutes.splash, equals('/'));
      expect(AppRoutes.home, equals('/home'));
      expect(AppRoutes.products, equals('/products'));
      expect(AppRoutes.cart, equals('/cart'));
      expect(AppRoutes.orders, equals('/orders'));
      expect(AppRoutes.chat, equals('/chat'));
      expect(AppRoutes.profile, equals('/profile'));
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.register, equals('/register'));
      expect(AppRoutes.checkout, equals('/checkout'));
      expect(AppRoutes.settings, equals('/settings'));
      expect(AppRoutes.analytics, equals('/analytics'));
    });

    test('Product and Order parameterized route generators', () {
      expect(AppRoutes.productDetailPath('apo-123'), equals('/products/apo-123'));
      expect(AppRoutes.orderDetailPath('ord-456'), equals('/orders/ord-456'));
    });

    test('Protected routes list integrity', () {
      expect(AppRoutes.protectedRoutes, contains(AppRoutes.cart));
      expect(AppRoutes.protectedRoutes, contains(AppRoutes.checkout));
      expect(AppRoutes.protectedRoutes, contains(AppRoutes.orders));
      expect(AppRoutes.protectedRoutes, contains(AppRoutes.chat));
      expect(AppRoutes.protectedRoutes, contains(AppRoutes.profile));
      expect(AppRoutes.protectedRoutes, contains(AppRoutes.analytics));
    });
  });
}
