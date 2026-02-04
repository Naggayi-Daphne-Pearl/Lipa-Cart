# 🏗️ Single Application Architecture (One App, Multiple Roles)

## Why One App is Better Than Multiple Apps

| Feature | Separate Apps | One App ✅ |
|---------|---------------|----------|
| **Shared Backend** | All consume same API | Yes |
| **Code Duplication** | 80-90% same code | Zero duplication |
| **Maintenance** | Update 3-4 apps | Update 1 app |
| **Bug Fixes** | Fix in all places | Fix once |
| **Auth System** | Manage 3-4 auth flows | Single auth flow |
| **Database** | One DB (still) | Same DB |
| **User Switching** | Logout, switch app | Toggle in app |
| **Development Speed** | Slow (multiple codebases) | Fast (one codebase) |
| **Deployment** | 3-4 separate deployments | 1 deployment |
| **Testing** | 3-4 times work | Once |

**Verdict:** One app = simpler, faster, cheaper to build & maintain

---

## How It Works: The Architecture

### User Flow
```
User Opens App
       ↓
Not Logged In? → Login Screen
       ↓
Enter Email & Password
       ↓
Backend Validates
       ↓
Returns JWT Token + Role (customer/admin/rider/shopper)
       ↓
App Checks Role
       ↓
Shows Role-Specific Dashboard
  - Customer  → Browse products, Order
  - Admin     → Manage products, Users
  - Rider     → Accept deliveries
  - Shopper   → Browse shopper jobs
```

### Role Detection After Login
```json
{
  "jwt": "eyJhbGc...",
  "user": {
    "id": 1,
    "email": "john@example.com",
    "role": "customer"  ← App reads this
  }
}
```

The app says: "Oh, role is 'customer'? Show customer screens"

---

## Frontend Structure (One Codebase)

### Folder Organization
```
lib/
├── main.dart              ← Single entry point
├── models/
│   ├── user.dart
│   └── role.dart
├── providers/
│   ├── auth_provider.dart ← Manages login
│   └── role_provider.dart ← Stores current role
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── customer/
│   │   ├── home.dart
│   │   ├── cart.dart
│   │   └── orders.dart
│   ├── admin/
│   │   ├── dashboard.dart
│   │   ├── manage_products.dart
│   │   └── manage_users.dart
│   ├── rider/
│   │   ├── available_deliveries.dart
│   │   ├── active_deliveries.dart
│   │   └── earnings.dart
│   ├── shopper/
│   │   ├── available_jobs.dart
│   │   ├── active_jobs.dart
│   │   └── earnings.dart
│   └── shared/
│       ├── profile.dart
│       └── settings.dart
└── router/
    └── app_router.dart    ← Route based on role
```

### Example: Role-Based Navigation
```dart
// app_router.dart
GoRouter _createRouter() {
  return GoRouter(
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isLoggedIn = authProvider.isLoggedIn;
      final userRole = authProvider.user?.role;

      // Not logged in? Go to login
      if (!isLoggedIn) {
        return '/login';
      }

      // Logged in? Route based on role
      return switch(userRole) {
        'customer' => '/customer/home',
        'admin' => '/admin/dashboard',
        'rider' => '/rider/deliveries',
        'shopper' => '/shopper/jobs',
        _ => '/login',
      };
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(),
      ),
      
      // Customer routes
      GoRoute(
        path: '/customer/home',
        builder: (context, state) => CustomerHome(),
      ),
      GoRoute(
        path: '/customer/cart',
        builder: (context, state) => CartScreen(),
      ),
      
      // Admin routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/manage-products',
        builder: (context, state) => ManageProductsScreen(),
      ),
      
      // Rider routes
      GoRoute(
        path: '/rider/deliveries',
        builder: (context, state) => RiderDeliveriesScreen(),
      ),
      
      // Shopper routes
      GoRoute(
        path: '/shopper/jobs',
        builder: (context, state) => ShopperJobsScreen(),
      ),
    ],
  );
}
```

### Example: Conditional UI in Widgets
```dart
// In any screen
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    final userRole = authProvider.user?.role;

    // Show different UI based on role
    return switch(userRole) {
      'customer' => CustomerAppBar(),
      'admin' => AdminAppBar(),
      'rider' => RiderAppBar(),
      'shopper' => ShopperAppBar(),
      _ => SizedBox(),
    };
  },
);
```

---

## How Login Determines Everything

### Backend Returns Role
```
POST /api/auth/login
{
  "email": "john@example.com",
  "password": "password123"
}

RESPONSE:
{
  "jwt": "eyJhbGc...",
  "user": {
    "id": 1,
    "email": "john@example.com",
    "role": "customer"  ← THIS determines UI
  }
}
```

