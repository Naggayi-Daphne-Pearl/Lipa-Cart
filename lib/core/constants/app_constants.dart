import '../config/app_config.dart';

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'LipaCart';
  static const String appTagline = 'Fresh groceries delivered to your doorstep';

  // API Endpoints — read from --dart-define, defaults to localhost
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const String apiUrl = AppConfig.apiUrl;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_complete';
  static const String cartKey = 'cart_items';
  static const String addressKey = 'saved_addresses';
  static const String preferredDeliveryAddressKey =
      'preferred_delivery_address';
  static const String ordersKey = 'orders_state';
  static const String currentOrderKey = 'current_order';
  static const String shoppingListsKey = 'shopping_lists';

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

  // Delivery Zone — service area center + max radius in km
  // Kampala city center (0.3476, 32.5825)
  static const double serviceAreaCenterLat = 0.3476;
  static const double serviceAreaCenterLng = 32.5825;
  static const double serviceAreaRadiusKm = 15.0; // 15 km from Kampala center

  // Images
  static const String placeholderImage = 'assets/images/placeholder.png';
  static const String logoImage = 'assets/images/logo.png';
}
