import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ImgBBService {
  /// Replace with your ImgBB API Key from https://imgbb.com/dashboard
  /// GET KEY: https://imgbb.com/dashboard → API button (top right)
  static const String apiKey = '9b8b1e167f65f3825ae4e1716c8b9bf5';

  static const String baseUrl = 'https://api.imgbb.com/1/upload';

  /// Upload single image to ImgBB
  /// Returns the image URL from the API response
  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Read image file and convert to base64
      final bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // Check file size (ImgBB max is 32MB, but keep under 5MB)
      int fileSizeInMB = bytes.length ~/ (1024 * 1024);
      if (fileSizeInMB > 5) {
        throw Exception('Image too large: ${fileSizeInMB}MB (max 5MB)');
      }

      // Create the request - using the exact format from ImgBB API
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['key'] = apiKey;
      request.fields['image'] = base64Image;

      // Send request with timeout
      var streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Upload timeout after 30 seconds'),
          );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);

        // Check if ImgBB returned success
        if (json['success'] == true) {
          // Use the URL from the response
          String imageUrl = json['data']['url'];

          return imageUrl;
        } else {
          String error = json['error']['message'] ?? 'Unknown error';
          throw Exception('ImgBB error: $error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload image from bytes (web-compatible)
  /// Returns the image URL from the API response
  static Future<String?> uploadImageBytes(Uint8List bytes, String fileName) async {
    try {
      final String base64Image = base64Encode(bytes);

      int fileSizeInMB = bytes.length ~/ (1024 * 1024);
      if (fileSizeInMB > 5) {
        throw Exception('Image too large: ${fileSizeInMB}MB (max 5MB)');
      }

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['key'] = apiKey;
      request.fields['image'] = base64Image;

      var streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Upload timeout after 30 seconds'),
          );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['success'] == true) {
          return json['data']['url'];
        } else {
          String error = json['error']['message'] ?? 'Unknown error';
          throw Exception('ImgBB error: $error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload multiple images (batch)
  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles,
  ) async {
    List<String> urls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        String? url = await uploadImage(imageFiles[i]);

        if (url != null) {
          urls.add(url);
        }

        // Small delay between uploads
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        continue;
      }
    }

    return urls;
  }
}
