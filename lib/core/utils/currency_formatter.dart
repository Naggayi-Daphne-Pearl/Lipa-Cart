import '../constants/app_constants.dart';

/// Utility class for formatting currency amounts
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format amount with currency symbol
  /// Example: formatCurrency(1500) => "UGX 1,500"
  static String format(double amount) {
    return '$currencySymbol ${_formatNumber(amount)}';
  }

  /// Format amount without currency symbol
  /// Example: formatAmount(1500) => "1,500"
  static String formatAmount(double amount) {
    return _formatNumber(amount);
  }

  /// Get currency symbol
  static String get currencySymbol => AppConstants.currencySymbol;

  /// Get currency code
  static String get currencyCode => AppConstants.currencyCode;

  /// Format number with thousand separators
  static String _formatNumber(double amount) {
    // Format to 2 decimal places if it has cents, otherwise no decimals
    final absAmount = amount.abs();
    if (absAmount >= 1 && absAmount % 1 == 0) {
      // No decimal places needed
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => ',',
          );
    } else {
      // Keep 2 decimal places
      return amount.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => ',',
          );
    }
  }
}
