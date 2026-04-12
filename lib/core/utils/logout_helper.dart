import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../services/order_service.dart';

class LogoutHelper {
  LogoutHelper._();

  /// Comprehensive logout that clears all user data and app state
  /// Clears:
  /// - JWT token & user profile (AuthProvider)
  /// - Shopping cart items (CartProvider)
  /// - Order history & tracking (OrderProvider)
  /// - Shopping lists (ShoppingListProvider)
  /// - Recipe favorites (RecipeProvider)
  /// - Shopper-specific data (ShopperProvider)
  /// - Order service cache (OrderService)
  static Future<void> logoutAndClear(BuildContext context) async {
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final shoppingListProvider = context.read<ShoppingListProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    final shopperProvider = context.read<ShopperProvider>();
    final orderService = context.read<OrderService>();
    final authProvider = context.read<AuthProvider>();

    // Clear all providers in parallel
    await Future.wait([
      cartProvider.clearAll(),
      orderProvider.clearAll(),
      shoppingListProvider.clearAll(),
      recipeProvider.clearAll(),
      shopperProvider.clearAll(),
      orderService.clearAll(),
    ]);

    // Finally, logout auth (clears token & user)
    await authProvider.logout();
  }
}
