import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/recipe.dart';

class StrapiService {
  static String get _baseUrl {
    if (kIsWeb) return AppConstants.strapiApiUrl;
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:1337/api';
    }
    return AppConstants.strapiApiUrl;
  }

  static String get _strapiHost {
    if (kIsWeb) return AppConstants.baseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:1337';
    return AppConstants.baseUrl;
  }

  static Future<List<Category>> getCategories() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/categories?populate=*'))
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final data = body['data'] as List<dynamic>;
    return data
        .map((item) =>
            Category.fromStrapi(item as Map<String, dynamic>, baseUrl: _strapiHost))
        .toList();
  }

  static Future<List<Product>> getProducts() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/products?populate=*'))
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final data = body['data'] as List<dynamic>;
    return data
        .map((item) =>
            Product.fromStrapi(item as Map<String, dynamic>, baseUrl: _strapiHost))
        .toList();
  }

  static Future<List<Recipe>> getRecipes() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/recipes?populate=*'))
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final data = body['data'] as List<dynamic>;
    return data
        .map((item) =>
            Recipe.fromStrapi(item as Map<String, dynamic>, baseUrl: _strapiHost))
        .toList();
  }
}
