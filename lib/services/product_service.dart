import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/product.dart';

class ProductService {
  static String get _apiUrl => AppConstants.apiUrl;

  /// Get all products with pagination and filters
  static Future<List<Product>> getProducts({
    String? token,
    int page = 1,
    int pageSize = 20,
    String? category,
    String? search,
  }) async {
    try {
      String url = '$_apiUrl/products?pagination[page]=$page&pagination[pageSize]=$pageSize&populate=*';

      if (category != null && category.isNotEmpty) {
        url += '&filters[category][\$eq]=$category';
      }

      if (search != null && search.isNotEmpty) {
        url += '&filters[name][\$containsi]=$search';
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
        throw Exception('Failed to load products: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? [];

      return data.map((item) => Product.fromStrapi(item)).toList();
    } catch (e) {
      throw Exception('Error loading products: $e');
    }
  }

  /// Get single product by ID
  static Future<Product> getProduct(String productId, {String? token}) async {
    try {
      final url = '$_apiUrl/products/$productId?populate=*';

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load product: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      return Product.fromStrapi(body['data']);
    } catch (e) {
      throw Exception('Error loading product: $e');
    }
  }

  /// Create new product (admin only)
  static Future<Product> createProduct(
    Map<String, dynamic> data, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/products';

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
        final body = jsonDecode(response.body);
        throw Exception(body['error']['message'] ?? 'Validation error');
      }

      if (response.statusCode != 201) {
        throw Exception('Failed to create product: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      return Product.fromStrapi(body['data']);
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  /// Update product (admin only)
  static Future<Product> updateProduct(
    String productId,
    Map<String, dynamic> data, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/products/$productId';

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
        final body = jsonDecode(response.body);
        throw Exception(body['error']['message'] ?? 'Validation error');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to update product: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      return Product.fromStrapi(body['data']);
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  /// Delete product (admin only)
  static Future<void> deleteProduct(
    String productId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/products/$productId';

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

      if (response.statusCode != 200) {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  /// Get product categories
  static Future<List<String>> getCategories({String? token}) async {
    try {
      final url = '$_apiUrl/products?pagination[limit]=1000&fields=category';

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? [];

      final categories = <String>{};
      for (final item in data) {
        final attrs = item['attributes'] as Map<String, dynamic>?;
        final category = attrs?['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      return [];
    }
  }
}
