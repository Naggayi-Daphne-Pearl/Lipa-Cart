import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import 'http_client_factory.dart';
import '../core/constants/app_constants.dart';
import 'session_service.dart';

/// HTTP client with automatic token refresh on 401 errors
/// Wraps standard http.Client with authentication and retry logic
class AuthenticatedHttpClient {
  final http.Client _client = createHttpClient();
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

  /// Execute request with automatic retry on 401 (after token refresh).
  ///
  /// If the retry also fails with 401/403, the session is considered expired
  /// and the user is redirected to the login screen via [SessionService].
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
          final retryResponse =
              await request().timeout(AppConstants.apiTimeout);

          // If the retry still fails with 401/403, handle session expiry
          if (_isAuthError(retryResponse)) {
            await _handleSessionExpiry();
          }
          return retryResponse;
        } else {
          // Token refresh itself failed — session is expired
          await _handleSessionExpiry();
        }
      }

      // First response was 403 (forbidden) — session/role issue
      if (response.statusCode == 403 && _authProvider.token != null) {
        if (!_isAuthEndpoint(response)) {
          await _handleSessionExpiry();
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a response indicates an authentication/authorization error.
  bool _isAuthError(http.Response response) {
    return (response.statusCode == 401 || response.statusCode == 403) &&
        !_isAuthEndpoint(response);
  }

  /// Returns true if the request targeted an auth endpoint (login, signup, etc.)
  /// so we don't trigger session expiry for expected auth failures.
  bool _isAuthEndpoint(http.Response response) {
    final path = response.request?.url.path ?? '';
    return path.contains('/auth/');
  }

  /// Clear the stored token and redirect to login via SessionService.
  Future<void> _handleSessionExpiry() async {
    await _authProvider.logout();
    SessionService.handleSessionExpiry();
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
