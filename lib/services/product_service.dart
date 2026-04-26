import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/app_constants.dart';
import '../models/product.dart';

class BulkImportResult {
  final bool dryRun;
  final int created;
  final int skipped;
  final int total;
  final int rowsRequestingImage;
  final int imagesAttached;
  final bool zipProvided;
  final List<({int row, String error})> errors;
  final List<String> unusedZipFiles;

  const BulkImportResult({
    required this.dryRun,
    required this.created,
    required this.skipped,
    required this.total,
    required this.rowsRequestingImage,
    required this.imagesAttached,
    required this.zipProvided,
    required this.errors,
    required this.unusedZipFiles,
  });
}

class ProductService {
  static String get _apiUrl => AppConstants.apiUrl;
  static String get _baseUrl => AppConstants.baseUrl;

  /// Bulk-create products from an .xlsx (and optional companion .zip of
  /// product images). Backend caps at 200 rows per call.
  /// Pass [dryRun] = true to validate without persisting.
  static Future<BulkImportResult> bulkImport({
    required String token,
    required Uint8List xlsxBytes,
    required String xlsxFilename,
    Uint8List? zipBytes,
    String? zipFilename,
    bool dryRun = false,
  }) async {
    final uri = Uri.parse('$_apiUrl/products/bulk-import');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['dry_run'] = dryRun.toString();
    request.files.add(
      http.MultipartFile.fromBytes(
        'xlsx',
        xlsxBytes,
        filename: xlsxFilename,
        contentType: MediaType(
          'application',
          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ),
    );
    if (zipBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'zip',
          zipBytes,
          filename: zipFilename ?? 'images.zip',
          contentType: MediaType('application', 'zip'),
        ),
      );
    }

    final streamed = await request.send().timeout(const Duration(minutes: 10));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      String message = 'Bulk import failed: ${response.statusCode}';
      try {
        final parsed = jsonDecode(response.body);
        message = parsed['error']?['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
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
      dryRun: data['dry_run'] as bool? ?? false,
      created: (data['created'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      rowsRequestingImage: (data['rows_requesting_image'] as num?)?.toInt() ?? 0,
      imagesAttached: (data['images_attached'] as num?)?.toInt() ?? 0,
      zipProvided: data['zip_provided'] as bool? ?? false,
      errors: errors,
      unusedZipFiles: (data['unused_zip_files'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
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
