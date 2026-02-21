import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../core/constants/app_constants.dart';

/// HTTP client with automatic token refresh on 401 errors
/// Wraps standard http.Client with authentication and retry logic
class AuthenticatedHttpClient {
  final http.Client _client = http.Client();
  final AuthProvider _authProvider;

  AuthenticatedHttpClient(this._authProvider);

  /// GET request with automatic token refresh
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return _requestWithRetry(
      () => _client.get(url, headers: _buildHeaders(headers)),
    );
  }

  /// POST request with automatic token refresh
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithRetry(
      () => _client.post(
        url,
        headers: _buildHeaders(headers),
        body: body,
        encoding: encoding,
      ),
    );
  }

  /// PUT request with automatic token refresh
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithRetry(
      () => _client.put(
        url,
        headers: _buildHeaders(headers),
        body: body,
        encoding: encoding,
      ),
    );
  }

  /// PATCH request with automatic token refresh
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithRetry(
      () => _client.patch(
        url,
        headers: _buildHeaders(headers),
        body: body,
        encoding: encoding,
      ),
    );
  }

  /// DELETE request with automatic token refresh
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithRetry(
      () => _client.delete(
        url,
        headers: _buildHeaders(headers),
        body: body,
        encoding: encoding,
      ),
    );
  }

  /// Execute request with automatic retry on 401 (after token refresh)
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(AppConstants.apiTimeout);

      // Token expired - try to refresh and retry
      if (response.statusCode == 401 && _authProvider.token != null) {
        final refreshed = await _authProvider.refreshToken();

        if (refreshed) {
          // Retry with new token
          return await request().timeout(AppConstants.apiTimeout);
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Build headers with Authorization token if available
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{'Content-Type': 'application/json'};

    // Add custom headers
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    // Add Authorization header if token exists
    if (_authProvider.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider.token}';
    }

    return headers;
  }

  void close() {
    _client.close();
  }
}
