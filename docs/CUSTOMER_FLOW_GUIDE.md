# Lipa Cart Frontend - Customer Flow Implementation Guide

## 📋 Architecture Overview

### Single App with Role-Based Navigation ✅

**Why NOT three separate apps:**
- ❌ Code duplication (auth, models, services repeated 3x)
- ❌ 3x maintenance burden
- ❌ Users download 3 apps instead of 1
- ❌ Cannot seamlessly switch between roles
- ❌ Fragmented features and bug fixes

**Why ONE app with role-based routing:**
- ✅ Shared codebase, shared components
- ✅ Single deployment pipeline
- ✅ Users can switch roles in-app
- ✅ Consistent UI/UX across roles
- ✅ Unified backend integration

---

## 🏗️ Current Implementation Status

### ✅ Completed

1. **Role-Based Router** (`lib/role_based_router.dart`)
   - Dynamic routing based on `user.user_type` from auth
   - Separate navigation trees for: Customer, Shopper, Rider, Admin
   - Shell routes with bottom navigation per role
   - Role guards using `GoRouter`

2. **Authentication Service** (`lib/services/auth_service.dart`)
   - Login with phone & password
   - Register with automatic customer profile creation
   - Current user retrieval
   - Logout
   - Token management

3. **Customer Screens**
   - `CustomerHomeScreen` - Browse catalog, view addresses, recent orders
   - `AddressesScreen` - CRUD delivery addresses
   - `OrdersScreen` - View all orders with status filtering
   - `OrderDetailScreen` - Full order details with tracking, shopper/rider info, rating

4. **Address Service** (`lib/services/address_service.dart`)
   - Fetch user's addresses
   - Create/Update/Delete addresses
   - Set default address
   - Full address model with GPS support

5. **Order Service** (`lib/services/order_service.dart`)
   - Fetch customer orders
   - Get single order details
   - Create new order
   - Cancel pending orders
   - Order status tracking

### 🚧 In Progress

6. **Product/Category Service** (TODO)
   - Fetch categories and subcategories
   - Fetch products by category
   - Search products
   - Get product details

7. **Cart Management** (TODO)
   - Add items to cart
   - Update quantities
   - Remove items
   - Cart persistence

8. **Order Placement Flow** (TODO)
   - Add items from cart to order
   - Select delivery address
   - Apply promo codes
   - Process payment
   - Confirm order

---

## 🎯 Customer Capabilities (40 Permissions)

### Browse & Search
- ✅ View all categories
- ✅ View products in category
- ✅ View product details
- ⏳ Search products by name
- ⏳ Filter by price/rating
- ⏳ View recipes and shopping lists

### Account Management
- ✅ View own profile
- ⏳ Edit profile (name, phone, photo)
- ✅ Create delivery addresses
- ✅ Update delivery addresses
- ✅ Delete delivery addresses
- ✅ Set default address

### Orders & Payments
- ✅ Create orders
- ✅ View order history
- ✅ View order details with tracking
- ✅ Cancel pending orders
- ⏳ Track order in real-time
- ⏳ Pay for orders
- ⏳ Apply promo codes

### Ratings & Reviews
- ✅ Rate delivered orders
- ⏳ Write reviews for orders
- ⏳ Rate shoppers and riders
- ⏳ View ratings/reviews

---

## 📁 Project Structure

```
lib/
├── role_based_router.dart          # Dynamic routing (role-based)
├── services/
│   ├── auth_service.dart           # Login/Register/Logout
│   ├── address_service.dart        # Address CRUD
│   ├── order_service.dart          # Order operations
│   ├── product_service.dart        # (TODO) Categories/Products
│   ├── cart_service.dart           # (TODO) Cart management
│   └── payment_service.dart        # (TODO) Payment processing
├── models/
│   ├── user.dart                   # User & Customer models
│   ├── address.dart                # Address model
│   ├── order.dart                  # Order model
│   ├── product.dart                # (TODO) Product model
│   ├── category.dart               # (TODO) Category model
│   └── cart_item.dart              # (TODO) Cart item model
└── screens/
    ├── auth/                       # (TODO) Auth screens
    ├── customer/                   # Customer role screens
    │   ├── customer_home_screen.dart
    │   ├── addresses_screen.dart
    │   ├── orders_screen.dart
    │   └── order_detail_screen.dart
    ├── shopper/                    # (TODO) Shopper role screens
    ├── rider/                      # (TODO) Rider role screens
    └── admin/                      # (TODO) Admin role screens
```

