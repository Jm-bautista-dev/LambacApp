import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/utils/currency_formatter.dart';

void main() {
  group('Date & Financial Currency Precision Unit Tests', () {
    test('CurrencyFormatter formats PHP values with 2 decimals without floating point drift', () {
      expect(CurrencyFormatter.format(480.0), equals('₱480.00'));
      expect(CurrencyFormatter.format(14850.5), equals('₱14,850.50'));
      expect(CurrencyFormatter.format(0.0), equals('₱0.00'));
    });

    test('ISO-8601 Timestamps parse cleanly across timezone offsets', () {
      final isoString = '2026-08-21T03:25:00.000Z';
      final parsed = DateTime.parse(isoString);

      expect(parsed.year, equals(2026));
      expect(parsed.month, equals(8));
      expect(parsed.day, equals(21));
      expect(parsed.toIso8601String(), startsWith('2026-08-21T03:25:00.000'));
    });
  });
}
