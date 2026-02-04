import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/order.dart';
import 'models/product.dart';

// Import screens
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/profile/profile_screen.dart';

// Customer screens
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
import 'screens/customer/addresses_screen.dart';

// Admin screens
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_products_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_orders_screen.dart';
import 'screens/admin/admin_analytics_screen.dart';

// Rider screens
import 'screens/rider/rider_home_screen.dart';
import 'screens/rider/rider_available_deliveries_screen.dart';
import 'screens/rider/rider_active_deliveries_screen.dart';
import 'screens/rider/rider_earnings_screen.dart';
import 'screens/rider/rider_ratings_screen.dart';

// Shopper screens
import 'screens/shopper/shopper_home_screen.dart';
import 'screens/shopper/shopper_available_tasks_screen.dart';
import 'screens/shopper/shopper_active_tasks_screen.dart';
import 'screens/shopper/shopper_earnings_screen.dart';
import 'screens/shopper/shopper_completed_tasks_screen.dart';

/// Unified role-based router that handles all user types in one app
class RoleBasedRouter {
  static GoRouter? _router;

  static GoRouter getRouter(BuildContext context) {
    _router ??= GoRouter(
      initialLocation: '/',
      routes: [
        // Auth Routes
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            return const LoginScreen();
          },
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final phoneNumber = state.extra as String? ?? '';
            return OtpScreen(phoneNumber: phoneNumber);
          },
        ),

        // Customer Routes
        GoRoute(
          path: '/customer/home',
          builder: (context, state) => const MainShell(),
        ),
        GoRoute(
          path: '/customer/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/customer/categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/customer/product',
          builder: (context, state) {
            final product = state.extra as Product?;
            if (product == null) return const MainShell();
            return ProductDetailScreen(product: product);
          },
        ),
        GoRoute(
          path: '/customer/addresses',
          builder: (context, state) => const AddressesScreen(),
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/customer/checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/customer/order-success',
          builder: (context, state) {
            final order = state.extra as Order?;
            if (order == null) return const MainShell();
            return OrderSuccessScreen(order: order);
          },
        ),
        GoRoute(
          path: '/customer/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/customer/order-tracking',
          builder: (context, state) {
            final order = state.extra as Order?;
            if (order == null) return const MainShell();
            return OrderTrackingScreen(order: order);
          },
        ),
        GoRoute(
          path: '/customer/shopping-lists',
          builder: (context, state) => const ShoppingListsScreen(),
        ),
        GoRoute(
          path: '/customer/shopping-list-detail',
          builder: (context, state) {
            final listId = state.extra as String?;
            if (listId == null) return const ShoppingListsScreen();
            return ShoppingListDetailScreen(listId: listId);
          },
        ),
        GoRoute(
          path: '/customer/recipes',
          builder: (context, state) => const RecipesScreen(),
        ),
        GoRoute(
          path: '/customer/recipe-detail',
          builder: (context, state) {
            final recipeId = state.extra as String?;
            if (recipeId == null) return const RecipesScreen();
            return RecipeDetailScreen(recipeId: recipeId);
          },
        ),
        GoRoute(
          path: '/customer/profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        // Admin Routes
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => const AdminProductsScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const AdminOrdersScreen(),
        ),
        GoRoute(
          path: '/admin/analytics',
          builder: (context, state) => const AdminAnalyticsScreen(),
        ),

        // Rider Routes
        GoRoute(
          path: '/rider/home',
          builder: (context, state) => const RiderHomeScreen(),
        ),
        GoRoute(
          path: '/rider/available-deliveries',
          builder: (context, state) => const RiderAvailableDeliveriesScreen(),
        ),
        GoRoute(
          path: '/rider/active-deliveries',
          builder: (context, state) => const RiderActiveDeliveriesScreen(),
        ),
        GoRoute(
          path: '/rider/earnings',
          builder: (context, state) => const RiderEarningsScreen(),
        ),
        GoRoute(
          path: '/rider/ratings',
          builder: (context, state) => const RiderRatingsScreen(),
        ),

        // Shopper Routes
        GoRoute(
          path: '/shopper/home',
          builder: (context, state) => const ShopperHomeScreen(),
        ),
        GoRoute(
          path: '/shopper/available-tasks',
          builder: (context, state) => const ShopperAvailableTasksScreen(),
        ),
        GoRoute(
          path: '/shopper/active-tasks',
          builder: (context, state) => const ShopperActiveTasksScreen(),
        ),
        GoRoute(
          path: '/shopper/completed-tasks',
          builder: (context, state) => const ShopperCompletedTasksScreen(),
        ),
        GoRoute(
          path: '/shopper/earnings',
          builder: (context, state) => const ShopperEarningsScreen(),
        ),
      ],
    );
    return _router!;
  }

  static void resetRouter() {
    _router = null;
  }
}

// Shell widgets for bottom navigation
class CustomerMainShell extends StatefulWidget {
  final Widget child;
  const CustomerMainShell({Key? key, required this.child}) : super(key: key);

  @override
  State<CustomerMainShell> createState() => _CustomerMainShellState();
}

class _CustomerMainShellState extends State<CustomerMainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          final routes = [
            '/customer/home',
            '/customer/categories',
            '/customer/orders',
            '/customer/profile',
          ];
          context.go(routes[index]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Placeholder shells for other roles (implement similarly)
class ShopperMainShell extends StatelessWidget {
  final Widget child;
  const ShopperMainShell({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Earnings',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}

class RiderMainShell extends StatelessWidget {
  final Widget child;
  const RiderMainShell({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Deliveries',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Earnings',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}

class AdminMainShell extends StatelessWidget {
  final Widget child;
  const AdminMainShell({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Users'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
      ],
    ),
  );
}
