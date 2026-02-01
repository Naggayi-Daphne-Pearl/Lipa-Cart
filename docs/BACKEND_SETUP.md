# Backend Setup: Supabase + Strapi

This guide explains how to set up Lipa-Cart's backend using Supabase (PostgreSQL + Auth) with Strapi as the CMS.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       Flutter App                                │
├─────────────────────────────────────────────────────────────────┤
│                            │                                     │
│              ┌─────────────┴─────────────┐                      │
│              ▼                           ▼                      │
│     ┌─────────────────┐         ┌─────────────────┐            │
│     │     Strapi      │         │    Supabase     │            │
│     │   (CMS API)     │         │   (Auth/RT)     │            │
│     │                 │         │                 │            │
│     │ • Products      │         │ • Auth          │            │
│     │ • Categories    │         │ • Realtime      │            │
│     │ • Recipes       │         │ • Storage       │            │
│     │ • Shoppers      │         │                 │            │
│     │ • Riders        │         │                 │            │
│     └────────┬────────┘         └────────┬────────┘            │
│              │                           │                      │
│              └───────────┬───────────────┘                      │
│                          ▼                                      │
│              ┌─────────────────────────┐                        │
│              │   Supabase PostgreSQL   │                        │
│              │      (Single DB)        │                        │
│              └─────────────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘
```

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note down your credentials:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **Anon Key**: For client-side access
   - **Service Role Key**: For server-side/admin access
   - **Database Password**: Set during project creation

3. Get your database connection string:
   - Go to **Settings > Database**
   - Copy the **Connection string (URI)**
   - Format: `postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres`

## Step 2: Run Database Migrations

1. Install Supabase CLI:
```bash
npm install -g supabase
```

2. Login to Supabase:
```bash
supabase login
```

3. Link your project:
```bash
cd Lipa-Cart
supabase link --project-ref your-project-ref
```

4. Run the migration:
```bash
supabase db push
```

Or manually run the SQL in Supabase Dashboard:
- Go to **SQL Editor**
- Paste contents of `supabase/migrations/001_initial_schema.sql`
- Click **Run**

## Step 3: Set Up Strapi

1. Create a new Strapi project:
```bash
npx create-strapi-app@latest lipa-cart-cms --quickstart
cd lipa-cart-cms
```

2. Stop the server and configure PostgreSQL connection

3. Install PostgreSQL client:
```bash
npm install pg
```

4. Update `config/database.js`:
```javascript
module.exports = ({ env }) => ({
  connection: {
    client: 'postgres',
    connection: {
      host: env('DATABASE_HOST', 'db.xxxxx.supabase.co'),
      port: env.int('DATABASE_PORT', 5432),
      database: env('DATABASE_NAME', 'postgres'),
      user: env('DATABASE_USERNAME', 'postgres'),
      password: env('DATABASE_PASSWORD', 'your-database-password'),
      ssl: {
        rejectUnauthorized: env.bool('DATABASE_SSL_SELF', false),
      },
    },
    debug: false,
  },
});
```



# Supabase PostgreSQL
DATABASE_HOST=db.xxxxx.supabase.co
DATABASE_PORT=5432
DATABASE_NAME=postgres
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your-supabase-db-password
DATABASE_SSL_SELF=false
```

## Step 4: Configure Strapi Content Types

Strapi will manage these content types via its admin panel:

### Products
Create a collection type with these fields:
- `name` (Text, required)
- `slug` (UID, based on name)
- `description` (Rich Text)
- `price` (Decimal, required)
- `original_price` (Decimal)
- `unit` (Enumeration: kg, piece, litre, bunch, tray)
- `min_quantity` (Decimal, default: 1)
- `max_quantity` (Decimal, default: 100)
- `is_available` (Boolean, default: true)
- `is_featured` (Boolean, default: false)
- `rating` (Decimal)
- `review_count` (Integer)
- `category` (Relation: belongs to Category)
- `images` (Media, multiple)
- `tags` (JSON or Repeatable component)

### Categories
- `name` (Text, required)
- `slug` (UID)
- `description` (Text)
- `image` (Media)
- `color` (Text)
- `sort_order` (Integer)
- `is_active` (Boolean)
- `products` (Relation: has many Products)

### Recipes
- `name` (Text, required)
- `slug` (UID)
- `description` (Rich Text)
- `image` (Media)
- `author_name` (Text)
- `author_image` (Media)
- `prep_time` (Integer, in minutes)
- `cook_time` (Integer, in minutes)
- `servings` (Integer)
- `difficulty` (Enumeration: easy, medium, hard)
- `rating` (Decimal)
- `review_count` (Integer)
- `is_published` (Boolean)
- `ingredients` (Repeatable component)
- `instructions` (Repeatable component)
- `tags` (JSON array)

### Shoppers
- `name` (Text, required)
- `phone` (Text, required)
- `email` (Email)
- `profile_image` (Media)
- `is_active` (Boolean)
- `rating` (Decimal)

### Riders
- `name` (Text, required)
- `phone` (Text, required)
- `email` (Email)
- `profile_image` (Media)
- `vehicle_type` (Enumeration)
- `vehicle_plate` (Text)
- `is_active` (Boolean)
- `rating` (Decimal)

## Step 5: Strapi Permissions

Go to **Settings > Roles > Public** and enable:
- `find` and `findOne` for: Categories, Products, Recipes
- `find` for: Shoppers, Riders (only active ones)

## Step 6: Flutter Integration

### Add dependencies to `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.3.0
  http: ^1.1.0  # For Strapi API calls
```

### Initialize Supabase in `main.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xxxxx.supabase.co',
    anonKey: 'your-anon-key',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
```

### Create API service for Strapi:
```dart
class StrapiService {
  static const String baseUrl = 'https://your-strapi-url.com/api';

  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products?populate=*'),
    );
    // Parse response...
  }

  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories?populate=*'),
    );
    // Parse response...
  }
}
```

### Use Supabase for user data:
```dart
// Auth
final authResponse = await supabase.auth.signInWithOtp(phone: '+256...');

// Orders
final orders = await supabase
  .from('orders')
  .select('*, order_items(*)')
  .eq('user_id', supabase.auth.currentUser!.id);

// Cart
await supabase
  .from('cart_items')
  .insert({'cart_id': cartId, 'product_id': productId, 'quantity': 1});

// Realtime order tracking
supabase
  .from('orders')
  .stream(primaryKey: ['id'])
  .eq('id', orderId)
  .listen((data) {
    // Update UI with new order status
  });
```

## Environment Variables

### Flutter App (create `lib/config/env.dart`):
```dart
class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String strapiUrl = String.fromEnvironment('STRAPI_URL');
}
```

### Build with env vars:
```bash
flutter build web --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=xxx --dart-define=STRAPI_URL=https://xxx
```

## Deployment

### Strapi
- **Render.com** (free tier available)
- **Railway.app**
- **DigitalOcean App Platform**
- **Heroku**

### Supabase
- Already hosted at supabase.com

## Database Schema Reference

See `supabase/migrations/001_initial_schema.sql` for complete schema including:
- All table definitions
- Indexes for performance
- Row Level Security policies
- Triggers for timestamps
- Functions for order numbers
