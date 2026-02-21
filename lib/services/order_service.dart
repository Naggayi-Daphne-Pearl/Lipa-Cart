import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order.dart';
import '../models/rating.dart';
import '../core/constants/app_constants.dart';

class OrderService extends ChangeNotifier {
  static String get baseUrl => AppConstants.baseUrl;

  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all orders for current customer
  Future<bool> fetchOrders(String token, String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/orders?filters[customer][id][\$eq]=$customerId&populate[order_items][populate]=*&populate[delivery_address]=*&sort=createdAt:desc',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _orders = List<Order>.from(
          (data['data'] as List).map((order) => Order.fromJson(order)),
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Failed to fetch orders';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error fetching orders: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get single order details
  Future<bool> getOrder(String token, int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/orders/$orderId?populate[order_items][populate]=*&populate[delivery_address]=*&populate[shopper]=*&populate[rider]=*',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentOrder = Order.fromJson(data['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Failed to fetch order';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error fetching order: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create new order
  Future<bool> createOrder({
    required String token,
    required int customerId,
    required int addressId,
    required double subtotal,
    required double serviceFee,
    required double deliveryFee,
    required double total,
    String? specialInstructions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {
            'customer': customerId,
            'delivery_address': addressId,
            'subtotal': subtotal,
            'service_fee': serviceFee,
            'delivery_fee': deliveryFee,
            'total': total,
            'status': 'pending',
            'special_instructions': specialInstructions,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _currentOrder = Order.fromJson(data['data']);
        _orders.insert(0, _currentOrder!);
        notifyListeners();
        return true;
      }
      _error = 'Failed to create order';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error creating order: $e';
      notifyListeners();
      return false;
    }
  }

  /// Create order as guest (no authentication required)
  Future<Order?> createGuestOrder({
    required String guestName,
    required String guestPhone,
    required String addressLine,
    String? city,
    String? landmark,
    required double subtotal,
    required double serviceFee,
    required double deliveryFee,
    required double total,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/guest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': guestName,
          'phone': guestPhone,
          'address_line': addressLine,
          'city': city,
          'landmark': landmark,
          'subtotal': subtotal,
          'service_fee': serviceFee,
          'delivery_fee': deliveryFee,
          'total': total,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final order = Order.fromJson(data['data']);
        _currentOrder = order;
        _orders.insert(0, order);
        notifyListeners();
        return order;
      }
      _error = 'Failed to create guest order';
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error creating guest order: $e';
      notifyListeners();
      return null;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(String token, int orderId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cancelledOrder = Order.fromJson(data['data']);
        final index = _orders.indexWhere((o) => o.id == orderId.toString());
        if (index != -1) {
          _orders[index] = cancelledOrder;
        }
        if (_currentOrder?.id == orderId.toString()) {
          _currentOrder = cancelledOrder;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error cancelling order: $e';
      notifyListeners();
      return false;
    }
  }

  /// Submit rating for delivered order
  Future<bool> submitRating({
    required String token,
    required String orderId,
    required double stars,
    required String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {'order': orderId, 'stars': stars, 'comment': comment},
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final rating = Rating.fromJson(data['data']);

        // Update current order with rating
        if (_currentOrder?.id == orderId) {
          _currentOrder = _currentOrder!.copyWith(
            rating: rating,
            hasBeenRated: true,
          );
        }

        // Update order in list
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = _orders[index].copyWith(
            rating: rating,
            hasBeenRated: true,
          );
        }

        notifyListeners();
        return true;
      }
      _error = 'Failed to submit rating';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error submitting rating: $e';
      notifyListeners();
      return false;
    }
  }
}
