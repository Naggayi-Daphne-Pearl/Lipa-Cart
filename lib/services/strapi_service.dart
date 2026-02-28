import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/recipe.dart';
import '../models/shopping_list.dart';

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
}
