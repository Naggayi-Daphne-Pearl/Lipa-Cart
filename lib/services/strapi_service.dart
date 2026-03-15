import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/recipe.dart';
import '../models/shopping_list.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/user.dart' show Address;

class StrapiService {
  static String get _apiUrl => AppConstants.apiUrl;
  static String get _baseUrl => AppConstants.baseUrl;

  static Future<List<Category>> getCategories() async {
    final response = await http
        .get(Uri.parse('$_apiUrl/categories?populate=*'))
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final data = body['data'] as List<dynamic>;
    return data
        .map(
          (item) => Category.fromStrapi(
            item as Map<String, dynamic>,
            baseUrl: _baseUrl,
          ),
        )
        .toList();
  }

  static Future<List<Product>> getProducts() async {
    final response = await http
        .get(Uri.parse('$_apiUrl/products?populate=*&pagination[pageSize]=100'))
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final data = body['data'] as List<dynamic>;
    return data
        .map(
          (item) => Product.fromStrapi(
            item as Map<String, dynamic>,
            baseUrl: _baseUrl,
          ),
        )
        .toList();
  }

  static Future<List<ShoppingList>> getShoppingLists({
    String? authToken,
  }) async {
    // Simplified populate query - use wildcard instead of complex nested fields
    // Note: /me endpoint not needed since find() is already filtered by authenticated user
    final url = '$_apiUrl/shopping-lists?populate=*&publicationState=preview';

    print('DEBUG StrapiService.getShoppingLists - URL: $url');

    final headers = <String, String>{
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final response = await http
        .get(Uri.parse(url), headers: headers.isNotEmpty ? headers : null)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load shopping lists: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final data = body['data'] as List<dynamic>;
    return data
        .map((item) => ShoppingList.fromStrapi(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ShoppingList> createShoppingList({
    required String name,
    String? description,
    String emoji = '🛒',
    String color = '#15874B',
    required String authToken,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_apiUrl/shopping-lists'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: json.encode({
            'data': {
              'name': name,
              'description': description,
              'emoji': emoji,
              'color': color,
              'publishedAt': DateTime.now().toIso8601String(),
            },
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to create shopping list: ${response.statusCode} ${response.body}',
      );
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response while creating shopping list');
    }

    return ShoppingList.fromStrapi(data);
  }

  static Future<ShoppingList> updateShoppingList({
    required String listId,
    required String name,
    String? description,
    String emoji = '🛒',
    String color = '#15874B',
    List<ShoppingListItem>? items,
    required String authToken,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'description': description,
      'emoji': emoji,
      'color': color,
      'publishedAt': DateTime.now().toIso8601String(),
    };

    if (items != null) {
      payload['items'] = items.map(_shoppingListItemToStrapiData).toList();
    }

    final response = await http
        .put(
          Uri.parse('$_apiUrl/shopping-lists/$listId?populate=*'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: json.encode({'data': payload}),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update shopping list: ${response.statusCode} ${response.body}',
      );
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response while updating shopping list');
    }

    return ShoppingList.fromStrapi(data);
  }

  static Map<String, dynamic> _shoppingListItemToStrapiData(
    ShoppingListItem item,
  ) {
    final mapped = <String, dynamic>{
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'unit_price': item.unitPrice,
      'budget_amount': item.budgetAmount,
      'notes': item.description,
    };

    final productId = item.linkedProduct?.strapiId ?? item.linkedProduct?.id;
    if (productId != null && productId.isNotEmpty) {
      mapped['product'] = productId;
    }

    return mapped;
  }

  static Future<void> deleteShoppingList({
    required String listId,
    required String authToken,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$_apiUrl/shopping-lists/$listId'),
          headers: {'Authorization': 'Bearer $authToken'},
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete shopping list: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<List<Recipe>> getRecipes() async {
    // Simplified populate query - use wildcard instead of complex nested fields
    final url = '$_apiUrl/recipes?populate=*';

    print('DEBUG StrapiService.getRecipes - URL: $url');

    final response = await http
        .get(Uri.parse(url))
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final data = body['data'] as List<dynamic>;
    return data
        .map(
          (item) => Recipe.fromStrapi(
            item as Map<String, dynamic>,
            baseUrl: _baseUrl,
          ),
        )
        .toList();
  }

  // =============== SHOPPER METHODS ===============

  /// Get shopper profile with stats
  static Future<Map<String, dynamic>?> getShopperProfile(
    String shopperId,
    String token,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/shoppers/$shopperId?populate=*'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Strapi v5: fields are directly on data, not nested in attributes
        final shopperData = data['data'];
        if (shopperData is Map<String, dynamic>) {
          return shopperData['attributes'] as Map<String, dynamic>? ?? shopperData;
        }
        return null;
      }
      return null;
    } catch (e) {
      print('ERROR: getShopperProfile - $e');
      return null;
    }
  }

  /// Parse a Strapi v5 order response into an Order model
  /// Handles both flat (v5) and wrapped (v4 attributes) formats
  static Order _parseOrderFromStrapi(Map<String, dynamic> data) {
    final attrs = (data['attributes'] as Map<String, dynamic>?) ?? data;
    final rawId = data['id'] ?? data['documentId'];
    final documentId = data['documentId'] as String?;

    // Parse order items
    final orderItemsRaw = attrs['order_items'];
    List<CartItem> items = [];
    if (orderItemsRaw is List) {
      items = orderItemsRaw.map<CartItem>((item) {
        final itemAttrs = (item is Map<String, dynamic>)
            ? ((item['attributes'] as Map<String, dynamic>?) ?? item)
            : <String, dynamic>{};
        final productName = itemAttrs['product_name'] as String? ?? 'Item';
        final quantity = (itemAttrs['quantity'] as num?)?.toDouble() ?? 1;
        final unit = itemAttrs['unit'] as String? ?? 'unit';
        final estimatedPrice =
            (itemAttrs['estimated_price'] as num?)?.toDouble() ?? 0;

        final productData = itemAttrs['product'];
        final productId = productData is Map
            ? (productData['documentId'] ?? productData['id']).toString()
            : '';

        return CartItem(
          id: (item['documentId'] ?? item['id'] ?? '').toString(),
          product: Product(
            id: productId.isEmpty ? 'unknown' : productId,
            name: productName,
            description: '',
            image: '',
            price: estimatedPrice,
            unit: unit,
            categoryId: '',
            categoryName: '',
            isAvailable: true,
          ),
          quantity: quantity,
          specialInstructions: itemAttrs['special_instructions'] as String?,
          found: itemAttrs['found'] as bool?,
          actualPrice: (itemAttrs['actual_price'] as num?)?.toDouble(),
          shopperNotes: itemAttrs['shopper_notes'] as String?,
        );
      }).toList();
    } else if (orderItemsRaw is Map && orderItemsRaw['data'] is List) {
      // Strapi v4 wrapped format
      items = (orderItemsRaw['data'] as List).map<CartItem>((item) {
        final itemAttrs = (item['attributes'] as Map<String, dynamic>?) ?? item;
        final productName = itemAttrs['product_name'] as String? ?? 'Item';
        final quantity = (itemAttrs['quantity'] as num?)?.toDouble() ?? 1;
        final estimatedPrice =
            (itemAttrs['estimated_price'] as num?)?.toDouble() ?? 0;

        return CartItem(
          id: (item['documentId'] ?? item['id'] ?? '').toString(),
          product: Product(
            id: 'unknown',
            name: productName,
            description: '',
            image: '',
            price: estimatedPrice,
            unit: itemAttrs['unit'] as String? ?? 'unit',
            categoryId: '',
            categoryName: '',
            isAvailable: true,
          ),
          quantity: quantity,
        );
      }).toList();
    }

    // Parse delivery address
    final addressRaw = attrs['delivery_address'];
    Address deliveryAddress;
    if (addressRaw is Map<String, dynamic>) {
      final addrData = (addressRaw.containsKey('data') &&
              addressRaw['data'] is Map<String, dynamic>)
          ? addressRaw['data'] as Map<String, dynamic>
          : addressRaw;
      final addrAttrs =
          (addrData['attributes'] as Map<String, dynamic>?) ?? addrData;
      final addressLine = addrAttrs['address_line'] as String? ?? '';
      final city = addrAttrs['city'] as String? ?? '';
      final landmark = addrAttrs['landmark'] as String?;
      deliveryAddress = Address(
        id: (addrData['id'] ?? addrData['documentId'] ?? '0').toString(),
        label: addrAttrs['label'] as String? ?? 'Delivery Address',
        fullAddress:
            '$addressLine${city.isNotEmpty ? ', $city' : ''}${landmark != null && landmark.isNotEmpty ? ', $landmark' : ''}',
        landmark: landmark,
        latitude: (addrAttrs['gps_lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (addrAttrs['gps_lng'] as num?)?.toDouble() ?? 0.0,
        isDefault: addrAttrs['is_default'] as bool? ?? false,
      );
    } else {
      deliveryAddress = Address(
        id: '0',
        label: 'Delivery Address',
        fullAddress: 'No address provided',
        latitude: 0.0,
        longitude: 0.0,
      );
    }

    // Map Strapi status string to OrderStatus enum
    final statusStr = attrs['status'] as String? ?? 'pending';
    const statusMap = {
      'pending': OrderStatus.pending,
      'payment_processing': OrderStatus.pending,
      'payment_confirmed': OrderStatus.confirmed,
      'shopper_assigned': OrderStatus.confirmed,
      'shopping': OrderStatus.shopping,
      'ready_for_pickup': OrderStatus.readyForDelivery,
      'rider_assigned': OrderStatus.readyForDelivery,
      'in_transit': OrderStatus.inTransit,
      'delivered': OrderStatus.delivered,
      'cancelled': OrderStatus.cancelled,
      'refunded': OrderStatus.cancelled,
    };
    final status = statusMap[statusStr] ?? OrderStatus.pending;

    return Order(
      id: rawId?.toString() ?? '',
      documentId: documentId,
      orderNumber: (attrs['order_number'] ?? '').toString(),
      items: items,
      deliveryAddress: deliveryAddress,
      subtotal: (attrs['subtotal'] as num?)?.toDouble() ?? 0,
      serviceFee: (attrs['service_fee'] as num?)?.toDouble() ?? 0,
      deliveryFee: (attrs['delivery_fee'] as num?)?.toDouble() ?? 0,
      total: (attrs['total'] as num?)?.toDouble() ?? 0,
      status: status,
      createdAt:
          DateTime.tryParse(attrs['createdAt'] as String? ?? '') ??
          DateTime.now(),
      estimatedDelivery: DateTime.tryParse(
        attrs['estimated_delivery'] as String? ?? '',
      ),
      deliveredAt: DateTime.tryParse(
        attrs['delivered_at'] as String? ?? '',
      ),
      cancellationReason: attrs['cancellation_reason'] as String?,
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.name == (attrs['payment_method'] as String? ?? ''),
        orElse: () => PaymentMethod.mobileMoney,
      ),
      isPaid: attrs['is_paid'] as bool? ?? false,
    );
  }

  /// Get available orders (status = payment_confirmed)
  static Future<List<Order>> getAvailableOrdersForShopper(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[status][\$eq]=payment_confirmed',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      print('DEBUG: getAvailableOrdersForShopper - status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list =
            (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        print('DEBUG: getAvailableOrdersForShopper - found ${list.length} orders');
        return list.map((o) => _parseOrderFromStrapi(o)).toList();
      }
      print('DEBUG: getAvailableOrdersForShopper - response: ${response.body}');
      return [];
    } catch (e) {
      print('ERROR: getAvailableOrdersForShopper - $e');
      return [];
    }
  }

  /// Get active orders for shopper (shopper_assigned, shopping, or ready_for_pickup)
  static Future<List<Order>> getActiveOrdersForShopper(
    String token,
    String userDocumentId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[\$or][0][status][\$eq]=shopper_assigned&filters[\$or][1][status][\$eq]=shopping&filters[\$or][2][status][\$eq]=ready_for_pickup&filters[shopper][documentId][\$eq]=$userDocumentId',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list =
            (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        return list.map((o) => _parseOrderFromStrapi(o)).toList();
      }
      return [];
    } catch (e) {
      print('ERROR: getActiveOrdersForShopper - $e');
      return [];
    }
  }

  /// Get completed orders for shopper (delivered OR cancelled)
  static Future<List<Order>> getCompletedOrdersForShopper(
    String token,
    String userDocumentId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[\$or][0][status][\$eq]=delivered&filters[\$or][1][status][\$eq]=cancelled&filters[shopper][documentId][\$eq]=$userDocumentId',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list =
            (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        return list.map((o) => _parseOrderFromStrapi(o)).toList();
      }
      return [];
    } catch (e) {
      print('ERROR: getCompletedOrdersForShopper - $e');
      return [];
    }
  }

  /// Shopper claims an available order
  static Future<Map<String, dynamic>?> claimOrder(
    String orderDocumentId,
    String token,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/orders/$orderDocumentId/claim'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
      print('ERROR: claimOrder - ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('ERROR: claimOrder - $e');
      return null;
    }
  }

  /// Shopper unclaims an order (removes assignment)
  static Future<bool> unclaimOrder(String orderDocumentId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/orders/$orderDocumentId/claim'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(AppConstants.apiTimeout);
      return response.statusCode == 200;
    } catch (e) {
      print('ERROR: unclaimOrder - $e');
      return false;
    }
  }

