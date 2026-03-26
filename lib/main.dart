import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/config/app_config.dart';
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
      // Only set system UI overlay and orientations on mobile
      if (!kIsWeb) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        );

        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }

      // Capture Flutter framework errors to Sentry
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        Sentry.captureException(
          details.exception,
          stackTrace: details.stack,
        );
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
