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
        .map((item) =>
            Category.fromStrapi(item as Map<String, dynamic>, baseUrl: _baseUrl))
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
        .map((item) =>
            Product.fromStrapi(item as Map<String, dynamic>, baseUrl: _baseUrl))
        .toList();
  }

  static Future<List<ShoppingList>> getShoppingLists() async {
    final response = await http
        .get(Uri.parse('$_apiUrl/shopping-lists?populate=*'))
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

  static Future<List<Recipe>> getRecipes() async {
    final response = await http
        .get(Uri.parse('$_apiUrl/recipes?populate=*'))
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final data = body['data'] as List<dynamic>;
    return data
        .map((item) =>
            Recipe.fromStrapi(item as Map<String, dynamic>, baseUrl: _baseUrl))
        .toList();
  }
}
