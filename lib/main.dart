import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const LipaCartApp());
}

class LipaCartApp extends StatelessWidget {
  const LipaCartApp({super.key});

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
          // Provide the router context to SessionService so it can
          // navigate to /login on auth expiry from anywhere in the app.
          SessionService.setRouterContext(context);

          return MaterialApp.router(
            title: 'LipaCart',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            scaffoldMessengerKey: SessionService.scaffoldMessengerKey,
            routerConfig: RoleBasedRouter.getRouter(context),
          );
        },
      ),
    );
  }
}