---

## 🔌 API Integration

### Base URL
```dart
const String baseUrl = 'http://localhost:1337'; // Development
const String baseUrl = 'https://api.lipacart.com'; // Production
```

### Authentication Flow

```
1. User enters phone & password on LoginScreen
2. POST /api/auth/local
   - Receive JWT token
   - Receive Strapi auth user with role
3. POST /api/users
   - Create custom user profile (phone, name, user_type)
4. POST /api/customers
   - Create customer profile (linked to user)
5. AuthProvider stores token & user info
6. RoleBasedRouter renders Customer navigation
```

### Key Endpoints Used

#### User Management
```
POST   /api/auth/local              # Login
POST   /api/auth/local/register     # Register
GET    /api/users/me                # Current user
GET    /api/users/:id               # User details
PUT    /api/users/:id               # Update profile
```

#### Addresses
```
GET    /api/addresses?filters[user][id][$eq]={userId}
POST   /api/addresses
PUT    /api/addresses/:id
DELETE /api/addresses/:id
```

#### Orders
```
GET    /api/orders?filters[customer][id][$eq]={customerId}&sort=createdAt:desc
GET    /api/orders/:id?populate[order_items][populate]=*&populate[delivery_address]=*
POST   /api/orders
PUT    /api/orders/:id               # Update status
```

#### Products (TODO)
```
GET    /api/categories
GET    /api/categories/:id/subcategories
GET    /api/products?filters[category]...
GET    /api/products/:id
```

---

## 🚀 Next Steps (Priority Order)

### Phase 1: Core Customer Flow ⭐
1. **Authentication**
   - [ ] Create LoginScreen with phone input
   - [ ] Create RegisterScreen with name/phone/password
   - [ ] Implement OTP verification (optional)
   - [ ] Add token persistence (SharedPreferences)
   - [ ] Add auto-login on app start

2. **Products & Browsing**
   - [ ] Create ProductService for catalog endpoints
   - [ ] Create CategoryModel and ProductModel
   - [ ] Create CategoriesScreen (grid of categories)
   - [ ] Create CategoryProductsScreen (list of products)
   - [ ] Create ProductDetailScreen (with add to cart)
   - [ ] Create SearchScreen (search products)

3. **Cart Management**
   - [ ] Create CartService for cart state
   - [ ] Create CartItem model
   - [ ] Create CartProvider with Provider pattern
   - [ ] Implement add/remove/update quantity in cart
   - [ ] Persist cart locally with SharedPreferences

### Phase 2: Order Placement
4. **Checkout Flow**
   - [ ] Create CheckoutScreen (review cart + select address)
   - [ ] Integrate address selection
   - [ ] Calculate fees (service + delivery)
   - [ ] Apply promo codes
   - [ ] Create PaymentScreen (payment gateway integration)
   - [ ] Implement order creation API call

### Phase 3: Order Tracking & Rating
5. **Order Management**
   - [ ] Enhance OrderDetailScreen with real-time updates
   - [ ] Add live location tracking (map integration)
   - [ ] Show shopper info with contact button
   - [ ] Show rider info with live tracking
   - [ ] Create RatingScreen with star/text review
   - [ ] Add notification for order status changes

### Phase 4: Additional Features
6. **Shopping Lists & Recipes**
   - [ ] Create ShoppingListProvider
   - [ ] Create RecipeScreen with shopping list conversion
   - [ ] Save lists for reordering

---

## 💡 Key Implementation Tips

### 1. Update main.dart to use RoleBasedRouter

```dart
// lib/main.dart
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/address_service.dart';
import 'services/order_service.dart';
import 'role_based_router.dart';

void main() async {
  await Future.delayed(Duration.zero); // Initialize SharedPreferences if needed
  runApp(const LipaCartApp());
}

class LipaCartApp extends StatelessWidget {
  const LipaCartApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AddressService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        // Add other services as needed
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'Lipa Cart',
            theme: ThemeData(
              primarySwatch: Colors.green,
              useMaterial3: true,
            ),
            routerConfig: RoleBasedRouter.getRouter(auth),
          );
        },
      ),
    );
  }
}
```

