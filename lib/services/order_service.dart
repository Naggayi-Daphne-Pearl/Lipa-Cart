import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order.dart';
import '../models/rating.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart' as user_models;
import '../core/constants/app_constants.dart';
import 'session_service.dart';

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

  /// Check if an HTTP response indicates an auth error (401/403) on a
  /// non-auth endpoint.
  bool _isAuthError(http.Response response) {
    return (response.statusCode == 401 || response.statusCode == 403) &&
        !(response.request?.url.path.contains('/auth/') ?? false);
  }

  Future<void> clearAll() async {
    _orders = [];
    _currentOrder = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  OrderStatus _mapStatus(String? status) {
    switch (status) {
      case 'payment_processing':
        return OrderStatus.paymentProcessing;
      case 'payment_confirmed':
        return OrderStatus.confirmed;
      case 'shopper_assigned':
        return OrderStatus.shopperAssigned;
      case 'ready_for_pickup':
        return OrderStatus.readyForDelivery;
      case 'rider_assigned':
        return OrderStatus.riderAssigned;
      case 'in_transit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      case 'shopping':
        return OrderStatus.shopping;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  List<CartItem> _parseOrderItems(Map<String, dynamic> attributes) {
    // Handle both wrapped and flat formats
    // Try multiple field names: order_items, toc_items, items
    final orderItemsRaw =
        attributes['order_items'] ??
        attributes['toc_items'] ??
        attributes['items'];

    if (orderItemsRaw == null) {
      return [];
    }

    List<dynamic> orderItems = [];
    if (orderItemsRaw is List<dynamic>) {
      // Flat format: direct array
      orderItems = orderItemsRaw;
    } else if (orderItemsRaw is Map<String, dynamic> &&
        orderItemsRaw.containsKey('data')) {
      // Wrapped format: {data: [...]}
      orderItems = (orderItemsRaw['data'] as List<dynamic>?) ?? [];
    }

    final parsedItems = orderItems.map((item) {
      final itemAttrs = (item['attributes'] as Map<String, dynamic>?) ?? item;
      final productName = itemAttrs['product_name'] as String? ?? 'Item';
      final quantity = (itemAttrs['quantity'] as num?)?.toDouble() ?? 1;
      final unit = itemAttrs['unit'] as String? ?? 'unit';
      final estimatedPrice =
          (itemAttrs['estimated_price'] as num?)?.toDouble() ?? 0;

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

      // Parse substitution photo URL from Strapi media field
      String? substitutePhotoUrl;
      final photoField = itemAttrs['substitution_photo'];
      if (photoField is Map<String, dynamic>) {
        final url = photoField['url'] as String?;
        if (url != null && url.isNotEmpty) {
          substitutePhotoUrl = url.startsWith('http') ? url : '${AppConstants.baseUrl}$url';
        }
      }

      final shopperNotes = itemAttrs['shopper_notes'] as String?;
      // Structured fields take priority over legacy notes parsing
      final structuredName = itemAttrs['substitute_name'] as String?;
      final structuredPrice = (itemAttrs['substitute_price'] as num?)?.toDouble();

      return CartItem(
        id: (item['documentId'] ?? item['id'] ?? '').toString(),
        product: product,
        quantity: quantity,
        specialInstructions: itemAttrs['special_instructions'] as String?,
        found: itemAttrs['found'] as bool?,
        actualPrice: (itemAttrs['actual_price'] as num?)?.toDouble(),
        shopperNotes: shopperNotes,
        substitutionApproved: itemAttrs['substitution_approved'] as bool?,
        isSubstituted: itemAttrs['is_substituted'] as bool?,
        substituteName: structuredName ?? CartItem.parseSubstituteNameFromNotes(shopperNotes),
        substitutePrice: structuredPrice ?? CartItem.parseSubstitutePriceFromNotes(shopperNotes),
        substitutePhotoUrl: substitutePhotoUrl,
        substituteForItemId: (itemAttrs['substitute_for_item']?['documentId'] ?? itemAttrs['substitute_for_item']?['id'])?.toString(),
      );
    }).toList();

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

    if (addressData == null) {
      return user_models.Address(
        id: '0',
        label: 'Delivery Address',
        fullAddress: 'No address provided',
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
    try {
      final attributes = (data['attributes'] as Map<String, dynamic>?) ?? data;

      final rawId = data['documentId'] ?? data['id'];
      final documentId = data['documentId'] as String?;

      final orderNumber =
          (attributes['order_number'] ?? attributes['orderNumber'])
              ?.toString() ??
          (data['id']?.toString() ?? 'UNKNOWN');

      final items = _parseOrderItems(attributes);

      final deliveryAddress = _parseDeliveryAddress(attributes);

      // Parse customer data if available
      user_models.User? customer;
      final customerData = attributes['customer'];
      if (customerData != null) {
        try {
          Map<String, dynamic> customerMap;
          if (customerData is Map<String, dynamic>) {
            // Check if it's wrapped in {data: {...}}
            if (customerData.containsKey('data') &&
                customerData['data'] is Map<String, dynamic>) {
              customerMap = customerData['data'];
              final attrs = customerMap['attributes'] as Map<String, dynamic>?;
              if (attrs != null) {
                customerMap = {...customerMap, ...attrs};
              }
            } else {
              // Flat format - check if it has attributes
              final attrs = customerData['attributes'] as Map<String, dynamic>?;
              if (attrs != null) {
                customerMap = {...customerData, ...attrs};
              } else {
                customerMap = customerData;
              }
            }
            customer = user_models.User.fromJson(customerMap);
          }
        } catch (_) {
          // ignored
        }
      }

      // Parse shopper info
      final shopperData = attributes['shopper'];
      String? shopperName;
      String? shopperPhone;
      if (shopperData is Map<String, dynamic>) {
        final sAttrs =
            shopperData['attributes'] as Map<String, dynamic>? ?? shopperData;
        shopperName = sAttrs['name'] as String?;
        shopperPhone = sAttrs['phone'] as String?;
      }

      // Parse rider info
      final riderData = attributes['rider'];
      String? riderName;
      String? riderPhone;
      double? riderLatitude;
      double? riderLongitude;
      if (riderData is Map<String, dynamic>) {
        final rAttrs =
            riderData['attributes'] as Map<String, dynamic>? ?? riderData;
        riderName = rAttrs['name'] as String?;
        riderPhone = rAttrs['phone'] as String?;

        final riderProfileData =
            (rAttrs['rider']?['data'] as Map<String, dynamic>?) ??
            (rAttrs['rider'] as Map<String, dynamic>?);
        if (riderProfileData != null) {
          final riderProfileAttrs =
              riderProfileData['attributes'] as Map<String, dynamic>? ??
              riderProfileData;

          double? parseCoordinate(dynamic value) {
            if (value is num) return value.toDouble();
            if (value is String) return double.tryParse(value);
            return null;
          }

          riderLatitude = parseCoordinate(riderProfileAttrs['current_gps_lat']);
          riderLongitude = parseCoordinate(
            riderProfileAttrs['current_gps_lng'],
          );
        }
      }

      return Order(
        id: rawId?.toString() ?? '',
        documentId: documentId,
        orderNumber: orderNumber,
        items: items,
        deliveryAddress: deliveryAddress,
        subtotal: (attributes['subtotal'] as num?)?.toDouble() ?? 0,
        serviceFee: (attributes['service_fee'] as num?)?.toDouble() ?? 0,
        deliveryFee: (attributes['delivery_fee'] as num?)?.toDouble() ?? 0,
        total: (attributes['total'] as num?)?.toDouble() ?? 0,
        status: _mapStatus(attributes['status'] as String?),
        customerId: (attributes['customer_id'] ?? customer?.id) as String?,
        customer: customer,
        shopperName: shopperName,
        shopperPhone: shopperPhone,
        riderName: riderName,
        riderPhone: riderPhone,
        riderLatitude: riderLatitude,
        riderLongitude: riderLongitude,
        createdAt:
            DateTime.tryParse(attributes['createdAt'] as String? ?? '') ??
            DateTime.now(),
        estimatedDelivery: DateTime.tryParse(
          attributes['estimated_delivery'] as String? ?? '',
        ),
        deliveredAt: DateTime.tryParse(
          attributes['delivered_at'] as String? ?? '',
        ),
        paymentConfirmedAt: DateTime.tryParse(
          attributes['payment_confirmed_at'] as String? ?? '',
        ),
        shopperAssignedAt: DateTime.tryParse(
          attributes['shopper_assigned_at'] as String? ?? '',
        ),
        shoppingStartedAt: DateTime.tryParse(
          attributes['shopping_started_at'] as String? ?? '',
        ),
        shoppingCompletedAt: DateTime.tryParse(
          attributes['shopping_completed_at'] as String? ?? '',
        ),
        riderAssignedAt: DateTime.tryParse(
          attributes['rider_assigned_at'] as String? ?? '',
        ),
        pickedUpAt: DateTime.tryParse(
          attributes['picked_up_at'] as String? ?? '',
        ),
        cancelledAt: DateTime.tryParse(
          attributes['cancelled_at'] as String? ?? '',
        ),
        cancellationReason: attributes['cancellation_reason'] as String?,
        paymentMethod: PaymentMethod.mobileMoney,
        isPaid: false,
        deliveryProofUrl: attributes['delivery_proof_url'] as String?,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all orders for current customer
  Future<bool> fetchOrders(String token, String customerIdentifier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isNumericId = int.tryParse(customerIdentifier) != null;

      // Strapi v5 syntax: populate order_items and delivery_address
      final filters = isNumericId
        ? 'filters[customer][id][\$eq]=$customerIdentifier'
        : 'filters[customer][documentId][\$eq]=$customerIdentifier';
      final url =
        '$baseUrl/api/orders?$filters&populate[0]=order_items&populate[1]=delivery_address&populate[2]=customer&populate[3]=shopper&populate[4]=rider&sort[0]=createdAt:desc';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Session expired — redirect to login
      if (_isAuthError(response)) {
        SessionService.handleSessionExpiry();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _orders = List<Order>.from(
          (data['data'] as List).map((order) {
            return _fromStrapi(order);
          }),
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Failed to fetch orders (${response.statusCode})';
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

  /// Fetch ALL orders for admin dashboard (no customer filter)
  Future<bool> fetchAllOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all orders without customer filter - populate specific relations
      final url =
          '$baseUrl/api/orders?populate[0]=order_items&populate[1]=customer&populate[2]=delivery_address&sort[0]=createdAt:desc';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Session expired — redirect to login
      if (_isAuthError(response)) {
        SessionService.handleSessionExpiry();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _orders = List<Order>.from(
          (data['data'] as List).map((item) {
            return _fromStrapi(item);
          }),
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Failed to fetch orders (${response.statusCode})';
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
  Future<bool> getOrder(String token, String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/orders/$orderId?populate[0]=order_items&populate[1]=delivery_address&populate[2]=customer&populate[3]=shopper&populate[4]=rider',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentOrder = _fromStrapi(data['data']);

        final orderKey = _currentOrder!.documentId ?? _currentOrder!.id;
        final existingIndex = _orders.indexWhere(
          (o) => (o.documentId ?? o.id) == orderKey,
        );
        if (existingIndex >= 0) {
          _orders[existingIndex] = _currentOrder!;
        } else {
          _orders.insert(0, _currentOrder!);
        }

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

  Future<bool> respondToSubstitution(
    String token,
    String orderItemId,
    bool approved, {
    String? rejectionReason,
  }) async {
    try {
      final body = <String, dynamic>{'approved': approved};
      if (!approved && rejectionReason != null && rejectionReason.isNotEmpty) {
        body['rejection_reason'] = rejectionReason;
      }

      final response = await http.patch(
        Uri.parse(
          '$baseUrl/api/order-items/$orderItemId/substitution-response',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error responding to substitution: $e';
      notifyListeners();
      return false;
    }
  }

  /// Shopper suggests a structured substitute for an unavailable item.
  Future<bool> suggestSubstitute(
    String token,
    String orderItemId, {
    required String name,
    required double price,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/order-items/$orderItemId/suggest-substitute',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'substitute_name': name,
          'substitute_price': price,
        }),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      }
      _error = 'Failed to suggest substitute';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error suggesting substitute: $e';
      notifyListeners();
      return false;
    }
  }

  // --- Admin actions ---

  /// Admin confirms payment for a pending order.
  Future<bool> adminConfirmPayment(String token, String orderId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/confirm-payment'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) { notifyListeners(); return true; }
      _error = 'Failed to confirm payment';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error confirming payment: $e';
      notifyListeners();
      return false;
    }
  }

  /// Admin cancels an order from any status.
  Future<bool> adminCancelOrder(String token, String orderId, String reason) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/admin-cancel'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'cancellation_reason': reason}),
      );
      if (response.statusCode == 200) { notifyListeners(); return true; }
      _error = 'Failed to cancel order';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error cancelling order: $e';
      notifyListeners();
      return false;
    }
  }

  /// Admin removes current shopper, resets order to payment_confirmed.
  Future<bool> adminReassignShopper(String token, String orderId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/reassign-shopper'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) { notifyListeners(); return true; }
      _error = 'Failed to reassign shopper';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error reassigning shopper: $e';
      notifyListeners();
      return false;
    }
  }

  /// Admin removes current rider, resets order to ready_for_pickup.
  Future<bool> adminReassignRider(String token, String orderId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/reassign-rider'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) { notifyListeners(); return true; }
      _error = 'Failed to reassign rider';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error reassigning rider: $e';
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
    String? paymentMethod,
  }) async {
    try {
      final orderNumber =
          'LC${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      // TODO: Once payment integration is set up, use this logic instead:
      // final status = paymentMethod == 'cashOnDelivery' ? 'payment_confirmed' : 'pending';
      // For now, all orders default to payment_confirmed so shoppers can see them
      final status = 'payment_confirmed';

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
            'status': status,
            'payment_method': paymentMethod,
            'special_instructions': specialInstructions,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _currentOrder = _fromStrapi(data['data']);
        _orders.insert(0, _currentOrder!);
        notifyListeners();
        return true;
      }

      _error = 'Failed to create order (${response.statusCode})';
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
  Future<bool> cancelOrder(
    String token,
    String orderId, {
    String? reason,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/customer-cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (reason != null && reason.isNotEmpty)
            'cancellation_reason': reason,
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
      if (response.body.isNotEmpty) {
        try {
          final payload = jsonDecode(response.body) as Map<String, dynamic>;
          final err = payload['error'] as Map<String, dynamic>?;
          final msg = err?['message'] as String?;
          if (msg != null && msg.isNotEmpty) {
            _error = msg;
            notifyListeners();
            return false;
          }
        } catch (_) {
          // ignored
        }
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
    int? overallRating,
    int? shopperRating,
    int? riderRating,
    String? comment,
    String? customerId,
    // Legacy support
    double? stars,
  }) async {
    try {
      final ratingData = <String, dynamic>{
        'order': orderId,
        'overall_rating': overallRating ?? stars?.toInt() ?? 5,
        if (shopperRating != null) 'shopper_rating': shopperRating,
        if (riderRating != null) 'rider_rating': riderRating,
        if (comment != null) 'comment': comment,
        if (customerId != null) 'customer': customerId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'data': ratingData}),
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
    String? paymentMethod,
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
      paymentMethod: paymentMethod,
    );

    if (!orderCreated || _currentOrder == null) return null;

    final orderId = _currentOrder!.id;
    final orderDocumentId =
        _currentOrder!.documentId ??
        orderId; // Use documentId for Strapi v5 relations

    try {
      // Prepare all items for bulk creation
      final itemsData = items.asMap().entries.map((entry) {
        final item = entry.value;
        final productId = item.product.id;

        return {
          'order': orderDocumentId, // Use documentId for Strapi v5 relations
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

      // Single bulk request to create all items
      final response = await http.post(
        Uri.parse('$baseUrl/api/order-items/bulk'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'items': itemsData}),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
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

      if (createdCount == 0 && failedCount > 0) {
        _error = 'All order items failed to create. Check backend logs.';
        notifyListeners();
        return _currentOrder;
      }

      await getOrder(token, orderId);
      return _currentOrder;
    } catch (e) {
      _error = 'Error creating order items: $e';
      notifyListeners();
      return _currentOrder;
    }
  }
}
