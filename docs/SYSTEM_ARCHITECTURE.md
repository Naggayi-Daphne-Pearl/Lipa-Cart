# Lipa Cart - Complete System Architecture

## 🏗️ Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                         │
│                   (Flutter Mobile App)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐   │
│  │   AUTH      │  │  CUSTOMER    │  │   SHOPPER/RIDER     │   │
│  │  SCREENS    │  │   SCREENS    │  │    SCREENS (TODO)   │   │
│  ├─────────────┤  ├──────────────┤  ├─────────────────────┤   │
│  │ • Login     │  │ • Home       │  │ • Dashboard         │   │
│  │ • Register  │  │ • Browse     │  │ • Assigned Work     │   │
│  │ • OTP       │  │ • Addresses  │  │ • Earnings          │   │
│  │ • Splash    │  │ • Orders     │  │ • Profile           │   │
│  │             │  │ • Cart       │  │ • Rating            │   │
│  │             │  │ • Checkout   │  │                     │   │
│  └─────────────┘  └──────────────┘  └─────────────────────┘   │
│                          ⬇️                                     │
│          Role-Based Router (GoRouter)                          │
│          Dynamic routing based on user.user_type               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                          │
│              (State Management & Services)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐  ┌──────────────────────────────┐    │
│  │   STATE MANAGEMENT  │  │      API SERVICES            │    │
│  │    (Provider)       │  │  (HTTP + Token Auth)         │    │
│  ├─────────────────────┤  ├──────────────────────────────┤    │
│  │ AuthProvider        │  │ AuthService                  │    │
│  │ ProductProvider     │  │ ProductService              │    │
│  │ CartProvider        │  │ OrderService                │    │
│  │ OrderProvider       │  │ AddressService              │    │
│  │ ShoppingListProvider│  │ PaymentService              │    │
│  │ RecipeProvider      │  │ RatingService               │    │
│  └─────────────────────┘  └──────────────────────────────┘    │
│                                                                 │
│              Models: User, Product, Order, Address, etc.       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      DATA LAYER                                 │
│              (Backend API & Database)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────┐  ┌──────────────────────────────┐      │
│  │  STRAPI BACKEND   │  │  POSTGRESQL DATABASE         │      │
│  │   (Node.js)       │  │                              │      │
│  ├───────────────────┤  ├──────────────────────────────┤      │
│  │ Auth API          │  │ Core Tables                  │      │
│  │ Users API         │  │ • users                      │      │
│  │ Products API      │  │ • customers                  │      │
│  │ Orders API        │  │ • shoppers                   │      │
│  │ Payments API      │  │ • riders                     │      │
│  │ Ratings API       │  │ • admins                     │      │
│  │ RBAC Middleware   │  │                              │      │
│  │                   │  │ Transaction Tables           │      │
│  │ (142+ Permissions)│  │ • orders                     │      │
│  │ (4 Roles)         │  │ • order_items                │      │
│  │                   │  │ • payments                   │      │
│  │                   │  │                              │      │
│  │                   │  │ Master Data                  │      │
│  │                   │  │ • products                   │      │
│  │                   │  │ • categories                 │      │
│  │                   │  │ • promo_codes                │      │
│  │                   │  │                              │      │
│  │                   │  │ Logistics Tables             │      │
│  │                   │  │ • addresses                  │      │
│  │                   │  │ • rider_locations            │      │
│  │                   │  │ • ratings                    │      │
│  └───────────────────┘  └──────────────────────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Customer Journey - Data Flow

