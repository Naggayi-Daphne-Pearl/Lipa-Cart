import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/app_constants.dart';
import 'product_service.dart' show BulkImportResult;

class RecipeService {
  static String get _apiUrl => AppConstants.apiUrl;

  /// Bulk-create recipes from an .xlsx (and optional .zip of images).
  ///
  /// Notes:
  /// - Each ingredient in ingredients_json must include product_name.
  /// - product_name values must match existing active products.
  /// - Pass dryRun=true to validate without persisting.
  static Future<BulkImportResult> bulkImport({
    required String token,
    required Uint8List xlsxBytes,
    required String xlsxFilename,
    Uint8List? zipBytes,
    String? zipFilename,
    bool dryRun = false,
  }) async {
    final uri = Uri.parse('$_apiUrl/recipes/bulk-import');
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
        .map(
          (e) => (
            row: (e['row'] as num).toInt(),
            error: (e['error'] ?? '').toString(),
          ),
        )
        .toList();

    return BulkImportResult(
      dryRun: data['dry_run'] as bool? ?? false,
      created: (data['created'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      rowsRequestingImage:
          (data['rows_requesting_image'] as num?)?.toInt() ?? 0,
      imagesAttached: (data['images_attached'] as num?)?.toInt() ?? 0,
      zipProvided: data['zip_provided'] as bool? ?? false,
      errors: errors,
      unusedZipFiles: (data['unused_zip_files'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
