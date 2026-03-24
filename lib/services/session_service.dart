import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Global session service to handle auth expiry from anywhere in the app.
///
/// When any API call returns 401 or 403, the app automatically clears the
/// session and redirects the user to the login screen with a snackbar message.
class SessionService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static BuildContext? _routerContext;

  /// Whether a session-expiry redirect is already in progress.
  /// Prevents multiple simultaneous redirects from concurrent failing API calls.
  static bool _isHandlingExpiry = false;

  /// Set the router context from the top-level widget's build method.
  static void setRouterContext(BuildContext context) {
    _routerContext = context;
  }

  /// Handle session expiry: show a snackbar and navigate to login.
  ///
  /// Safe to call from services that have no direct access to BuildContext.
  static void handleSessionExpiry() {
    if (_isHandlingExpiry) return;
    _isHandlingExpiry = true;

    // Show snackbar via the global key
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please login again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate to login via the router context
    final context = _routerContext ?? navigatorKey.currentContext;
    if (context != null && context.mounted) {
      GoRouter.of(context).go('/login');
    }

    // Reset the flag after a short delay so future expirations can trigger again
    Future.delayed(const Duration(seconds: 2), () {
      _isHandlingExpiry = false;
    });
  }
}
