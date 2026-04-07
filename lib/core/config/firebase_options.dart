import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration read from --dart-define environment variables.
///
/// Pass values at build time:
///   flutter run \
///     --dart-define=FIREBASE_API_KEY=... \
///     --dart-define=FIREBASE_PROJECT_ID=... \
///     --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
///     --dart-define=FIREBASE_APP_ID=...
///
/// Or generate this file automatically with:
///   flutterfire configure
class DefaultFirebaseOptions {
  static const _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'lipa-cart',
  );
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '461833863082',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'lipa-cart.firebasestorage.app',
  );
  static const _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: 'G-ZM4L9JJ7N5',
  );

  // Web Firebase app
  static const _webApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyBGWIinYblWXKjws0O3J3AuS3sjn26aq1o',
  );
  static const _webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:461833863082:web:bf946f68ce79646dfbb5d3',
  );

  // Android Firebase app (matches `android/app/google-services.json`)
  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyCjmKZ3Y5BirUZTLqkYDB4nasPokTqacOc',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:461833863082:android:ba1bf3a16ef9925efbb5d3',
  );

  // iOS Firebase app (matches `ios/Runner/GoogleService-Info.plist`)
  static const _iosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
    defaultValue: 'AIzaSyBjD3UGL6M1vjXJKN6zs6yFOo99jTUzobE',
  );
  static const _iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '1:461833863082:ios:553826fdbd96614afbb5d3',
  );

  /// Whether Firebase has been configured with valid credentials.
  static bool get isConfigured =>
      _projectId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      (_webApiKey.isNotEmpty ||
          _androidApiKey.isNotEmpty ||
          _iosApiKey.isNotEmpty);

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _webApiKey,
    appId: _webAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    authDomain: 'lipa-cart.firebaseapp.com',
    measurementId: _measurementId,
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _androidApiKey,
    appId: _androidAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _iosApiKey,
    appId: _iosAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'com.lipacart.lipaCart',
  );
}
