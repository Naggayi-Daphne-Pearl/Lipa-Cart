import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/constants/app_constants.dart';

/// Uploads images through Strapi's `/api/upload` endpoint. Strapi then
/// delegates to whichever upload provider is configured server-side
/// (currently Cloudinary — see `Lipa-Cart-Backend/config/plugins.ts`).
class UploadService {
  static String get _apiUrl => AppConstants.apiUrl;

  static const int _maxFileSizeMb = 10;

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
    final sizeMb = bytes.length / (1024 * 1024);
    if (sizeMb > _maxFileSizeMb) {
      throw Exception(
        'Image too large: ${sizeMb.toStringAsFixed(1)}MB (max ${_maxFileSizeMb}MB)',
      );
    }

    final baseUrl = apiUrlOverride ?? _apiUrl;
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'files',
        bytes,
        filename: fileName,
        contentType: _contentTypeFor(fileName),
      ),
    );

    final sender = sendRequest ?? _defaultSend;
    final streamed = await sender(request).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw TimeoutException('Upload timed out after 60s'),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Upload failed: HTTP ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      throw Exception('Upload response missing file data: ${response.body}');
    }
    final first = decoded.first as Map<String, dynamic>;
    return first['url'] as String?;
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