```
START (Splash Screen)
    ⬇️
[Login/Register]
    ⬇️ AuthService.login() / AuthService.register()
    ⬇️ POST /api/auth/local
    ⬇️ Receive JWT Token + User Role
    ⬇️ Create Custom User Profile
    ⬇️ Store in AuthProvider
    ⬇️ RoleBasedRouter renders Customer Navigation
    ⬇️
[HOME SCREEN]
  📍 Show welcome message
  📍 Load addresses
  📍 Show featured categories
    ⬇️
[BROWSE PRODUCTS]
  📍 View categories (ProductService.getCategories())
  📍 View products (ProductService.getProducts(categoryId))
  📍 View product details
  📍 Add to cart (CartProvider.addItem())
    ⬇️
[MANAGE CART]
  📍 Update quantities
  📍 Remove items
  📍 View total
    ⬇️
[CHECKOUT]
  📍 Select delivery address (AddressService.getAddresses())
  📍 View pricing breakdown
  📍 Apply promo code (optional)
    ⬇️
[PAYMENT]
  📍 Initiate payment (PaymentService.processPayment())
  📍 Handle payment response
    ⬇️
[ORDER CONFIRMATION]
  📍 OrderService.createOrder()
  📍 POST /api/orders
  📍 Receive order ID
    ⬇️
[ORDER TRACKING]
  📍 OrderService.getOrder(orderId)
  📍 View order status progression
  📍 Real-time updates (polling or WebSocket - TODO)
  📍 View shopper/rider info
    ⬇️
[DELIVERED]
  📍 OrderService.getOrder()
  📍 Show rating screen
  📍 RatingService.createRating()
    ⬇️
END (Order Complete)
```

---

## 🛡️ Authentication & Authorization

```
┌─────────────────┐
│   User Inputs   │
│  Phone + Pass   │
└────────┬────────┘
         ⬇️
┌─────────────────────────────────────┐
│  AuthService.login()                │
│  POST /api/auth/local               │
└────────┬────────────────────────────┘
         ⬇️
┌─────────────────────────────────────┐
│  Strapi Auth User Created           │
│  • JWT Token Generated              │
│  • Role Assigned (Customer)         │
│  • Permissions Loaded               │
└────────┬────────────────────────────┘
         ⬇️
┌─────────────────────────────────────┐
│  Custom User Profile Created        │
│  POST /api/users                    │
│  POST /api/customers                │
└────────┬────────────────────────────┘
         ⬇️
┌─────────────────────────────────────┐
│  AuthProvider Stores:               │
│  • Token (JWT)                      │
│  • User Info (phone, name, type)    │
│  • User Type (customer)             │
└────────┬────────────────────────────┘
         ⬇️
┌─────────────────────────────────────┐
│  RoleBasedRouter Activated          │
│  Renders: CustomerNavigation        │
└─────────────────────────────────────┘

API Request with Auth:
┌─────────────────────────────────────┐
│  GET /api/orders                    │
│  Headers: {                         │
│    Authorization: "Bearer {token}"  │
│    Content-Type: application/json   │
│  }                                  │
└────────┬────────────────────────────┘
         ⬇️
┌─────────────────────────────────────┐
│  Strapi Middleware Validates:       │
│  1. Token is valid                  │
│  2. User has 'customers.find'       │
│     permission                      │
│  3. Returns only user's data        │
└────────┬────────────────────────────┘
         ⬇️
┌─────────────────────────────────────┐
│  Response with filtered data        │
└─────────────────────────────────────┘
```

---

## 📊 Database Schema Relationships

```
USERS (Base User)
├── id (Primary Key)
├── phone (Unique)
├── email
├── name
├── user_type (customer|shopper|rider|admin)
├── is_active
│
├── 1:1 ─→ CUSTOMERS (if user_type = 'customer')
│   ├── total_orders
│   ├── referral_code
│   └── referred_by (self-reference)
│
├── 1:1 ─→ SHOPPERS (if user_type = 'shopper')
│   ├── market_location
│   ├── rating
│   └── earnings
│
├── 1:1 ─→ RIDERS (if user_type = 'rider')
│   ├── vehicle_type
│   ├── is_online
│   ├── gps_current
│   └── earnings
│
├── 1:1 ─→ ADMINS (if user_type = 'admin')
│   ├── role (super_admin|admin|support)
│   └── permissions (JSONB)
│
└── 1:N ─→ ADDRESSES
    ├── label
    ├── address_line
    ├── city
    ├── gps (lat/lng)
    └── is_default

ORDERS (Customer Order)
├── id
├── order_number (Unique)
├── customer_id (FK → CUSTOMERS)
├── shopper_id (FK → SHOPPERS) [assigned later]
├── rider_id (FK → RIDERS) [assigned later]
├── delivery_address_id (FK → ADDRESSES)
├── status (pending → delivered)
├── subtotal
├── service_fee
├── delivery_fee
├── discount
├── total
│
├── 1:N ─→ ORDER_ITEMS
│   ├── product_id
│   ├── quantity
│   ├── estimated_price
│   ├── actual_price
│   └── found (bool)
│
├── 1:1 ─→ PAYMENTS
│   ├── amount
│   ├── method
│   ├── status
│   └── transaction_id
│
└── 1:N ─→ RATINGS
    ├── rating_value
    ├── comment
    └── rater_id

PRODUCTS
├── id
├── name
├── category_id (FK → CATEGORIES)
├── price
├── image_url
└── description

CATEGORIES
├── id
├── name
└── 1:N ─→ SUBCATEGORIES
    └── 1:N ─→ PRODUCTS
```

