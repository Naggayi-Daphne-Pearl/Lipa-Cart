import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/constants/app_constants.dart';

/// Handle returned by upload endpoints that need both the Strapi media id
/// (for relation binding) and the resolved URL (for preview rendering).
class UploadedMedia {
  final int id;
  final String url;
  const UploadedMedia({required this.id, required this.url});
}

/// Uploads images through Strapi's `/api/upload` endpoint. Strapi then
/// delegates to whichever upload provider is configured server-side
/// (currently Cloudinary — see `Lipa-Cart-Backend/config/plugins.ts`).
class UploadService {
  static String get _apiUrl => AppConstants.apiUrl;

  static const int _maxFileSizeMb = 10;
  static const int _maxUploadAttempts = 3;

  static Future<http.StreamedResponse> _defaultSend(
    http.MultipartRequest request,
  ) {
    return request.send();
  }

  static Future<String?> uploadImage(
    File imageFile,
    String token, {
    String? apiUrlOverride,
    Future<http.StreamedResponse> Function(http.MultipartRequest request)?
    sendRequest,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final name = imageFile.uri.pathSegments.isNotEmpty
        ? imageFile.uri.pathSegments.last
        : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImageBytes(
      bytes,
      name,
      token,
      apiUrlOverride: apiUrlOverride,
      sendRequest: sendRequest,
    );
  }

  static Future<String?> uploadImageBytes(
    Uint8List bytes,
    String fileName,
    String token, {
    String? apiUrlOverride,
    Future<http.StreamedResponse> Function(http.MultipartRequest request)?
    sendRequest,
  }) async {
    final result = await _uploadRaw(
      bytes,
      fileName,
      token,
      apiUrlOverride: apiUrlOverride,
      sendRequest: sendRequest,
    );
    return result['url'] as String?;
  }

  /// Uploads and returns `{id, url}` so the caller can attach the media to a
  /// Strapi relation (e.g. `product.image`) via its numeric id.
  static Future<UploadedMedia> uploadImageWithMeta(
    File imageFile,
    String token, {
    String? apiUrlOverride,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final name = imageFile.uri.pathSegments.isNotEmpty
        ? imageFile.uri.pathSegments.last
        : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImageBytesWithMeta(
      bytes,
      name,
      token,
      apiUrlOverride: apiUrlOverride,
    );
  }

  static Future<UploadedMedia> uploadImageBytesWithMeta(
    Uint8List bytes,
    String fileName,
    String token, {
    String? apiUrlOverride,
  }) async {
    final result = await _uploadRaw(
      bytes,
      fileName,
      token,
      apiUrlOverride: apiUrlOverride,
    );
    final id = result['id'];
    final url = result['url'] as String?;
    if (id == null || url == null) {
      throw Exception('Upload response missing id/url: $result');
    }
    return UploadedMedia(id: id as int, url: url);
  }

  static Future<Map<String, dynamic>> _uploadRaw(
    Uint8List bytes,
    String fileName,
    String token, {
    String? apiUrlOverride,
    Future<http.StreamedResponse> Function(http.MultipartRequest request)?
    sendRequest,
  }) async {
    final sizeMb = bytes.length / (1024 * 1024);
    if (sizeMb > _maxFileSizeMb) {
      throw Exception(
        'Image too large: ${sizeMb.toStringAsFixed(1)}MB (max ${_maxFileSizeMb}MB)',
      );
    }

    final baseUrl = apiUrlOverride ?? _apiUrl;
    final sender = sendRequest ?? _defaultSend;
    Exception? lastError;

    for (int attempt = 1; attempt <= _maxUploadAttempts; attempt++) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/upload'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            bytes,
            filename: fileName,
            contentType: _contentTypeFor(fileName),
          ),
        );

        final streamed = await sender(request).timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException('Upload timed out after 60s'),
        );
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final decoded = jsonDecode(response.body);
          if (decoded is! List || decoded.isEmpty) {
            throw Exception(
              'Upload response missing file data: ${response.body}',
            );
          }
          return decoded.first as Map<String, dynamic>;
        }

        final message =
            'Upload failed: HTTP ${response.statusCode} ${response.body}';
        final isRetryable = _isRetryableUploadFailure(
          response.statusCode,
          response.body,
        );
        if (!isRetryable || attempt == _maxUploadAttempts) {
          throw Exception(message);
        }
        lastError = Exception(message);
      } on TimeoutException catch (e) {
        if (attempt == _maxUploadAttempts) {
          throw Exception(
            'Upload timed out after multiple attempts: ${e.message ?? 'timeout'}',
          );
        }
        lastError = Exception(e.message ?? 'timeout');
      }

      // Backoff for transient network/provider issues.
      await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
    }

    throw lastError ?? Exception('Upload failed after multiple attempts');
  }

  static bool _isRetryableUploadFailure(int statusCode, String body) {
    if (statusCode != 500 &&
        statusCode != 502 &&
        statusCode != 503 &&
        statusCode != 504) {
      return false;
    }
    final lowerBody = body.toLowerCase();
    return lowerBody.contains('timeout') ||
        lowerBody.contains('request timeout') ||
        lowerBody.contains('cloudinary');
  }

  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles,
    String token,
  ) async {
    final urls = <String>[];
    for (final file in imageFiles) {
      try {
        final url = await uploadImage(file, token);
        if (url != null) urls.add(url);
      } catch (_) {
        continue;
      }
    }
    return urls;
  }

  static MediaType _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }
}
