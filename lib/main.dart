import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/imgbb_upload_provider.dart';
import 'providers/shopper_provider.dart';
import 'providers/rider_provider.dart';
import 'services/order_service.dart';
import 'services/address_service.dart';
import 'services/session_service.dart';
import 'role_based_router.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.tracesSampleRate = 0.2;
      options.environment = AppConfig.sentryEnvironment;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase if configured (skip gracefully in dev without config)
      if (DefaultFirebaseOptions.isConfigured) {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } else {
          Firebase.app();
        }
        await NotificationService().init();
      }

      // Only set system UI overlay and orientations on mobile
      if (!kIsWeb) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        );

        // Allow landscape on tablets (shortestSide >= 600), portrait-only on phones
        final shortestSide =
            PlatformDispatcher.instance.views.first.physicalSize.shortestSide /
            PlatformDispatcher.instance.views.first.devicePixelRatio;
        if (shortestSide < 600) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        }
      }

      // Prevent GoRouter empty-stack assertion on web back button
      GoRouter.optionURLReflectsImperativeAPIs = true;

      // Capture Flutter framework errors to Sentry
      FlutterError.onError = (FlutterErrorDetails details) {
        // Suppress GoRouter/Navigator assertions caused by web back button
        // popping the last route (empty stack, locked navigator, duplicate keys)
        final message = details.exception.toString();
        if (message.contains('currentConfiguration.isNotEmpty') ||
            message.contains('popped the last page') ||
            message.contains('!_debugLocked') ||
            message.contains('Duplicate GlobalKey')) {
          return;
        }
        FlutterError.presentError(details);
        Sentry.captureException(details.exception, stackTrace: details.stack);
      };

      // Capture async errors (uncaught exceptions outside Flutter framework)
      PlatformDispatcher.instance.onError = (error, stack) {
        Sentry.captureException(error, stackTrace: stack);
        return true;
      };

      runApp(const LipaCartApp());
    },
  );
}

class LipaCartApp extends StatefulWidget {
  const LipaCartApp({super.key});

  @override
  State<LipaCartApp> createState() => _LipaCartAppState();
}

class _LipaCartAppState extends State<LipaCartApp> {
  GoRouter? _router;

  @override
  void dispose() {
    RoleBasedRouter.reset();
    _router = null;
    super.dispose();
  }

  /// Route notification taps to the correct screen based on payload data.
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final router = _router;
    if (router == null) return;

    final route = data['route'] as String?;
    final type = data['type'] as String? ?? '';
    final orderId = data['orderId']?.toString();

    Future<bool> openLatestCustomerOrder() async {
      if (orderId == null || orderId.isEmpty) return false;

      final navContext = router.routerDelegate.navigatorKey.currentContext;
      if (navContext == null) return false;

      final auth = Provider.of<AuthProvider>(navContext, listen: false);
      final orderService = Provider.of<OrderService>(navContext, listen: false);
      if (auth.token == null) return false;

      final success = await orderService.getOrder(auth.token!, orderId);
      final latestOrder = orderService.currentOrder;
      if (success && latestOrder != null) {
        router.go('/customer/order-tracking', extra: latestOrder);
        return true;
      }

      return false;
    }

    if (type == 'order_status' || type == 'substitute_suggestion') {
      final openedLatest = await openLatestCustomerOrder();
      if (openedLatest) return;
    }

    if (route != null && route.isNotEmpty) {
      router.go(route);
      return;
    }

    switch (type) {
      case 'order_status':
      case 'substitute_suggestion':
        router.go('/customer/orders');
        break;
      case 'substitute_response':
        router.go('/shopper/active-tasks');
        break;
      case 'new_task':
        router.go('/shopper/available-tasks');
        break;
      case 'new_delivery':
        router.go('/rider/available-deliveries');
        break;
      default:
        router.go('/customer/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => AddressService()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ImgBBUploadProvider()),
        ChangeNotifierProvider(create: (_) => ShopperProvider()),
        ChangeNotifierProvider(create: (_) => RiderProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Create router once, reuse across rebuilds
          _router ??= RoleBasedRouter.getRouter(context);

          // Wire notification tap routing
          NotificationService().onNotificationTap = _handleNotificationTap;

          // Provide the router context to SessionService so it can
          // navigate to /login on auth expiry from anywhere in the app.
          SessionService.setRouterContext(context);

          return MaterialApp.router(
            title: 'LipaCart',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            scaffoldMessengerKey: SessionService.scaffoldMessengerKey,
            routerConfig: _router!,
          );
        },
      ),
    );
  }
}