  /// Shopper updates order status (shopping, ready_for_pickup)
  static Future<Map<String, dynamic>?> updateShopperOrderStatus(
    String orderDocumentId,
    String status,
    String token,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_apiUrl/orders/$orderDocumentId/shopper-status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'status': status}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
      print('ERROR: updateShopperOrderStatus - ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('ERROR: updateShopperOrderStatus - $e');
      return null;
    }
  }

  /// Shopper batch-updates order items (mark found, set actual price)
  static Future<bool> batchUpdateOrderItems(
    List<Map<String, dynamic>> items,
    String token,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_apiUrl/order-items/batch-update'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'items': items}),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('ERROR: batchUpdateOrderItems - $e');
      return false;
    }
  }

  /// Legacy: Assign order to shopper (kept for backward compat)
  static Future<bool> assignOrderToShopper(
    String orderId,
    String shopperId,
    String token,
  ) async {
    final result = await claimOrder(orderId, token);
    return result != null;
  }

  /// Toggle shopper online/offline status
  static Future<bool> updateShopperStatus(
    String shopperId,
    bool isOnline,
    String token,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_apiUrl/shoppers/$shopperId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'data': {'is_online': isOnline},
            }),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('ERROR: updateShopperStatus - $e');
      return false;
    }
  }

  /// Update order status
  static Future<bool> updateOrderStatus(
    String orderId,
    String status,
    String token,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_apiUrl/orders/$orderId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'data': {'status': status},
            }),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('ERROR: updateOrderStatus - $e');
      return false;
    }
  }

  /// Submit KYC documents for shopper verification
  static Future<bool> submitShopperKyc({
    required String idNumber,
    required String idPhotoUrl,
    required String facePhotoUrl,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/shoppers/kyc/submit'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'id_number': idNumber,
              'id_photo_url': idPhotoUrl,
              'face_photo_url': facePhotoUrl,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        print('KYC submission successful');
        return true;
      } else {
        print('ERROR: KYC submission failed - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('ERROR: submitShopperKyc - $e');
      return false;
    }
  }

  /// Submit full KYC with payment & contact info
  static Future<bool> submitShopperKycFull({
    required String idNumber,
    required String idPhotoUrl,
    required String facePhotoUrl,
    String? mobileMoneyProvider,
    String? mobileMoneyNumber,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{
        'id_number': idNumber,
        'id_photo_url': idPhotoUrl,
        'face_photo_url': facePhotoUrl,
      };
      if (mobileMoneyProvider != null) {
        body['mobile_money_provider'] = mobileMoneyProvider;
      }
      if (mobileMoneyNumber != null) {
        body['mobile_money_number'] = mobileMoneyNumber;
      }
      if (bankName != null) body['bank_name'] = bankName;
      if (bankAccountName != null) {
        body['bank_account_name'] = bankAccountName;
      }
      if (bankAccountNumber != null) {
        body['bank_account_number'] = bankAccountNumber;
      }
      if (emergencyContactName != null) {
        body['emergency_contact_name'] = emergencyContactName;
      }
      if (emergencyContactPhone != null) {
        body['emergency_contact_phone'] = emergencyContactPhone;
      }

      final response = await http
          .post(
            Uri.parse('$_apiUrl/shoppers/kyc/submit'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        print('Full KYC submission successful');
        return true;
      } else {
        print('ERROR: Full KYC submission failed - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('ERROR: submitShopperKycFull - $e');
      return false;
    }
  }

  // ─── Rider Order Methods ───────────────────────────────────

  /// Get available deliveries (orders ready for pickup, no rider assigned)
  static Future<List<Order>> getAvailableDeliveries(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[status][\$eq]=ready_for_pickup',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list =
            (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        return list.map((o) => _parseOrderFromStrapi(o)).toList();
      }
      print('ERROR: getAvailableDeliveries - ${response.statusCode}: ${response.body}');
      return [];
    } catch (e) {
      print('ERROR: getAvailableDeliveries - $e');
      return [];
    }
  }

  /// Get active deliveries for rider (rider_assigned or in_transit)
  static Future<List<Order>> getActiveDeliveries(
    String token,
    String riderDocumentId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[\$or][0][status][\$eq]=rider_assigned&filters[\$or][1][status][\$eq]=in_transit&filters[rider][documentId][\$eq]=$riderDocumentId',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list =
            (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        return list.map((o) => _parseOrderFromStrapi(o)).toList();
      }
      return [];
    } catch (e) {
      print('ERROR: getActiveDeliveries - $e');
      return [];
    }
  }

  /// Get completed deliveries for rider
  static Future<List<Order>> getCompletedDeliveries(
    String token,
    String riderDocumentId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[\$or][0][status][\$eq]=delivered&filters[\$or][1][status][\$eq]=cancelled&filters[rider][documentId][\$eq]=$riderDocumentId',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list =
            (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        return list.map((o) => _parseOrderFromStrapi(o)).toList();
      }
      return [];
    } catch (e) {
      print('ERROR: getCompletedDeliveries - $e');
      return [];
    }
  }

  /// Rider claims a delivery
  static Future<Map<String, dynamic>?> claimDelivery(
    String orderDocumentId,
    String token,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/orders/$orderDocumentId/claim-delivery'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
      print('ERROR: claimDelivery - ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('ERROR: claimDelivery - $e');
      return null;
    }
  }

  /// Rider updates delivery status (in_transit, delivered)
  static Future<Map<String, dynamic>?> updateRiderOrderStatus(
    String orderDocumentId,
    String status,
    String token,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_apiUrl/orders/$orderDocumentId/rider-status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'status': status}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
      print('ERROR: updateRiderOrderStatus - ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('ERROR: updateRiderOrderStatus - $e');
      return null;
    }
  }

  /// Submit rider KYC with all documents and details
  static Future<bool> submitRiderKycFull({
    required String idNumber,
    required String idPhotoUrl,
    required String facePhotoUrl,
    required String vehicleType,
    required String licenseNumber,
    String? vehicleMake,
    String? vehiclePlate,
    String? licensePhotoUrl,
    String? mobileMoneyProvider,
    String? mobileMoneyNumber,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{
        'id_number': idNumber,
        'id_photo_url': idPhotoUrl,
        'face_photo_url': facePhotoUrl,
        'vehicle_type': vehicleType,
        'license_number': licenseNumber,
      };
      if (vehicleMake != null) body['vehicle_make'] = vehicleMake;
      if (vehiclePlate != null) body['vehicle_plate'] = vehiclePlate;
      if (licensePhotoUrl != null) body['license_photo_url'] = licensePhotoUrl;
      if (mobileMoneyProvider != null) body['mobile_money_provider'] = mobileMoneyProvider;
      if (mobileMoneyNumber != null) body['mobile_money_number'] = mobileMoneyNumber;
      if (bankName != null) body['bank_name'] = bankName;
      if (bankAccountName != null) body['bank_account_name'] = bankAccountName;
      if (bankAccountNumber != null) body['bank_account_number'] = bankAccountNumber;
      if (emergencyContactName != null) body['emergency_contact_name'] = emergencyContactName;
      if (emergencyContactPhone != null) body['emergency_contact_phone'] = emergencyContactPhone;

      final response = await http
          .post(
            Uri.parse('$_apiUrl/riders/kyc/submit'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        print('Rider KYC submission successful');
        return true;
      } else {
        print('ERROR: Rider KYC submission failed - ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR: submitRiderKycFull - $e');
      return false;
    }
  }

  /// Update shopper profile fields
  static Future<bool> updateShopperProfile(
    String shopperId,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_apiUrl/shoppers/$shopperId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'data': data}),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('ERROR: updateShopperProfile - $e');
      return false;
    }
  }

  /// Get rider profile with stats
  static Future<Map<String, dynamic>?> getRiderProfile(
    String riderId,
    String token,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/riders/$riderId?populate=*'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final riderData = data['data'];
        if (riderData is Map<String, dynamic>) {
          return riderData['attributes'] as Map<String, dynamic>? ?? riderData;
        }
        return null;
      }
      return null;
    } catch (e) {
      print('ERROR: getRiderProfile - $e');
      return null;
    }
  }

  /// Update rider profile fields
  static Future<bool> updateRiderProfile(
    String riderId,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_apiUrl/riders/$riderId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'data': data}),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('ERROR: updateRiderProfile - $e');
      return false;
    }
  }

  /// Update user profile (name, email)
  static Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_apiUrl/users/$userId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'data': data}),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('ERROR: updateUserProfile - $e');
      return false;
    }
  }
}