---

## 🔐 Role-Based Permission Matrix

| Feature | Customer | Shopper | Rider | Admin |
|---------|----------|---------|-------|-------|
| **Browse Catalog** | ✅ | ✅ | ✅ | ✅ |
| **Manage Cart** | ✅ | ❌ | ❌ | ❌ |
| **Place Orders** | ✅ | ❌ | ❌ | ❌ |
| **View Own Orders** | ✅ | ❌ | ❌ | ✅ |
| **Manage Addresses** | ✅ | ❌ | ❌ | ❌ |
| **Assigned Orders** | ❌ | ✅ | ✅ | ❌ |
| **Update Items** | ❌ | ✅ | ❌ | ❌ |
| **Track Delivery** | ✅ | ✅ | ✅ | ✅ |
| **Rate Orders** | ✅ | ❌ | ❌ | ❌ |
| **View Earnings** | ❌ | ✅ | ✅ | ❌ |
| **Manage All Users** | ❌ | ❌ | ❌ | ✅ |
| **Manage Products** | ❌ | ❌ | ❌ | ✅ |
| **View Analytics** | ❌ | ❌ | ❌ | ✅ |

---

## 📱 UI Component Hierarchy

```
LipaCartApp (MaterialApp)
├── MultiProvider (6 Providers)
│   ├── AuthProvider
│   ├── ProductProvider
│   ├── CartProvider
│   ├── OrderProvider
│   ├── ShoppingListProvider
│   └── RecipeProvider
│
└── RoleBasedRouter
    ├── CustomerNavigation
    │   ├── CustomerMainShell (BottomNavigationBar)
    │   │   ├── CustomerHomeScreen
    │   │   │   ├── WelcomeBanner
    │   │   │   ├── DeliveryAddressCard
    │   │   │   ├── CategoriesGrid
    │   │   │   └── RecentOrdersList
    │   │   │
    │   │   ├── AddressesScreen
    │   │   │   ├── AddressCard x N
    │   │   │   ├── AddressForm (BottomSheet)
    │   │   │   └── AddNewButton
    │   │   │
    │   │   ├── OrdersScreen
    │   │   │   ├── OrderCard x N
    │   │   │   │   ├── OrderNumber
    │   │   │   │   ├── StatusBadge
    │   │   │   │   └── Total
    │   │   │   └── EmptyState
    │   │   │
    │   │   ├── OrderDetailScreen
    │   │   │   ├── OrderStatusHeader
    │   │   │   ├── OrderItemsList
    │   │   │   ├── DeliveryAddress
    │   │   │   ├── ShopperCard
    │   │   │   ├── RiderCard
    │   │   │   ├── PriceBreakdown
    │   │   │   ├── RatingDialog
    │   │   │   └── CancelButton
    │   │   │
    │   │   └── ProfileScreen
    │   │       └── (TODO)
    │   │
    │   ├── CategoriesScreen (TODO)
    │   ├── CategoryProductsScreen (TODO)
    │   ├── ProductDetailScreen (TODO)
    │   ├── CartScreen (TODO)
    │   └── CheckoutScreen (TODO)
    │
    ├── ShopperNavigation (TODO)
    ├── RiderNavigation (TODO)
    └── AdminNavigation (TODO)
```