### Frontend Stores Role
```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _jwt;

  Future<void> login(String email, String password) async {
    final response = await api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    _user = User.fromJson(response['user']);  // role is inside
    _jwt = response['jwt'];
    
    notifyListeners();  // Triggers router to redirect
  }

  String? get userRole => _user?.role;
}
```

---

## Web vs Mobile: Same App, Same Roles

### Web (www.lipacart.com)
```
https://www.lipacart.com/
       ↓
Flutter Web App loads
       ↓
Login Screen
       ↓
User logs in as customer/admin/rider/shopper
       ↓
Same role-based UI as mobile
```

### Android (App Store)
```
User opens Lipa Cart app
       ↓
Same Flutter app
       ↓
Login Screen
       ↓
User logs in as customer/admin/rider/shopper
       ↓
Same role-based UI as web
```

### iOS (Future)
```
User opens Lipa Cart app
       ↓
Same Flutter app
       ↓
Same login, same role-based UI
```

**Both platforms use the exact same code!** ✅

---

## User Switching (Optional)

Want users to switch roles without logging out?

### Add Role Switcher
```dart
// In settings screen
ListTile(
  title: Text('Switch Role'),
  onTap: () {
    // If user has multiple roles, show a menu
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch Role'),
        content: Column(
          children: [
            'customer',
            'admin',
            'rider',
            'shopper',
          ]
          .map((role) => ListTile(
            title: Text(role),
            onTap: () {
              authProvider.switchRole(role);
              router.go('/$role/home');
            },
          ))
          .toList(),
        ),
      ),
    );
  },
),
```

**Backend:** User with multiple roles can switch via API (optional feature)

---

## Example Flow: One App, Four Users

### User 1: Customer
```
1. Opens app on phone or web
2. Sees login screen
3. Logs in with customer credentials
4. Backend returns: role: "customer"
5. App shows: Browse products, add to cart, checkout
6. URL (web): lipacart.com/customer/home
```

### User 2: Admin
```
1. Opens same app on phone or web
2. Sees login screen
3. Logs in with admin credentials
4. Backend returns: role: "admin"
5. App shows: Dashboard, manage products, manage users
6. URL (web): lipacart.com/admin/dashboard
```

### User 3: Rider
```
1. Opens same app on phone
2. Sees login screen
3. Logs in with rider credentials
4. Backend returns: role: "rider"
5. App shows: Available deliveries, active deliveries, earnings
6. URL (web): lipacart.com/rider/deliveries
```

### User 4: Shopper
```
1. Opens same app on phone or web
2. Sees login screen
3. Logs in with shopper credentials
4. Backend returns: role: "shopper"
5. App shows: Available jobs, active jobs, earnings
6. URL (web): lipacart.com/shopper/jobs
```

**Same app. Different UI. All powered by one codebase.** ✅

---

## API Endpoints Used By Each Role

### Customer Uses
```
GET  /api/categories
GET  /api/products
GET  /api/products/:id
POST /api/shopping-list
GET  /api/shopping-list
POST /api/cart
GET  /api/cart
POST /api/orders
GET  /api/orders
GET  /api/orders/:id
```

### Admin Uses
```
GET    /api/admin/products
POST   /api/admin/products
PATCH  /api/admin/products/:id
DELETE /api/admin/products/:id
GET    /api/admin/users
PATCH  /api/admin/users/:id
GET    /api/admin/analytics
```

### Rider Uses
```
GET    /api/deliveries/available
GET    /api/deliveries/active
PATCH  /api/deliveries/:id/status
GET    /api/deliveries/earnings
GET    /api/deliveries/rating
```

### Shopper Uses
```
GET    /api/shopping-jobs/available
GET    /api/shopping-jobs/active
PATCH  /api/shopping-jobs/:id/status
GET    /api/shopping-jobs/earnings
```

**Backend enforces permissions.** If a customer tries to access `/api/admin/users`, backend returns 403 Forbidden.

---

## Security: Backend Enforces Roles

### Token-Based Security
```
1. User logs in
2. Gets JWT token containing: { userId, role }
3. Token is sent with EVERY request
4. Backend checks:
   - Is token valid?
   - Does user have permission for this endpoint?
   - If role is "customer", can they delete products? NO
   - If role is "admin", can they delete products? YES
```

### Example: Middleware Check
```typescript
// Your backend middleware (already implemented ✓)
async (req, res, next) => {
  const userRole = req.state.user.role;
  
  // Only admins can delete products
  if (action === 'delete' && userRole !== 'admin') {
    return res.status(403).json({ message: 'Forbidden' });
  }
  
  next();
}
```

