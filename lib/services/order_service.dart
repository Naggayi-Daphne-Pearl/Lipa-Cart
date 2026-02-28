import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order.dart';
import '../models/rating.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart' as user_models;
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

  Future<void> clearAll() async {
    _orders = [];
    _currentOrder = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  OrderStatus _mapStatus(String? status) {
    switch (status) {
      case 'payment_confirmed':
      case 'shopper_assigned':
        return OrderStatus.confirmed;
      case 'ready_for_pickup':
        return OrderStatus.readyForDelivery;
      case 'in_transit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'shopping':
        return OrderStatus.shopping;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  List<CartItem> _parseOrderItems(Map<String, dynamic> attributes) {
    // Handle both wrapped and flat formats
    final orderItemsRaw = attributes['order_items'];

    print(
      'DEBUG: _parseOrderItems - orderItemsRaw type: ${orderItemsRaw.runtimeType}',
    );
    print('DEBUG: _parseOrderItems - orderItemsRaw value: $orderItemsRaw');

    List<dynamic> orderItems = [];
    if (orderItemsRaw is List<dynamic>) {
      // Flat format: direct array
      orderItems = orderItemsRaw;
      print('DEBUG: Parsed as direct array, count: ${orderItems.length}');
    } else if (orderItemsRaw is Map<String, dynamic> &&
        orderItemsRaw.containsKey('data')) {
      // Wrapped format: {data: [...]}
      orderItems = (orderItemsRaw['data'] as List<dynamic>?) ?? [];
      print('DEBUG: Parsed as wrapped format, count: ${orderItems.length}');
    } else {
      print('DEBUG: No order_items found or invalid format');
    }

    final parsedItems = orderItems.map((item) {
      final itemAttrs = (item['attributes'] as Map<String, dynamic>?) ?? item;
      final productName = itemAttrs['product_name'] as String? ?? 'Item';
      final quantity = (itemAttrs['quantity'] as num?)?.toDouble() ?? 1;
      final unit = itemAttrs['unit'] as String? ?? 'unit';
      final estimatedPrice =
          (itemAttrs['estimated_price'] as num?)?.toDouble() ?? 0;

      print(
        'DEBUG: Parsed order item - name: $productName, qty: $quantity, price: $estimatedPrice',
      );

      final productData =
          (itemAttrs['product']?['data'] as Map<String, dynamic>?) ??
          itemAttrs['product'];
      final productId = productData is Map
          ? (productData['documentId'] ?? productData['id']).toString()
          : productData?.toString() ?? '';

      final product = Product(
        id: productId.isEmpty ? 'unknown' : productId,
        name: productName,
        description: '',
        image: '',
        price: estimatedPrice,
        unit: unit,
        categoryId: '',
        categoryName: '',
        isAvailable: true,
      );

      return CartItem(
        id: (item['id'] ?? '').toString(),
        product: product,
        quantity: quantity,
        specialInstructions: itemAttrs['special_instructions'] as String?,
      );
    }).toList();

    print('DEBUG: Final parsed items count: ${parsedItems.length}');
    return parsedItems;
  }

  user_models.Address _parseDeliveryAddress(Map<String, dynamic> attributes) {
    // Handle both wrapped and flat formats
    final addressRaw = attributes['delivery_address'];

    Map<String, dynamic>? addressData;
    if (addressRaw is Map<String, dynamic>) {
      // Check if it has 'data' key (wrapped format)
      if (addressRaw.containsKey('data') &&
          addressRaw['data'] is Map<String, dynamic>) {
        addressData = addressRaw['data'];
      } else {
        // Flat format: use directly
        addressData = addressRaw;
      }
    }

    if (addressData == null || addressData.isEmpty) {
      return user_models.Address(
        id: '0',
        label: 'Delivery Address',
        fullAddress: '',
        landmark: null,
        latitude: 0.0,
        longitude: 0.0,
        isDefault: false,
      );
    }

    final addressAttrs =
        (addressData['attributes'] as Map<String, dynamic>?) ?? addressData;

    final label = addressAttrs['label'] as String? ?? 'Delivery Address';
    final addressLine = addressAttrs['address_line'] as String? ?? '';
    final city = addressAttrs['city'] as String? ?? '';
    final landmark = addressAttrs['landmark'] as String?;
    final fullAddress =
        '$addressLine${city.isNotEmpty ? ', $city' : ''}${landmark != null && landmark.isNotEmpty ? ', $landmark' : ''}';

    return user_models.Address(
      id: (addressData['id'] ?? addressData['documentId'] ?? '0').toString(),
      label: label,
      fullAddress: fullAddress,
      landmark: landmark,
      latitude: (addressAttrs['gps_lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (addressAttrs['gps_lng'] as num?)?.toDouble() ?? 0.0,
      isDefault: addressAttrs['is_default'] as bool? ?? false,
    );
  }

  Order _fromStrapi(Map<String, dynamic> data) {
    final attributes = (data['attributes'] as Map<String, dynamic>?) ?? data;
    final rawId = data['id'] ?? data['documentId'];
    final orderNumber =
        (attributes['order_number'] ?? attributes['orderNumber'])?.toString() ??
        data['id'].toString();

    print('DEBUG: _fromStrapi - Order ID: $rawId');
    print('DEBUG: _fromStrapi - Order Number: $orderNumber');
    print('DEBUG: _fromStrapi - Attributes keys: ${attributes.keys.toList()}');

    final items = _parseOrderItems(attributes);
    print('DEBUG: _fromStrapi - Final order items count: ${items.length}');

    return Order(
      id: rawId?.toString() ?? '',
      orderNumber: orderNumber,
      items: items,
      deliveryAddress: _parseDeliveryAddress(attributes),
      subtotal: (attributes['subtotal'] as num?)?.toDouble() ?? 0,
      serviceFee: (attributes['service_fee'] as num?)?.toDouble() ?? 0,
      deliveryFee: (attributes['delivery_fee'] as num?)?.toDouble() ?? 0,
      total: (attributes['total'] as num?)?.toDouble() ?? 0,
      status: _mapStatus(attributes['status'] as String?),
      createdAt:
          DateTime.tryParse(attributes['createdAt'] as String? ?? '') ??
          DateTime.now(),
      estimatedDelivery: DateTime.tryParse(
        attributes['estimated_delivery'] as String? ?? '',
      ),
      deliveredAt: DateTime.tryParse(
        attributes['delivered_at'] as String? ?? '',
      ),
      cancellationReason: attributes['cancellation_reason'] as String?,
      paymentMethod: PaymentMethod.mobileMoney,
      isPaid: false,
    );
  }

  /// Fetch all orders for current customer
  Future<bool> fetchOrders(String token, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url =
          '$baseUrl/api/orders?filters[customer][id][\$eq]=$userId&populate[order_items]=*&populate[delivery_address]=*&sort=createdAt:desc';

      print('DEBUG: Fetching orders from $url');
      print('DEBUG: Using userId=$userId');
      print('DEBUG: Token length=${token.length}');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('DEBUG: Orders response status=${response.statusCode}');
      print('DEBUG: Orders response body length=${response.body.length}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: fetchOrders response data keys: ${(data as Map).keys}');
        print(
          'DEBUG: fetchOrders data["data"] type: ${data["data"].runtimeType}',
        );
        print(
          'DEBUG: fetchOrders total orders in response: ${(data["data"] as List).length}',
        );

        _orders = List<Order>.from(
          (data['data'] as List).map((order) {
            print(
              'DEBUG: Processing order in list - id: ${order["id"]}, has attributes: ${order.containsKey("attributes")}',
            );
            final parsed = _fromStrapi(order);
            print(
              'DEBUG: Parsed order - id: ${parsed.id}, items count: ${parsed.items.length}, itemCount: ${parsed.itemCount}',
            );
            return parsed;
          }),
        );
        print('DEBUG: Orders parsed count=${_orders.length}');
        for (var i = 0; i < _orders.length; i++) {
          print(
            'DEBUG: Order $i - items: ${_orders[i].items.length}, itemCount: ${_orders[i].itemCount}',
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      print('DEBUG: Orders fetch failed with status ${response.statusCode}');
      print('DEBUG: Response: ${response.body.substring(0, 200)}');
      _error = 'Failed to fetch orders (${response.statusCode})';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('DEBUG: Orders fetch exception: $e');
      _error = 'Error fetching orders: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get single order details
  Future<bool> getOrder(String token, String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/orders/$orderId?populate[order_items]=*&populate[delivery_address]=*',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentOrder = _fromStrapi(data['data']);
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
    required String customerId,
    required String addressId,
    required double subtotal,
    required double serviceFee,
    required double deliveryFee,
    required double total,
    String? specialInstructions,
  }) async {
    try {
      final orderNumber =
          'LC${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      print('DEBUG: Creating order with number: $orderNumber');
      print('DEBUG: Customer ID: $customerId, Address ID: $addressId');

      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {
            'order_number': orderNumber,
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

      print('DEBUG: Order creation response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _currentOrder = _fromStrapi(data['data']);
        _orders.insert(0, _currentOrder!);
        print(
          'DEBUG: Order created successfully with ID: ${_currentOrder!.id}',
        );
        notifyListeners();
        return true;
      }

      print('DEBUG: Order creation FAILED - status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');
      _error = 'Failed to create order (${response.statusCode})';
      notifyListeners();
      return false;
    } catch (e) {
      print('DEBUG: Order creation exception: $e');
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
        final order = _fromStrapi(data['data']);
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
  Future<bool> cancelOrder(String token, String orderId) async {
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
        final cancelledOrder = _fromStrapi(data['data']);
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = cancelledOrder;
        }
        if (_currentOrder?.id == orderId) {
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

  Future<Order?> createOrderWithItems({
    required String token,
    required String userId,
    required String addressId,
    required List<CartItem> items,
    required double subtotal,
    required double serviceFee,
    required double deliveryFee,
    required double total,
    String? specialInstructions,
  }) async {
    final orderCreated = await createOrder(
      token: token,
      customerId: userId,
      addressId: addressId,
      subtotal: subtotal,
      serviceFee: serviceFee,
      deliveryFee: deliveryFee,
      total: total,
      specialInstructions: specialInstructions,
    );

    if (!orderCreated || _currentOrder == null) return null;

    final orderId = _currentOrder!.id;
    print('DEBUG: createOrderWithItems - Order created with ID: $orderId');
    print('DEBUG: createOrderWithItems - Creating ${items.length} order items');

    try {
      // Prepare all items for bulk creation
      final itemsData = items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final productId = item.product.id;

        print(
          'DEBUG: [Item $index] Creating order item - product: ${item.product.name}, quantity: ${item.quantity}, productId: $productId (strapiId: ${item.product.strapiId}), orderId: $orderId',
        );

        return {
          'order': orderId,
          // Only include product if it's a real linked product (strapiId != null)
          if (item.product.strapiId != null) 'product': productId,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit': item.product.unit,
          'estimated_price': item.product.price,
          if (item.specialInstructions != null)
            'special_instructions': item.specialInstructions,
        };
      }).toList();

      print('DEBUG: Bulk creating ${itemsData.length} order items');
      print('DEBUG: Request body: ${jsonEncode({'items': itemsData})}');

      // Single bulk request to create all items
      final response = await http.post(
        Uri.parse('$baseUrl/api/order-items/bulk'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'items': itemsData}),
      );

      print('DEBUG: Bulk create response status: ${response.statusCode}');
      print('DEBUG: Bulk create response body: ${response.body}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        print('DEBUG: Bulk create FAILED - status: ${response.statusCode}');

        // Parse error for better diagnostics
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
          if (errorMsg.contains('do not exist')) {
            _error =
                'Some products do not exist in the database. '
                'This may happen if you\'re using sample data. '
                'Error: $errorMsg';
          } else {
            _error = 'Failed to create order items: $errorMsg';
          }
        } catch (_) {
          _error =
              'Failed to create order items (status ${response.statusCode})';
        }
        notifyListeners();
        return _currentOrder;
      }

      final responseData = jsonDecode(response.body);
      final createdCount =
          responseData['meta']?['count'] ?? responseData['data']?.length ?? 0;
      final failedCount = responseData['meta']?['failed'] ?? 0;
      print(
        'DEBUG: Bulk create complete - ${createdCount} created, ${failedCount} failed',
      );

      if (createdCount == 0 && failedCount > 0) {
        print('DEBUG: WARNING - All items failed to create!');
        _error = 'All order items failed to create. Check backend logs.';
        notifyListeners();
        return _currentOrder;
      }

      print('DEBUG: Fetching updated order...');
      await getOrder(token, orderId);
      print(
        'DEBUG: Order fetched after item creation - items count: ${_currentOrder?.items.length ?? 0}',
      );
      return _currentOrder;
    } catch (e) {
      _error = 'Error creating order items: $e';
      print('DEBUG: Error creating order items: $e');
      notifyListeners();
      return _currentOrder;
    }
  }
}
