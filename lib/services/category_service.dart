import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/category.dart';

class CategoryService {
  static String get _apiUrl => AppConstants.apiUrl;
  static String get _baseUrl => AppConstants.baseUrl;

  static Future<List<Category>> getCategories({
    String? token,
    String? search,
  }) async {
    String url =
        '$_apiUrl/categories?pagination[pageSize]=200&populate=image&populate=products&sort=sort_order:asc';
    if (search != null && search.isNotEmpty) {
      url += '&filters[name][\$containsi]=${Uri.encodeQueryComponent(search)}';
    }

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = (body['data'] as List<dynamic>?) ?? [];
    return data
        .map((item) =>
            Category.fromStrapi(item as Map<String, dynamic>, baseUrl: _baseUrl))
        .toList();
  }

  static Future<Category> createCategory(
    Map<String, dynamic> data, {
    required String token,
  }) async {
    final url = '$_apiUrl/categories';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http
        .post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({'data': data}),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized - Admin access required');
    }
    if (response.statusCode == 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = (body['error'] as Map<String, dynamic>?)?['message'];
      throw Exception(message ?? 'Validation error');
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create category: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Category.fromStrapi(
      body['data'] as Map<String, dynamic>,
      baseUrl: _baseUrl,
    );
  }

  static Future<Category> updateCategory(
    String id,
    Map<String, dynamic> data, {
    required String token,
  }) async {
    final url = '$_apiUrl/categories/$id';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http
        .put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({'data': data}),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized - Admin access required');
    }
    if (response.statusCode == 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = (body['error'] as Map<String, dynamic>?)?['message'];
      throw Exception(message ?? 'Validation error');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to update category: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Category.fromStrapi(
      body['data'] as Map<String, dynamic>,
      baseUrl: _baseUrl,
    );
  }

  static Future<void> deleteCategory(
    String id, {
    required String token,
  }) async {
    final url = '$_apiUrl/categories/$id';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http
        .delete(Uri.parse(url), headers: headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized - Admin access required');
    }
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete category: ${response.statusCode}');
    }
  }
}
