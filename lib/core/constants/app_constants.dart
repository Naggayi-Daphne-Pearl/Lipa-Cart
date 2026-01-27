class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'LipaCart';
  static const String appTagline = 'Fresh groceries delivered to your doorstep';

  // API Endpoints
  static const String baseUrl = 'http://localhost:1337';
  static const String strapiApiUrl = '$baseUrl/api';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_complete';
  static const String cartKey = 'cart_items';
  static const String addressKey = 'saved_addresses';

  // Validation
  static const int minPasswordLength = 8;
  static const int otpLength = 6;
  static const int phoneNumberLength = 10;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration otpResendDelay = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 20;

  // Currency
  static const String currencySymbol = 'UGX';
  static const String currencyCode = 'UGX';

  // Delivery
  static const double deliveryFeeBase = 3000;
  static const double deliveryFeePerKm = 500;
  static const double serviceFeePercentage = 0.05;

  // Images
  static const String placeholderImage = 'assets/images/placeholder.png';
  static const String logoImage = 'assets/images/logo.png';
}
