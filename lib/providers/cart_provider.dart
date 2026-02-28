import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../core/constants/app_constants.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final _uuid = const Uuid();
  bool _didBootstrap = false;

  CartProvider() {
    _bootstrap();
  }

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  int get totalQuantity =>
      _items.fold(0, (sum, item) => sum + item.quantity.toInt());

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  double get serviceFee => subtotal * AppConstants.serviceFeePercentage;

  double get deliveryFee => AppConstants.deliveryFeeBase;

  double get total => subtotal + serviceFee + deliveryFee;

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  Future<void> _bootstrap() async {
    if (_didBootstrap) return;
    _didBootstrap = true;
    await _restoreCart();
  }

  Future<void> _restoreCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.cartKey);
      if (raw == null || raw.isEmpty) {
        print('DEBUG CartProvider._restoreCart - No cart data to restore');
        return;
      }
      final data = jsonDecode(raw) as List<dynamic>;
      final items = data
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();

      print(
        'DEBUG CartProvider._restoreCart - Restored ${items.length} items from cache',
      );
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        print(
          'DEBUG CartProvider._restoreCart - Item $i: product.id=${item.product.id}, product.strapiId=${item.product.strapiId}, name=${item.product.name}, qty=${item.quantity}',
        );
      }

      _items
        ..clear()
        ..addAll(items);
      notifyListeners();
    } catch (e) {
      print('DEBUG CartProvider._restoreCart - Error restoring cart: $e');
      // Ignore corrupted cache
    }
  }

  Future<void> _persistCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString(AppConstants.cartKey, payload);
    } catch (_) {
      // Ignore persistence errors
    }
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  CartItem? getCartItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  void addToCart(
    Product product, {
    double quantity = 1,
    String? specialInstructions,
  }) {
    print(
      'DEBUG CartProvider.addToCart - product.id: ${product.id}, product.strapiId: ${product.strapiId}, product.name: ${product.name}, quantity: $quantity',
    );

    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      if (specialInstructions != null &&
          specialInstructions.trim().isNotEmpty) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          specialInstructions: specialInstructions.trim(),
        );
      }
      print(
        'DEBUG CartProvider.addToCart - Updated existing item, new quantity: ${_items[existingIndex].quantity}',
      );
    } else {
      final newItem = CartItem(
        id: _uuid.v4(),
        product: product,
        quantity: quantity,
        specialInstructions: specialInstructions?.trim().isEmpty ?? true
            ? null
            : specialInstructions?.trim(),
      );
      _items.add(newItem);
      print(
        'DEBUG CartProvider.addToCart - Added new item to cart, cart size now: ${_items.length}',
      );
    }
    _persistCart();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _persistCart();
    notifyListeners();
  }

  void updateQuantity(String productId, double quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      _persistCart();
      notifyListeners();
    }
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity < item.product.maxQuantity) {
        item.quantity += 1;
        _persistCart();
        notifyListeners();
      }
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity > item.product.minQuantity) {
        item.quantity -= 1;
        _persistCart();
        notifyListeners();
      } else {
        _items.removeAt(index);
        _persistCart();
        notifyListeners();
      }
    }
  }

  void updateSpecialInstructions(String productId, String? instructions) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(specialInstructions: instructions);
      _persistCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _persistCart();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _items.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.cartKey);
    } catch (_) {
      // Ignore persistence errors
    }
    notifyListeners();
  }
}
