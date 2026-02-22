import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../services/order_service.dart';

class LogoutHelper {
  LogoutHelper._();

  static Future<void> logoutAndClear(BuildContext context) async {
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final shoppingListProvider = context.read<ShoppingListProvider>();
    final orderService = context.read<OrderService>();
    final authProvider = context.read<AuthProvider>();

    await Future.wait([
      cartProvider.clearAll(),
      orderProvider.clearAll(),
      shoppingListProvider.clearAll(),
      orderService.clearAll(),
    ]);

    await authProvider.logout();
  }
}
