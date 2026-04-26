import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/app_constants.dart';
import '../models/category.dart';
import 'product_service.dart' show BulkImportResult;

class CategoryService {
  static String get _apiUrl => AppConstants.apiUrl;
  static String get _baseUrl => AppConstants.baseUrl;

  /// Bulk-create categories from an .xlsx (and optional zip of images).
  /// Mirrors ProductService.bulkImport so the same dialog can drive both.
  static Future<BulkImportResult> bulkImport({
    required String token,
    required Uint8List xlsxBytes,
    required String xlsxFilename,
    Uint8List? zipBytes,
    String? zipFilename,
    bool dryRun = false,
  }) async {
    final uri = Uri.parse('$_apiUrl/categories/bulk-import');
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
