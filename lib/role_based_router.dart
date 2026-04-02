import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'models/category.dart';
import 'models/order.dart';
import 'models/product.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';

// Import screens
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/profile_completion_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
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
import 'screens/customer/order_rating_screen.dart';
import 'screens/customer/ratings_reviews_screen.dart';
import 'screens/notifications/notification_inbox_screen.dart';

// Admin screens
import 'screens/admin/admin_shell.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_products_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_riders_screen.dart';
import 'screens/admin/admin_orders_screen.dart';
import 'screens/admin/admin_analytics_screen.dart';
import 'screens/admin/admin_user_management_screen.dart';

// Rider screens
import 'screens/rider/rider_home_screen.dart';
import 'screens/rider/rider_available_deliveries_screen.dart';
import 'screens/rider/rider_active_deliveries_screen.dart';
import 'screens/rider/rider_earnings_screen.dart';
import 'screens/rider/rider_ratings_screen.dart';
import 'screens/rider/rider_kyc_screen.dart';
import 'screens/rider/rider_pending_approval_screen.dart';
import 'screens/rider/rider_profile_screen.dart';

// Shopper screens
import 'screens/shopper/shopper_home_screen.dart';
import 'screens/shopper/shopper_available_tasks_screen.dart';
import 'screens/shopper/shopper_active_tasks_screen.dart';
import 'screens/shopper/shopper_earnings_screen.dart';
import 'screens/shopper/shopper_completed_tasks_screen.dart';
import 'screens/shopper/shopper_kyc_screen.dart';
import 'screens/shopper/shopper_pending_approval_screen.dart';
import 'screens/shopper/shopping_checklist_screen.dart';
import 'screens/shopper/shopper_profile_screen.dart';

/// Helper to get home route based on user role
String _homeForRole(UserRole? role, {String? kycStatus}) {
  switch (role) {
    case UserRole.admin:
      return '/admin/dashboard';
    case UserRole.rider:
      // Route based on KYC status
      if (kycStatus == null || kycStatus == 'not_submitted') {
        return '/rider/kyc';
      } else if (kycStatus == 'pending_review') {
        return '/rider/pending-approval';
      } else if (kycStatus == 'rejected') {
        return '/rider/kyc?rejected=true';
      }
      return '/rider/home';
    case UserRole.shopper:
      // Route based on KYC status
      if (kycStatus == null || kycStatus == 'not_submitted') {
        return '/shopper/kyc';
      } else if (kycStatus == 'pending_review') {
        return '/shopper/pending-approval';
      } else if (kycStatus == 'rejected') {
        return '/shopper/kyc?rejected=true';
      }
      return '/shopper/home';
    case UserRole.customer:
    default:
      return '/customer/home';
  }
}

/// Unified role-based router that handles all user types in one app
class RoleBasedRouter {
  static GoRouter? _router;

  /// Reset cached router (call on hot restart / app recreation)
  static void reset() {
    _router?.dispose();
    _router = null;
  }

