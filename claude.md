# Lipa-Cart

**Fresh groceries delivered to your doorstep**

Lipa-Cart is a full-featured grocery delivery application built with Flutter targeting mobile and web platforms. The app connects customers with personal shoppers and delivery riders for convenient grocery shopping in East Africa (Uganda/Kenya).

## Core Features

### User Authentication
- Phone number-based OTP login (+256 Uganda format)
- User profile management (name, email, profile image)
- Multiple delivery address support with default selection

### Product Catalog
- Browse products across 6+ categories (Vegetables, Fruits, Meat & Fish, Dairy, Pantry, Beverages)
- Featured products highlighting
- Full-text search across products
- Product details with images, pricing, ratings, and availability
- Discount system with original vs. sale price

### Shopping Cart
- Add/remove items with quantity management
- Special instructions per item
- Dynamic pricing: subtotal + service fee (5%) + delivery fee
- Free delivery threshold: 50,000 UGX

### Orders & Checkout
- Delivery address selection
- Payment methods: Mobile Money, Card, Cash on Delivery
- Order tracking through 7 status stages:
  - Pending → Confirmed → Shopping → Ready for Delivery → In Transit → Delivered
- Personal shopper and rider assignment
- Order history (active and past orders)
- Order cancellation with reason

### Shopping Lists
- Create custom lists with names, descriptions, emojis, and colors
- List items with quantities, units, budget amounts, and notes
- Link items to actual products for quick purchase
- Progress tracking with check-off functionality

### Recipe Discovery
- Recipe catalog with East African and international cuisines
- Recipe details: prep/cook time, servings, difficulty, instructions
- Ingredient lists linked to purchasable products
- Estimated cost calculation from ingredients
- Favorite/bookmark recipes
- Filter by tags (Quick, Vegetarian, Kenyan, etc.)

## Tech Stack

- **Framework**: Flutter 3.29+ (Dart SDK ^3.9.2)
- **State Management**: Provider (ChangeNotifier pattern)
- **UI**: Material Design 3 with custom theme
- **Icons**: Iconsax
- **Images**: Cached Network Image
- **Routing**: GoRouter

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   ├── theme.dart           # App theme and colors
│   └── routes.dart          # Navigation routes
├── models/                   # Data models
│   ├── user.dart
│   ├── product.dart
│   ├── category.dart
│   ├── cart_item.dart
│   ├── order.dart
│   ├── address.dart
│   ├── shopping_list.dart
│   └── recipe.dart
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   ├── cart_provider.dart
│   ├── order_provider.dart
│   ├── shopping_list_provider.dart
│   └── recipe_provider.dart
├── screens/                 # UI screens
│   ├── auth/               # Login, OTP, Onboarding
│   ├── home/               # Home screen
│   ├── browse/             # Product browsing
│   ├── cart/               # Shopping cart
│   ├── checkout/           # Checkout flow
│   ├── orders/             # Order management
│   ├── profile/            # User profile
│   ├── lists/              # Shopping lists
│   └── recipes/            # Recipe discovery
├── widgets/                 # Reusable components
└── utils/                   # Helpers and utilities
    ├── formatters.dart     # Currency, date formatting
    ├── validators.dart     # Input validation
    └── responsive.dart     # Responsive design helpers
```

## Currency & Localization

- **Currency**: UGX (Uganda Shilling)
- **Phone Format**: +256 (Uganda)
- **Region**: East Africa (Uganda, Kenya focus)

## Deployment

- **Web**: Vercel (via GitHub Actions)
- **Mobile**: Android APK / iOS (Flutter build)

## Backend Requirements

The app currently uses mock data and requires a backend API for:
- User authentication (OTP service)
- Product catalog management
- Order processing and tracking
- Shopping list sync
- Recipe management
- Payment integration (Mobile Money, Cards)
- Real-time order status updates
- Shopper/Rider assignment and tracking
