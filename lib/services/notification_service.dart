import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/config/firebase_options.dart';
import 'web_notification_stub.dart'
    if (dart.library.js_interop) 'web_notification.dart';

/// Top-level handler for background FCM messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // On Android, background messages are shown automatically by FCM.
  // This handler is for any custom processing you need.
  debugPrint('[notifications] Background message: ${message.messageId}');
}

/// Service that manages push notifications via Firebase Cloud Messaging.
///
/// Handles:
/// - Requesting notification permission
/// - Obtaining and registering the FCM device token
/// - Displaying local notifications when the app is in the foreground
/// - Routing notification taps to the correct screen
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Callback invoked when a notification is tapped.
  /// The [data] map contains payload sent from the backend (e.g. orderId, type).
  void Function(Map<String, dynamic> data)? onNotificationTap;

  bool _initialized = false;

  /// Android notification channel for order updates.
  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
        'lipacart_orders',
        'Order Updates',
        description: 'Notifications about your LipaCart orders',
        importance: Importance.high,
      );

  /// Initialize the notification service. Call once after Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized || !DefaultFirebaseOptions.isConfigured) return;

    try {
      _messaging = FirebaseMessaging.instance;

      if (!kIsWeb) {
        // Register the background handler
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );

        // Create the Android notification channel
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_orderChannel);

        // Initialize local notifications for foreground display
        await _localNotifications.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(),
          ),
          onDidReceiveNotificationResponse: _onLocalNotificationTap,
        );
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps that open the app from background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Avoid blocking startup indefinitely on browsers where web push isn't fully supported.
      final initialMessage = await _messaging!.getInitialMessage().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('[notifications] Init skipped: $e');
    } finally {
      _initialized = true;
    }
  }

  /// Request notification permission from the user.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    if (_messaging == null) return false;

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Get the current FCM device token.
  Future<String?> getToken() async {
    if (_messaging == null) return null;

    try {
      if (kIsWeb) {
        // Web requires a VAPID key from Firebase Console → Cloud Messaging → Web Push certificates
        return await _messaging!.getToken(
          vapidKey:
              'BMrbqo9Y3Jm9LPgvapCjKgbCS75GRDH78147SmrRSI6StsTqMi2xudsdljV4UG9P0Ypmz4hffrXYzwZUQ1ClDpQ',
        );
      }
      return await _messaging!.getToken();
    } catch (e) {
      debugPrint('[notifications] Failed to get FCM token: $e');
      return null;
    }
  }

  /// Register the device token with the backend.
  Future<void> registerTokenWithBackend(String authToken) async {
    final fcmToken = await getToken();
    if (fcmToken == null) {
      debugPrint('[notifications] No FCM token available to register');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/user/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('[notifications] Device token registered with backend');
      } else {
        debugPrint(
          '[notifications] Device token registration failed: '
          '${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[notifications] Failed to register device token: $e');
    }
  }

  /// Unregister current device token from backend (best effort).
  Future<void> unregisterTokenWithBackend(String authToken) async {
    final fcmToken = await getToken();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/user/unregister-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[notifications] Device token unregister failed: '
          '${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[notifications] Failed to unregister device token: $e');
    }
  }

  /// Fetch unread notification count for current authenticated user.
  Future<int> getUnreadCount(String authToken) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConstants.apiUrl}/notifications/mine?page=1&pageSize=1',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) return 0;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final unread = body['meta']?['unreadCount'];
      return unread is num ? unread.toInt() : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Listen for token refresh and re-register with backend.
  void listenForTokenRefresh(String authToken) {
    _messaging?.onTokenRefresh.listen((newToken) async {
      try {
        final response = await http.post(
          Uri.parse('${AppConstants.apiUrl}/user/register-device'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({'fcm_token': newToken}),
        );

        if (response.statusCode != 200) {
          debugPrint(
            '[notifications] Refreshed token registration failed: '
            '${response.statusCode} ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('[notifications] Failed to re-register refreshed token: $e');
      }
    });
  }

  /// Show a local notification when a FCM message arrives while app is in foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    if (kIsWeb) {
      debugPrint('[notifications] *** FOREGROUND WEB MESSAGE RECEIVED ***');
      debugPrint('[notifications] Title: ${notification.title}');
      debugPrint('[notifications] Body: ${notification.body}');
      _showWebNotification(
        notification.title ?? 'LipaCart',
        notification.body ?? '',
      );
    } else {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _orderChannel.id,
            _orderChannel.name,
            channelDescription: _orderChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Show a browser notification on web using the service worker registration.
  void _showWebNotification(String title, String body) {
    // Use Firebase messaging's built-in foreground notification by re-dispatching
    // through the service worker. We access it via the messaging instance.
    try {
      // The simplest approach: show via JS eval through the Flutter web engine
      // This works because we're already running in a browser context
      _webNotificationFallback(title, body);
    } catch (e) {
      debugPrint('[notifications] Web notification failed: $e');
    }
  }

  void _webNotificationFallback(String title, String body) {
    if (kIsWeb) {
      try {
        callShowBrowserNotification(title, body);
      } catch (e) {
        debugPrint('[notifications] Browser notification error: $e');
      }
    }
  }

  /// Handle notification tap from FCM (background/terminated).
  void _handleNotificationTap(RemoteMessage message) {
    onNotificationTap?.call(message.data);
  }

  /// Handle notification tap from local notification (foreground).
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        onNotificationTap?.call(data);
      } catch (_) {}
    }
  }
}
