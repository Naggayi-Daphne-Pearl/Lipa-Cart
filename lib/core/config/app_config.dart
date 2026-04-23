/// Runtime configuration read from --dart-define environment variables.
///
/// Pass values at build time:
///   flutter run --dart-define=API_BASE_URL=https://your-api.com
///   flutter build web --dart-define=API_BASE_URL=https://your-api.com
///
/// For Firebase push notifications also pass:
///   --dart-define=FIREBASE_API_KEY=...
///   --dart-define=FIREBASE_PROJECT_ID=...
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=...
///   --dart-define=FIREBASE_APP_ID=...
///
/// For Google OAuth on web also pass:
///  ` --dart-define=GOOGLE_WEB_CLIENT_ID=...
///
/// Defaults point at the Railway production backend so dev builds Just Work
/// against a real API. To run against a local Strapi instance, override at
/// build time:
///   flutter run --dart-define=API_BASE_URL=http://localhost:1337
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

  /// Google OAuth web client ID used by the consent screen / Google sign-in.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '461833863082-gkset420arg3nqcip15jm9ptclom7g9e.apps.googleusercontent.com',
  );

  static bool get isGoogleOAuthConfigured =>
      googleWebClientId.trim().isNotEmpty;

  /// Ntuma hosted-checkout link (MVP payment provider).
  /// Override per environment: --dart-define=NTUMA_PAY_LINK=https://ntuma.app/pay/MERCHANT_UUID
  static const String ntumaPayLink = String.fromEnvironment(
    'NTUMA_PAY_LINK',
    defaultValue: 'https://ntuma.app/pay/3d2c8f1b-1d9e-43a1-a72d-ceaef0ce8aa9',
  );
}
