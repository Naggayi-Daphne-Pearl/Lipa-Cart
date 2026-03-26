# LipaCart

A mobile-first grocery shopping and delivery platform built with Flutter. LipaCart connects customers with personal shoppers at local markets and boda boda delivery riders for fresh groceries delivered to your doorstep.

## Features

- **Phone Authentication** - Quick registration with OTP verification
- **Guest Browsing** - Browse and add items to cart without authentication
- **Checkout Authentication** - Sign in required at checkout for secure order placement
- **Product Browsing** - Browse categories, search products, view featured items
- **Shopping Cart** - Add items, adjust quantities, special instructions
- **Multiple Payment Options** - Mobile Money, Card, Cash on Delivery
- **Real-time Order Tracking** - Track orders from shopping to delivery
- **Order History** - View past orders and reorder easily

## User Flow

### Order Journey

1. **Browse & Shop** - Users can browse products, search, and add items to cart without authentication
2. **Review Cart** - View cart items, adjust quantities, and see order summary
3. **Checkout Authentication** - When proceeding to checkout, users are prompted to sign in/login if not already authenticated
4. **Complete Order** - After authentication, users can select delivery address, payment method, and place their order
5. **Track Delivery** - Monitor order status from shopping to delivery

This flow allows users to explore products freely while ensuring secure, authenticated checkouts.

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK (3.9.2 or higher)
- iOS Simulator / Android Emulator or physical device

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/lipa-cart.git
   cd lipa-cart
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure environment variables

   Copy the example file and fill in your values:
   ```bash
   cp .env.example .env
   ```

   | Variable | Description | Default |
   |----------|-------------|---------|
   | `API_BASE_URL` | Backend API base URL (no trailing slash) | `http://localhost:1337` |
   | `SENTRY_DSN` | Sentry error tracking DSN | *(empty — Sentry disabled)* |
   | `SENTRY_ENV` | Sentry environment tag | `development` |
   | `IMGBB_API_KEY` | ImgBB API key for image uploads | *(empty)* |

   Pass them via `--dart-define` when running:
   ```bash
   flutter run -d chrome \
     --dart-define=API_BASE_URL=http://localhost:1337 \
     --dart-define=SENTRY_DSN=https://your-key@sentry.io/123 \
     --dart-define=IMGBB_API_KEY=your_key
   ```

   Or run with defaults (localhost, no Sentry):
   ```bash
   flutter run
   ```

4. **CI/CD (GitHub Actions)** — Add these as repository secrets:
   - `API_BASE_URL` — production backend URL
   - `SENTRY_DSN` — Sentry DSN from your project settings
   - `IMGBB_API_KEY` — ImgBB API key

   These are automatically passed as `--dart-define` flags during the Vercel web build.

### Demo Login

Use any phone number and OTP code `123456` to log in.

## Project Structure

```
lib/
├── app_router.dart          # Navigation routes
├── main.dart                # App entry point
├── core/
│   ├── constants/           # App constants and sizes
│   ├── theme/               # Colors, typography, theme data
│   └── utils/               # Formatters and validators
├── models/                  # Data models
│   ├── user.dart
│   ├── product.dart
│   ├── category.dart
│   ├── cart_item.dart
│   └── order.dart
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   ├── cart_provider.dart
│   └── order_provider.dart
├── screens/                 # UI screens
│   ├── splash/
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── categories/
│   ├── product/
│   ├── cart/
│   ├── checkout/
│   ├── orders/
│   └── profile/
└── widgets/                 # Reusable components
    ├── custom_button.dart
    ├── product_card.dart
    ├── category_card.dart
    ├── cart_item_card.dart
    └── search_bar_widget.dart
```

## Tech Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Navigation**: Named routes with custom transitions
- **UI Components**: Custom widgets with Material Design 3
- **Icons**: Iconsax

## Design System

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Orange | `#FF8C00` | Buttons, highlights, CTAs |
| Primary Green | `#2ECC71` | Success states, fresh indicators |
| Text Dark | `#2C3E50` | Primary text |
| Error Red | `#E74C3C` | Error states, alerts |

### Typography

The app uses the Inter font family (falls back to system fonts). To enable custom fonts:

1. Download Inter font files from [Google Fonts](https://fonts.google.com/specimen/Inter)
2. Place them in `assets/fonts/`
3. Uncomment the fonts section in `pubspec.yaml`

## Roadmap

- [ ] Firebase Authentication integration
- [ ] Real-time database with Firestore
- [ ] Payment gateway integration (Flutterwave, MTN Mobile Money)
- [ ] Google Maps for delivery tracking
- [ ] Push notifications
- [ ] Offline mode support
- [ ] Shopper and Rider companion apps

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Design inspired by modern grocery delivery apps
- Icons from [Iconsax](https://iconsax.io/)