  static GoRouter getRouter(BuildContext context) {
    if (_router != null) return _router!;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      observers: [SentryNavigatorObserver()],
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isInitial = authProvider.status == AuthStatus.initial;
        final userRole = authProvider.user?.role;

        // Still loading - let splash handle
        if (isInitial) return null;

        // Define protected routes (require authentication)
        // Customer routes are open for guest browsing
        // Only shopper, rider, and admin routes require authentication
        final isProtectedRoute =
            state.matchedLocation.startsWith('/shopper/') ||
            state.matchedLocation.startsWith('/rider/') ||
            state.matchedLocation.startsWith('/admin/');

        // Define auth routes (should redirect away if already authenticated)
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation.startsWith('/otp') ||
            state.matchedLocation == '/profile-completion' ||
            state.matchedLocation == '/forgot-password';

        final isCustomerProtectedRoute =
            state.matchedLocation.startsWith('/customer/checkout') ||
            state.matchedLocation.startsWith('/customer/orders') ||
            state.matchedLocation.startsWith('/customer/order-tracking') ||
            state.matchedLocation.startsWith('/customer/order-rating') ||
            state.matchedLocation.startsWith('/customer/addresses') ||
            state.matchedLocation.startsWith('/customer/profile');

        // Not authenticated, trying to access protected → go to login
        if (!isAuthenticated &&
            (isProtectedRoute || isCustomerProtectedRoute)) {
          final returnPath = Uri.encodeComponent(state.uri.toString());
          return '/login?return=$returnPath';
        }

        // Already authenticated, trying to access auth routes → go to role home
        if (isAuthenticated && isAuthRoute) {
          return _homeForRole(authProvider.user?.role, kycStatus: authProvider.user?.kycStatus);
        }

        // === ROLE-BASED ACCESS CONTROL ===
        // Ensure users can only access routes for their role

        // Shopper routes - only accessible by shoppers
        if (state.matchedLocation.startsWith('/shopper/')) {
          if (isAuthenticated && userRole != UserRole.shopper) {
            return _homeForRole(userRole, kycStatus: authProvider.user?.kycStatus);
          }

          // KYC enforcement for shoppers
          if (isAuthenticated && userRole == UserRole.shopper) {
            final kycStatus = authProvider.user?.kycStatus;
            final isKycRoute =
                state.matchedLocation == '/shopper/kyc' ||
                state.matchedLocation == '/shopper/pending-approval';

            if (!isKycRoute) {
              // Block access to dashboard/other routes if KYC not approved
              if (kycStatus == null || kycStatus == 'not_submitted') {
                return '/shopper/kyc';
              } else if (kycStatus == 'pending_review') {
                return '/shopper/pending-approval';
              } else if (kycStatus == 'rejected') {
                return '/shopper/kyc?rejected=true';
              }
              // kycStatus == 'approved' → allow access
            } else {
              // On KYC/pending pages but already approved → go to home
              if (kycStatus == 'approved') {
                return '/shopper/home';
              }
            }
          }
        }

        // Rider routes - only accessible by riders
        if (state.matchedLocation.startsWith('/rider/')) {
          if (isAuthenticated && userRole != UserRole.rider) {
            return _homeForRole(userRole, kycStatus: authProvider.user?.kycStatus);
          }

          // KYC enforcement for riders
          if (isAuthenticated && userRole == UserRole.rider) {
            final kycStatus = authProvider.user?.kycStatus;
            final isKycRoute =
                state.matchedLocation == '/rider/kyc' ||
                state.matchedLocation == '/rider/pending-approval';

            if (!isKycRoute) {
              // Block access to home/other routes if KYC not approved
              if (kycStatus == null || kycStatus == 'not_submitted') {
                return '/rider/kyc';
              } else if (kycStatus == 'pending_review') {
                return '/rider/pending-approval';
              } else if (kycStatus == 'rejected') {
                return '/rider/kyc?rejected=true';
              }
              // kycStatus == 'approved' → allow access
            } else {
              // On KYC/pending pages but already approved → go to home
              if (kycStatus == 'approved') {
                return '/rider/home';
              }
            }
          }
        }

        // Admin routes - only accessible by admins
        if (state.matchedLocation.startsWith('/admin/')) {
          if (isAuthenticated && userRole != UserRole.admin) {
            return _homeForRole(userRole, kycStatus: authProvider.user?.kycStatus);
          }
        }

        // Customer-specific protected routes - only for customers
        if (isCustomerProtectedRoute) {
          if (isAuthenticated && userRole != UserRole.customer) {
            return _homeForRole(userRole, kycStatus: authProvider.user?.kycStatus);
          }
        }

        // No redirect needed
        return null;
      },
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
            final returnRoute = state.uri.queryParameters['return'];
            return LoginScreen(returnRoute: returnRoute);
          },
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) {
            return const SignupScreen();
          },
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            if (state.extra is Map<String, dynamic>) {
              final extra = state.extra as Map<String, dynamic>;
              final phoneNumber = extra['phoneNumber'] as String? ?? '';
              final returnRoute = extra['returnRoute'] as String?;
              return OtpScreen(
                phoneNumber: phoneNumber,
                returnRoute: returnRoute,
              );
            }
            final phoneNumber = state.extra as String? ?? '';
            return OtpScreen(phoneNumber: phoneNumber);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/profile-completion',
          builder: (context, state) {
            final phoneNumber = state.extra as String? ?? '';
            return ProfileCompletionScreen(phoneNumber: phoneNumber);
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
          path: '/customer/category',
          builder: (context, state) {
            final category = state.extra as Category?;
            if (category == null) return const CategoriesScreen();
            return CategoryProductsScreen(
              categoryId: category.id,
              categoryName: category.name,
            );
          },
        ),
        GoRoute(
          path: '/customer/product',
          builder: (context, state) {
            // Handle both Product object and serialized Map
            final productData = state.extra;
            final Product? product;

            if (productData is Map<String, dynamic>) {
              product = Product.fromJson(productData);
            } else if (productData is Product) {
              product = productData;
            } else {
              product = null;
            }

            if (product == null) return const MainShell();
            return ProductDetailScreen(product: product);
          },
        ),
        GoRoute(
          path: '/customer/addresses',
          builder: (context, state) {
            final returnRoute = state.uri.queryParameters['return'];
            return AddressesScreen(returnRoute: returnRoute);
          },
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/customer/checkout',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final isGuest = extra?['guest'] == true;
            return CheckoutScreen(isGuest: isGuest);
          },
        ),
        GoRoute(
          path: '/customer/order-success',
          builder: (context, state) {
            // Handle both Order and Map<String, dynamic> (guest order with isGuest flag)
            if (state.extra is Order) {
              final order = state.extra as Order;
              return OrderSuccessScreen(order: order, isGuest: false);
            } else if (state.extra is Map<String, dynamic>) {
              final extra = state.extra as Map<String, dynamic>;

              // Handle order being either Order object or Map
              final orderData = extra['order'];
              final Order? order;

              if (orderData is Map<String, dynamic>) {
                order = Order.fromJson(orderData);
              } else if (orderData is Order) {
                order = orderData;
              } else {
                order = null;
              }

              final isGuest = extra['isGuest'] as bool? ?? false;
              if (order == null) return const MainShell();
              return OrderSuccessScreen(order: order, isGuest: isGuest);
            }
            return const MainShell();
          },
        ),
        GoRoute(
          path: '/customer/notifications',
          builder: (context, state) => const NotificationInboxScreen(),
        ),
        GoRoute(
          path: '/customer/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/customer/order-tracking',
          builder: (context, state) {
            // Handle both Order object and serialized Map
            final orderData = state.extra;
            final Order? order;

            if (orderData is Map<String, dynamic>) {
              order = Order.fromJson(orderData);
            } else if (orderData is Order) {
              order = orderData;
            } else {
              order = null;
            }

            if (order == null) return const MainShell();
            return OrderTrackingScreen(order: order);
          },
        ),
        GoRoute(
          path: '/customer/order-rating',
          builder: (context, state) {
            // Handle both Order object and serialized Map
            final orderData = state.extra;
            final Order? order;

            if (orderData is Map<String, dynamic>) {
              order = Order.fromJson(orderData);
            } else if (orderData is Order) {
              order = orderData;
            } else {
              order = null;
            }

            if (order == null) return const MainShell();
            return OrderRatingScreen(order: order);
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
          path: '/customer/ratings-reviews',
          builder: (context, state) => const RatingsReviewsScreen(),
        ),
        GoRoute(
          path: '/customer/profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        // Admin Routes
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => AdminShell(
            child: const AdminDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => AdminShell(
            child: const AdminProductsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => AdminShell(
            child: const AdminUsersScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => AdminShell(
            child: const AdminOrdersScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/analytics',
          builder: (context, state) => AdminShell(
            child: const AdminAnalyticsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/user-management',
          builder: (context, state) => AdminShell(
            child: const AdminUserManagementScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/riders',
          builder: (context, state) => AdminShell(
            child: const AdminRidersScreen(),
          ),
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
        GoRoute(
          path: '/rider/kyc',
          builder: (context, state) {
            final isRejected = state.uri.queryParameters['rejected'] == 'true';
            return RiderKycScreen(isRejected: isRejected);
          },
        ),
        GoRoute(
          path: '/rider/pending-approval',
          builder: (context, state) => const RiderPendingApprovalScreen(),
        ),
        GoRoute(
          path: '/rider/profile',
          builder: (context, state) => const RiderProfileScreen(),
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
          path: '/shopper/shopping-checklist',
          builder: (context, state) {
            final orderData = state.extra;
            final Order? order;

            if (orderData is Map<String, dynamic>) {
              order = Order.fromJson(orderData);
            } else if (orderData is Order) {
              order = orderData;
            } else {
              order = null;
            }

            if (order == null) return const ShopperActiveTasksScreen();
            return ShoppingChecklistScreen(order: order);
          },
        ),
        GoRoute(
          path: '/shopper/earnings',
          builder: (context, state) => const ShopperEarningsScreen(),
        ),
        GoRoute(
          path: '/shopper/profile',
          builder: (context, state) => const ShopperProfileScreen(),
        ),
        GoRoute(
          path: '/shopper/kyc',
          builder: (context, state) {
            final isRejected = state.uri.queryParameters['rejected'] == 'true';
            return ShopperKycScreen(isRejected: isRejected);
          },
        ),
        GoRoute(
          path: '/shopper/pending-approval',
          builder: (context, state) => const ShopperPendingApprovalScreen(),
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
  const CustomerMainShell({super.key, required this.child});

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
  const ShopperMainShell({super.key, required this.child});

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
  const RiderMainShell({super.key, required this.child});

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
  const AdminMainShell({super.key, required this.child});

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
