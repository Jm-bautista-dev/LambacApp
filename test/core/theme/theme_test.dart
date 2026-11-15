import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lambac_app/core/theme/app_animations.dart';
import 'package:lambac_app/core/theme/app_colors.dart';
import 'package:lambac_app/core/theme/app_radius.dart';
import 'package:lambac_app/core/theme/app_spacing.dart';
import 'package:lambac_app/core/theme/app_theme.dart';
import 'package:lambac_app/core/utils/currency_formatter.dart';
import 'package:lambac_app/core/utils/validators.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  group('Design System Tokens & Theme Tests', () {
    test('AppColors light and dark theme contrast integrity', () {
      expect(AppColors.brandAmber, const Color(0xFFC17A48));
      expect(AppColors.lightCanvas, const Color(0xFFFAF7F2));
      expect(AppColors.darkCanvas, const Color(0xFF12100E));
    });

    testWidgets('AppTheme creates valid ThemeData objects', (WidgetTester tester) async {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);
    });

    test('AppRadius, AppSpacing, and AppAnimations tokens integrity', () {
      expect(AppRadius.xs, equals(4.0));
      expect(AppRadius.pill, equals(999.0));
      expect(AppSpacing.lg, equals(16.0));
      expect(AppSpacing.cardPadding, const EdgeInsets.all(16.0));
      expect(AppAnimations.fast, const Duration(milliseconds: 250));
      expect(AppAnimations.micro, const Duration(milliseconds: 150));
    });
  });

  group('Utility Formatter Tests', () {
    test('CurrencyFormatter formats Philippine Peso correctly', () {
      final price1 = CurrencyFormatter.format(480.00);
      expect(price1, contains('480.00'));
      expect(price1, contains('₱'));

      final price2 = CurrencyFormatter.formatCompact(480.00);
      expect(price2, contains('480'));
    });

    test('Validators validate email, phone and passwords correctly', () {
      expect(Validators.email('test@lambaccoffee.com'), isNull);
      expect(Validators.email('invalid-email'), isNotNull);

      expect(Validators.password('Password123'), isNull);
      expect(Validators.password('123'), isNotNull);

      expect(Validators.phone('09171234567'), isNull);
      expect(Validators.phone('1234'), isNotNull);
    });
  });
}
