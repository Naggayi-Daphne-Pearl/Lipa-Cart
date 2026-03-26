/// Runtime configuration read from --dart-define environment variables.
///
/// Pass values at build time:
///   flutter run --dart-define=API_BASE_URL=https://your-api.com
///   flutter build web --dart-define=API_BASE_URL=https://your-api.com
///
/// For local development the defaults point at localhost.
class AppConfig {
  AppConfig._();

  /// Backend API base URL (no trailing slash)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:1337',
  );

  /// Full API path
  static const String apiUrl = '$apiBaseUrl/api';

  /// Sentry DSN for error tracking
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Sentry environment tag
  static const String sentryEnvironment = String.fromEnvironment(
    'SENTRY_ENV',
    defaultValue: 'development',
  );

  /// ImgBB API key for image uploads
  static const String imgbbApiKey = String.fromEnvironment(
    'IMGBB_API_KEY',
    defaultValue: '',
  );
}