---

## 🔌 API Communication Pattern

```
┌──────────────────────────────────────────────┐
│          Flutter Widget                      │
│  (e.g., AddressesScreen)                     │
└────────────┬─────────────────────────────────┘
             ⬇️ context.read<AddressService>()
┌──────────────────────────────────────────────┐
│          Service Class                       │
│  (AddressService extends ChangeNotifier)     │
├──────────────────────────────────────────────┤
│ Methods:                                     │
│ • fetchAddresses(token, userId)              │
│ • createAddress({params})                    │
│ • updateAddress({params})                    │
│ • deleteAddress(token, id)                   │
│ • setDefaultAddress(token, id)               │
│                                              │
│ State:                                       │
│ • _addresses: List<Address>                  │
│ • _defaultAddress: Address?                  │
│ • _isLoading: bool                           │
│ • _error: String?                            │
└────────────┬─────────────────────────────────┘
             ⬇️ http.get/post/put/delete
┌──────────────────────────────────────────────┐
│       HTTP Client (dart:io http)             │
│  • Adds Authorization header                 │
│  • Serializes/deserializes JSON              │
│  • Handles response codes                    │
└────────────┬─────────────────────────────────┘
             ⬇️ HTTP Request over network
┌──────────────────────────────────────────────┐
│    Strapi Backend (http://localhost:1337)    │
│                                              │
│  POST /api/addresses                         │
│  GET /api/addresses?filters=...              │
│  PUT /api/addresses/:id                      │
│  DELETE /api/addresses/:id                   │
└────────────┬─────────────────────────────────┘
             ⬇️ Query/Validate/Execute
┌──────────────────────────────────────────────┐
│    PostgreSQL Database                       │
│                                              │
│  SELECT * FROM addresses WHERE user_id = ?  │
│  INSERT INTO addresses ...                   │
│  UPDATE addresses SET ... WHERE id = ?       │
│  DELETE FROM addresses WHERE id = ?          │
└──────────────────────────────────────────────┘
             ⬇️ Response
┌──────────────────────────────────────────────┐
│    JSON Response back through layers         │
│  Parsed → Model → Service → Widget           │
└──────────────────────────────────────────────┘
             ⬇️ Consumer rebuilds UI
┌──────────────────────────────────────────────┐
│          Flutter Widget Re-renders           │
│    with new Address data                     │
└──────────────────────────────────────────────┘
```

---

## ⚙️ Development Environment Setup

```
Development Machine
├── Backend (Strapi)
│   └── http://localhost:1337
│       ├── Admin: http://localhost:1337/admin
│       ├── API: http://localhost:1337/api
│       └── Database: PostgreSQL on localhost:5432
│
└── Frontend (Flutter)
    ├── iOS Simulator
    │   └── Connects to localhost:1337
    ├── Android Emulator
    │   └── Connects to 10.0.2.2:1337 (Android emulator host mapping)
    └── Web Browser (Flutter Web)
        └── http://localhost:5000

API Testing Tools
├── Postman
│   └── /postman/Lipa-Cart-API-Complete.postman_collection.json
├── cURL
│   └── curl -H "Authorization: Bearer {token}" http://localhost:1337/api/orders
└── Browser DevTools
    └── Network tab for checking requests
```

---

## 🎯 Success Criteria

- [ ] User can authenticate (login/register)
- [ ] User can browse products by category
- [ ] User can add items to cart
- [ ] User can manage delivery addresses (CRUD)
- [ ] User can place orders
- [ ] User can view order history
- [ ] User can track orders in real-time
- [ ] User can cancel pending orders
- [ ] User can rate delivered orders
- [ ] All 40 customer permissions work
- [ ] Role-based navigation works correctly
- [ ] API integration 100% complete
- [ ] Error handling graceful
- [ ] Performance acceptable (< 2s per request)
- [ ] Code is well-documented
- [ ] No crashes on happy path

---

**This architecture provides a scalable, maintainable, and user-friendly multi-role delivery platform!** 🚀
