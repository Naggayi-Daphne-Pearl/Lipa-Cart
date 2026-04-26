import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/product.dart';

class BulkImportResult {
  final int created;
  final int skipped;
  final int total;
  final List<({int row, String error})> errors;

  const BulkImportResult({
    required this.created,
    required this.skipped,
    required this.total,
    required this.errors,
  });
}

class ProductService {
  static String get _apiUrl => AppConstants.apiUrl;
  static String get _baseUrl => AppConstants.baseUrl;

  /// Fetch the canonical CSV template as raw text (admins paste this into a
  /// spreadsheet, fill it in, and paste the result back into bulkImport).
  static Future<String> fetchCsvTemplate({String? token}) async {
    final url = '$_apiUrl/products/csv-template';
    final response = await http
        .get(Uri.parse(url), headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        })
        .timeout(AppConstants.apiTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch template: ${response.statusCode}');
    }
    return response.body;
  }

  /// Bulk-create products from a CSV blob. Backend caps at 200 rows per call.
  /// Pass [dryRun] = true to validate without persisting.
  static Future<BulkImportResult> bulkImport(
    String csv, {
    required String token,
    bool dryRun = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_apiUrl/products/bulk-import'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'csv': csv, 'dry_run': dryRun}),
        )
        .timeout(const Duration(minutes: 5));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(
        body['error']?['message'] ?? 'Bulk import failed: ${response.statusCode}',
      );
    }

    final outer = jsonDecode(response.body) as Map<String, dynamic>;
    final data = outer['data'] as Map<String, dynamic>;
    final errors = (data['errors'] as List<dynamic>? ?? const [])
        .map((e) => (
              row: (e['row'] as num).toInt(),
              error: (e['error'] ?? '').toString(),
            ))
        .toList();
    return BulkImportResult(
      created: (data['created'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      errors: errors,
    );
  }

  /// Admin-only list of {id, name} category options. Used by the bulk-import
  /// dialog to surface the documentIds that admins must paste into category_id.
  static Future<List<({String id, String name})>> fetchCategoryOptions({
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$_apiUrl/products/category-options'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(AppConstants.apiTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load category options: ${response.statusCode}');
    }
    final outer = jsonDecode(response.body) as Map<String, dynamic>;
    final list = outer['data'] as List<dynamic>;
    return list
        .map((e) => (
              id: (e['id'] ?? '').toString(),
              name: (e['name'] ?? '').toString(),
            ))
        .toList();
  }

  // Scoped populate for list queries — the admin/customer list view only needs
  // the image url + category name. populate=* on a 1k-row catalog was the
  // dominant cost in the 2.3s GET response.
  static const _listPopulate =
      'populate[image][fields][0]=url'
      '&populate[image][fields][1]=formats'
      '&populate[category][fields][0]=name'
      '&populate[category][fields][1]=slug';

  /// Get all products with pagination and filters
  static Future<List<Product>> getProducts({
    String? token,
    int page = 1,
    int pageSize = 20,
    String? category,
    String? search,
  }) async {
    try {
      String url =
          '$_apiUrl/products?pagination[page]=$page&pagination[pageSize]=$pageSize&$_listPopulate';

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

        return data
          .map((item) => Product.fromStrapi(item, baseUrl: _baseUrl))
          .toList();
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
      return Product.fromStrapi(body['data'], baseUrl: _baseUrl);
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
      return Product.fromStrapi(body['data'], baseUrl: _baseUrl);
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
      return Product.fromStrapi(body['data'], baseUrl: _baseUrl);
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

      if (response.statusCode != 200 && response.statusCode != 204) {
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
