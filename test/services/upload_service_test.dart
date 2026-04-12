import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lipa_cart/services/upload_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  http.StreamedResponse _response(int statusCode, Object body) {
    final bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(Stream.value(bytes), statusCode);
  }

  group('UploadService.uploadImageBytes', () {
    test('builds multipart request and returns uploaded url on success', () async {
      late http.MultipartRequest captured;

      final url = await UploadService.uploadImageBytes(
        Uint8List.fromList([1, 2, 3, 4]),
        'profile.jpg',
        'token-123',
        apiUrlOverride: 'https://api.example.com',
        sendRequest: (request) async {
          captured = request;
          return _response(201, [
            {'url': 'https://res.cloudinary.com/demo/image/upload/v1/profile.jpg'},
          ]);
        },
      );

      expect(url, 'https://res.cloudinary.com/demo/image/upload/v1/profile.jpg');
      expect(captured.url.toString(), 'https://api.example.com/upload');
      expect(captured.method, 'POST');
      expect(captured.headers['Authorization'], 'Bearer token-123');
      expect(captured.files, hasLength(1));
      expect(captured.files.first.field, 'files');
      expect(captured.files.first.filename, 'profile.jpg');
      expect(captured.files.first.contentType.mimeType, 'image/jpeg');
    });

    test('uses image/png content type for .png files', () async {
      late http.MultipartRequest captured;

      await UploadService.uploadImageBytes(
        Uint8List.fromList([10, 20]),
        'avatar.png',
        'token-123',
        apiUrlOverride: 'https://api.example.com',
        sendRequest: (request) async {
          captured = request;
          return _response(200, [
            {'url': 'https://res.cloudinary.com/demo/image/upload/v1/avatar.png'},
          ]);
        },
      );

      expect(captured.files.first.contentType.mimeType, 'image/png');
    });

    test('throws for non-success responses', () async {
      expect(
        () => UploadService.uploadImageBytes(
          Uint8List.fromList([1, 2, 3]),
          'profile.jpg',
          'token-123',
          apiUrlOverride: 'https://api.example.com',
          sendRequest: (_) async => _response(500, {'error': 'failed'}),
        ),
        throwsException,
      );
    });

    test('throws when response is missing file list', () async {
      expect(
        () => UploadService.uploadImageBytes(
          Uint8List.fromList([1, 2, 3]),
          'profile.jpg',
          'token-123',
          apiUrlOverride: 'https://api.example.com',
          sendRequest: (_) async => _response(200, {'url': 'not-a-list'}),
        ),
        throwsException,
      );
    });

    test('rejects files larger than 10MB before sending request', () async {
      var senderCalled = false;
      final hugeBytes = Uint8List(11 * 1024 * 1024);

      expect(
        () => UploadService.uploadImageBytes(
          hugeBytes,
          'large.jpg',
          'token-123',
          apiUrlOverride: 'https://api.example.com',
          sendRequest: (_) async {
            senderCalled = true;
            return _response(200, [
              {'url': 'https://res.cloudinary.com/demo/image/upload/v1/large.jpg'},
            ]);
          },
        ),
        throwsException,
      );

      expect(senderCalled, isFalse);
    });
  });

  group('UploadService.uploadImage', () {
    test('reads file bytes and filename before upload', () async {
      final tempDir = await Directory.systemTemp.createTemp('upload-service-test');
      addTearDown(() => tempDir.delete(recursive: true));

      final imageFile = File('${tempDir.path}/kyc-selfie.webp');
      await imageFile.writeAsBytes([1, 2, 3, 4, 5]);

      late http.MultipartRequest captured;
      final result = await UploadService.uploadImage(
        imageFile,
        'token-123',
        apiUrlOverride: 'https://api.example.com',
        sendRequest: (request) async {
          captured = request;
          return _response(201, [
            {'url': 'https://res.cloudinary.com/demo/image/upload/v1/kyc-selfie.webp'},
          ]);
        },
      );

      expect(result, 'https://res.cloudinary.com/demo/image/upload/v1/kyc-selfie.webp');
      expect(captured.files.first.filename, 'kyc-selfie.webp');
      expect(captured.files.first.contentType.mimeType, 'image/webp');
    });
  });
}
