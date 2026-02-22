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

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

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
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as List<dynamic>;
      _items
        ..clear()
        ..addAll(
          data
              .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      notifyListeners();
    } catch (_) {
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

  void addToCart(Product product, {double quantity = 1}) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: _uuid.v4(),
        product: product,
        quantity: quantity,
      ));
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
      _items[index] = _items[index].copyWith(
        specialInstructions: instructions,
      );
      _persistCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _persistCart();
    notifyListeners();
  }
}
