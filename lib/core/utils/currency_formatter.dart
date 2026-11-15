import 'package:intl/intl.dart';

/// Formatter for prices and monetary amounts in Lambac Roastery
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );

  /// Format a numeric amount as standard currency e.g. ₱180.00
  static String format(num amount) {
    return _formatter.format(amount);
  }

  /// Format a numeric amount with no decimals if integer e.g. ₱180
  static String formatCompact(num amount) {
    if (amount % 1 == 0) {
      return _compactFormatter.format(amount);
    }
    return _formatter.format(amount);
  }
}
