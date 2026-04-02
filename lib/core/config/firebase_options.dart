import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
  static const _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBGWIinYblWXKjws0O3J3AuS3sjn26aq1o',
  );
  static const _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'lipa-cart',
  );
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '461833863082',
  );
  static const _appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:461833863082:web:bf946f68ce79646dfbb5d3',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'lipa-cart.firebasestorage.app',
  );
  static const _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: 'G-ZM4L9JJ7N5',
  );

  /// Whether Firebase has been configured with valid credentials.
  static bool get isConfigured => _apiKey.isNotEmpty && _projectId.isNotEmpty;

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
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        authDomain: 'lipa-cart.firebaseapp.com',
        measurementId: _measurementId,
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: 'com.lipacart.lipaCart',
      );
}
