import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/recipe.dart';
import '../models/shopping_list.dart';
import '../models/order.dart';

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
        return data['data']['attributes'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('ERROR: getShopperProfile - $e');
      return null;
    }
  }

  /// Get available orders (status = payment_confirmed)
  static Future<List<Order>> getAvailableOrdersForShopper(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[status][\$eq]=payment_confirmed&populate[order_items][populate][0]=product',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list =
            (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        return list.map((o) => Order.fromJson(o['attributes'])).toList();
      }
      return [];
    } catch (e) {
      print('ERROR: getAvailableOrdersForShopper - $e');
      return [];
    }
  }

  /// Get active orders for shopper (shopper_assigned OR shopping status)
  static Future<List<Order>> getActiveOrdersForShopper(
    String token,
    String shopperId,
  ) async {
    try {
      // Strapi v5 syntax: filter by relation ID directly
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[\$or][0][status][\$eq]=shopper_assigned&filters[\$or][1][status][\$eq]=shopping&filters[shopper][\$eq]=$shopperId&populate[order_items][populate][0]=product',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list =
            (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        return list.map((o) => Order.fromJson(o['attributes'])).toList();
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
    String shopperId,
  ) async {
    try {
      // Strapi v5 syntax: filter by relation ID directly
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[\$or][0][status][\$eq]=delivered&filters[\$or][1][status][\$eq]=cancelled&filters[shopper][\$eq]=$shopperId&populate[order_items][populate][0]=product',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list =
            (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        return list.map((o) => Order.fromJson(o['attributes'])).toList();
      }
      return [];
    } catch (e) {
      print('ERROR: getCompletedOrdersForShopper - $e');
      return [];
    }
  }

  /// Assign order to shopper
  static Future<bool> assignOrderToShopper(
    String orderId,
    String shopperId,
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
              'data': {'shopper': shopperId, 'status': 'shopper_assigned'},
            }),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('ERROR: assignOrderToShopper - $e');
      return false;
    }
  }

  /// Toggle shopper online/offline status
  static Future<bool> updateShopperStatus(
    String shopperId,
    bool isOnline,
    String token,
  ) async {
    try {
      final response = await http
          .patch(
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
    required String shopperId,
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
}
