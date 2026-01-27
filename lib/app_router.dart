import 'package:flutter/material.dart';
import 'models/product.dart';
import 'models/category.dart';
import 'models/order.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/main_shell.dart';
import 'screens/home/search_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/checkout/order_success_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/orders/order_tracking_screen.dart';
import 'screens/shopping_lists/shopping_lists_screen.dart';
import 'screens/shopping_lists/shopping_list_detail_screen.dart';
import 'screens/recipes/recipes_screen.dart';
import 'screens/recipes/recipe_detail_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildRoute(const SplashScreen(), settings);

      case '/onboarding':
        return _buildRoute(const OnboardingScreen(), settings);

      case '/login':
        final returnRoute = settings.arguments as String?;
        return _buildRoute(
          LoginScreen(returnRoute: returnRoute),
          settings,
        );

      case '/otp':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return _buildRoute(const LoginScreen(), settings);
        }
        return _buildRoute(
          OtpScreen(
            phoneNumber: args['phoneNumber'] as String,
            returnRoute: args['returnRoute'] as String?,
          ),
          settings,
        );

      case '/main':
        return _buildRoute(const MainShell(), settings);

      case '/search':
        return _buildRoute(const SearchScreen(), settings);

      case '/categories':
        return _buildRoute(const CategoriesScreen(), settings);

      case '/category':
        final category = settings.arguments as Category?;
        if (category == null) {
          return _buildRoute(const CategoriesScreen(), settings);
        }
        return _buildRoute(
          CategoryProductsScreen(
            categoryId: category.id,
            categoryName: category.name,
          ),
          settings,
        );

      case '/product':
        final product = settings.arguments as Product?;
        if (product == null) {
          return _buildRoute(const MainShell(), settings);
        }
        return _buildRoute(ProductDetailScreen(product: product), settings);

      case '/cart':
        return _buildRoute(const CartScreen(), settings);

      case '/checkout':
        return _buildRoute(const CheckoutScreen(), settings);

      case '/order-success':
        final order = settings.arguments as Order?;
        if (order == null) {
          return _buildRoute(const MainShell(), settings);
        }
        return _buildRoute(OrderSuccessScreen(order: order), settings);

      case '/orders':
        return _buildRoute(const OrdersScreen(), settings);

      case '/order-tracking':
        final order = settings.arguments as Order?;
        if (order == null) {
          return _buildRoute(const MainShell(), settings);
        }
        return _buildRoute(OrderTrackingScreen(order: order), settings);

      case '/shopping-lists':
        return _buildRoute(const ShoppingListsScreen(), settings);

      case '/shopping-list-detail':
        final listId = settings.arguments as String?;
        if (listId == null) {
          return _buildRoute(const ShoppingListsScreen(), settings);
        }
        return _buildRoute(ShoppingListDetailScreen(listId: listId), settings);

      case '/recipes':
        return _buildRoute(const RecipesScreen(), settings);

      case '/recipe-detail':
        final recipeId = settings.arguments as String?;
        if (recipeId == null) {
          return _buildRoute(const RecipesScreen(), settings);
        }
        return _buildRoute(RecipeDetailScreen(recipeId: recipeId), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