### 2. Use AuthService to Access Auth State

```dart
// In any screen:
final auth = context.read<AuthService>();
print('User: ${auth.user?.name}');
print('Type: ${auth.userType}');
print('Token: ${auth.token}');

// Or listen to changes:
Consumer<AuthService>(
  builder: (context, auth, _) {
    if (!auth.isAuthenticated) {
      return LoginScreen();
    }
    return HomeScreen();
  },
)
```

### 3. Handle Loading & Error States

```dart
Consumer<OrderService>(
  builder: (context, orderService, _) {
    if (orderService.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (orderService.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${orderService.error}'),
            ElevatedButton(
              onPressed: () => _retry(),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(/* render data */);
  },
)
```

### 4. Navigation Between Roles (if needed)

```dart
// Switch role after logging in
final auth = context.read<AuthService>();
auth.user = userWithNewRole;
auth.notifyListeners(); // Triggers router rebuild

// GoRouter will automatically switch to correct role's navigation
```

---

## 📊 API Response Examples

### User Login Response
```json
{
  "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "0712345678",
    "email": "customer@example.com",
    "role": {
      "id": 1,
      "name": "Customer"
    }
  }
}
```

### User Profile Response
```json
{
  "data": {
    "id": 1,
    "phone": "0712345678",
    "name": "John Doe",
    "user_type": "customer",
    "profile_photo_url": null,
    "is_active": true,
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

### Order List Response
```json
{
  "data": [
    {
      "id": 101,
      "order_number": "ORD-20240115-001",
      "customer": 1,
      "status": "delivered",
      "subtotal": 5500,
      "service_fee": 500,
      "delivery_fee": 200,
      "total": 6200,
      "createdAt": "2024-01-15T14:20:00Z",
      "order_items": [...]
    }
  ]
}
```

---

## 🧪 Testing Checklist

- [ ] Login with phone & password
- [ ] Auto-login with stored token
- [ ] Register new customer account
- [ ] Create delivery address
- [ ] Edit delivery address
- [ ] Delete delivery address
- [ ] Set default address
- [ ] View all orders
- [ ] View order details
- [ ] Cancel pending order
- [ ] Rate delivered order
- [ ] Navigate between app screens
- [ ] Handle API errors gracefully
- [ ] Persist token after app restart

---

## 📝 Configuration

### Update pubspec.yaml (if needed)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2          # ✅ State management
  go_router: ^14.6.2        # ✅ Navigation
  http: ^1.2.0              # ✅ API calls
  shared_preferences: ^2.0  # For token persistence
  intl: ^0.18.0             # Date formatting
  uuid: ^4.0.0              # Generate order IDs
  cached_network_image: ^3.3.0  # Image caching
  flutter_svg: ^2.0.0       # SVG support
```

Run: `flutter pub get`

---

## 🔒 Security Notes

1. **Never store sensitive data unencrypted**
   - Use `flutter_secure_storage` for tokens instead of SharedPreferences for production

2. **HTTPS only in production**
   - Update baseUrl to HTTPS URLs
   - Implement certificate pinning

3. **Token refresh**
   - Implement token refresh before expiry
   - Handle 401 unauthorized errors

4. **Input validation**
   - Validate phone numbers format
   - Sanitize user input

---

## 🤝 Integration with Backend

All services are ready to connect to your Strapi backend at `http://localhost:1337`.

**Backend Status:**
- ✅ All 4 roles configured (Customer, Shopper, Rider, Admin)
- ✅ 142+ permissions defined
- ✅ All API endpoints documented in Postman
- ✅ Database schema complete (18 tables)

**Frontend Next Steps:**
- Implement remaining screens
- Add product/category services
- Add payment integration
- Add real-time order tracking
- Add push notifications

---

## 📞 Support

For questions about:
- **API Endpoints**: Check `/postman/Lipa-Cart-API-Complete.postman_collection.json`
- **Database Schema**: Check `/database/schema.sql` and `/database/ERD.md`
- **Role Permissions**: Check `/documentation/RBAC-QUICK-REFERENCE.md`
- **Backend Setup**: Check `/documentation/CLAUDE.md`

Good luck with the implementation! 🚀