**Frontend cannot bypass this.** Even if you remove buttons, backend still checks. ✅

---

## MVP Timeline

### Phase 1: Customer + Web (Current)
- [ ] Customer login on web
- [ ] Browse products on web
- [ ] Add to cart & checkout
- [ ] View orders
- [ ] Launch: www.lipacart.com

### Phase 2: Customer + Android
- [ ] Same app on Android
- [ ] Same features
- [ ] Same backend

### Phase 3: Add Admin
- [ ] Admin login
- [ ] Admin dashboard (same app)
- [ ] Manage products
- [ ] Manage users
- [ ] No new app needed!

### Phase 4: Add Rider
- [ ] Rider login
- [ ] View deliveries (same app)
- [ ] Track earnings
- [ ] No new app needed!

### Phase 5: Add Shopper
- [ ] Shopper login
- [ ] View shopping jobs (same app)
- [ ] Track earnings
- [ ] No new app needed!

---

## File Structure for Web Deployment

```
www.lipacart.com
  ├── /              ← Redirects to login or home
  ├── /login         ← Login screen
  ├── /customer/     ← Customer area
  │   ├── home       ← Browse products
  │   ├── cart       ← Shopping cart
  │   └── orders     ← Order history
  ├── /admin/        ← Admin area (role-protected)
  │   ├── dashboard
  │   └── manage-products
  ├── /rider/        ← Rider area (role-protected)
  │   ├── deliveries
  │   └── earnings
  └── /shopper/      ← Shopper area (role-protected)
      ├── jobs
      └── earnings
```

All routes under `/admin`, `/rider`, `/shopper` are **protected by auth middleware**.

---

## How Role-Based Routing Works

### Before Login
```
User visits: https://www.lipacart.com/admin/dashboard
       ↓
App checks: Are you logged in?
       ↓
NO → Redirect to /login
       ↓
User logs in
       ↓
Token stored in localStorage
```

### After Login
```
User visits: https://www.lipacart.com/admin/dashboard
       ↓
App checks: Are you logged in?
       ↓
YES → Check role
       ↓
Role is "customer" but trying to access /admin?
       ↓
NO → Redirect to /customer/home
       ↓
Role is "admin"?
       ↓
YES → Show admin dashboard ✅
```

---

## State Management (Single Source of Truth)

### AuthProvider (stores role)
```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _jwt;

  String? get userRole => _user?.role;
  bool get isLoggedIn => _jwt != null;
  User? get user => _user;
}
```

### Usage Throughout App
```dart
// In any screen/widget:
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    // Access role from anywhere
    final role = auth.userRole;
    
    return role == 'admin' 
      ? AdminUI() 
      : CustomerUI();
  },
);
```

---

## Deployment Strategy

### Single Flutter Project
```
lipa_cart/
  ├── pubspec.yaml
  ├── lib/
  ├── web/        ← Web version (Flutter Web)
  ├── android/    ← Android version (Flutter Android)
  └── ios/        ← iOS version (Flutter iOS) - future
```

### Deploy Web
```bash
flutter build web
# Upload to www.lipacart.com
```

### Deploy Android
```bash
flutter build apk
# Upload to Google Play Store
```

### Deploy iOS (Future)
```bash
flutter build ios
# Upload to Apple App Store
```

**All from the same codebase!** ✅

---

## Cost Savings

### With Separate Apps
- App A (Customer): $X/month
- App B (Admin): $X/month
- App C (Rider): $X/month
- App D (Shopper): $X/month
- Total: $4X/month
- Developer time: 4x

### With One App ✅
- One App: $X/month
- Developer time: 1x
- **Savings: 75%**

---

## Summary: One App Works Because

1. ✅ **Same Backend** - All users consume same API
2. ✅ **Login Determines UI** - Role from token controls what user sees
3. ✅ **Role-Based Routes** - Router redirects based on role
4. ✅ **Role-Based Widgets** - Screens show/hide UI based on role
5. ✅ **Security at Backend** - Backend enforces permissions
6. ✅ **Web + Mobile** - Same app on all platforms
7. ✅ **Easy to Update** - Fix once, deploy once
8. ✅ **Easy to Scale** - Add new roles without new apps

---

## Ready to Build?

Your structure is:

```
1 Backend (Strapi)
  ↓
1 Database (PostgreSQL)
  ↓
1 Frontend (Flutter)
  ├─ Web: www.lipacart.com
  └─ Android: Lipa Cart App
```

**That's it!** Everything else flows from this. 🚀

Next: Set up the Flutter routing & role-based UI.

