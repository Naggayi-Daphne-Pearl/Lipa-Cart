import 'dart:ui';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat.currency(
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _timeFormat = DateFormat('h:mm a');
  static final _dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String formatPhoneNumber(String phone) {
    if (phone.length < 10) return phone;
    return '+256 ${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
  }

  static String formatQuantity(double quantity, String unit) {
    if (quantity == quantity.truncateToDouble()) {
      return '${quantity.toInt()} $unit';
    }
    return '${quantity.toStringAsFixed(1)} $unit';
  }

  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static String formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns a category-specific background color for product cards.
  static Color getProductBgColor(String? categoryName) {
    switch (categoryName?.toLowerCase()) {
      case 'fruits':
        return const Color(0xFFFFF8E1);
      case 'vegetables':
        return const Color(0xFFE8F5E9);
      case 'meat & fish':
        return const Color(0xFFFFEBEE);
      case 'dairy':
        return const Color(0xFFE3F2FD);
      case 'bakery':
        return const Color(0xFFFFF3E0);
      case 'beverages':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFF5F5F5);
    }
  }
}
