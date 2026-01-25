# Responsive Web Design Guide

This guide explains how to make the Lipa-Cart app responsive for web, tablet, and desktop platforms.

## Responsive Utilities

### 1. Breakpoints

The app uses the following breakpoints defined in `lib/core/utils/responsive.dart`:

- **Mobile**: < 600px
- **Tablet**: 600px - 1199px
- **Desktop**: 1200px - 1599px
- **Large Desktop**: ≥ 1600px

### 2. Using Responsive Extensions

Import the responsive utilities:
```dart
import '../core/utils/responsive.dart';
```

#### Check Screen Size
```dart
if (context.isMobile) {
  // Mobile layout
} else if (context.isTablet) {
  // Tablet layout
} else if (context.isDesktop) {
  // Desktop layout
}
```

#### Get Responsive Values
```dart
final fontSize = context.responsive<double>(
  mobile: 14.0,
  tablet: 16.0,
  desktop: 18.0,
  largeDesktop: 20.0,
);
```

#### Use Responsive Padding
```dart
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: context.horizontalPadding, // 20 on mobile, 40 on tablet, 60 on desktop
  ),
  child: child,
)
```

#### Get Grid Columns
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: context.gridColumns, // 2 on mobile, 3 on tablet, 4 on desktop
  ),
)
```

### 3. Responsive Widgets

#### ResponsiveContainer
Constrains content width on large screens to prevent stretching:

```dart
ResponsiveContainer(
  centerContent: true,
  child: Column(
    children: [
      // Your content
    ],
  ),
)
```

#### ResponsiveGrid
Automatically adjusts grid columns based on screen size:

```dart
ResponsiveGrid(
  mobileColumns: 2,
  tabletColumns: 3,
  desktopColumns: 4,
  spacing: 16,
  children: products.map((p) => ProductCard(p)).toList(),
)
```

#### ResponsiveBuilder
Provide different layouts for different screen sizes:

```dart
ResponsiveBuilder(
  mobile: (context) => MobileLayout(),
  tablet: (context) => TabletLayout(),
  desktop: (context) => DesktopLayout(),
)
```

#### WebLayoutWrapper
Custom wrapper for constraining content on web:

```dart
import '../widgets/web_layout_wrapper.dart';

WebLayoutWrapper(
  addPadding: true,
  child: YourContent(),
)
```

## Best Practices

### 1. Always Use Responsive Padding
❌ Don't:
```dart
Padding(
  padding: const EdgeInsets.all(20),
  child: child,
)
```

✅ Do:
```dart
Padding(
  padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
  child: child,
)
```

### 2. Constrain Content Width
Wrap main content in `ResponsiveContainer` to prevent stretching:

```dart
Scaffold(
  body: SingleChildScrollView(
    child: ResponsiveContainer(
      child: Column(
        children: [...],
      ),
    ),
  ),
)
```

### 3. Responsive Sizes
Use `context.responsive()` for sizes that should change:

```dart
Container(
  height: context.responsive<double>(
    mobile: 160.0,
    tablet: 180.0,
    desktop: 200.0,
  ),
)
```

### 4. Adaptive Layouts
Consider using horizontal lists on mobile and grids on larger screens:

```dart
if (context.isMobile) {
  return HorizontalListView();
} else {
  return GridView();
}
```

## Testing on Web

### Run on Chrome
```bash
flutter run -d chrome
```

### Build for Web
```bash
flutter build web
```

### Test Different Screen Sizes
1. Open DevTools in Chrome (F12)
2. Click the device toolbar icon (or press Ctrl+Shift+M)
3. Test these sizes:
   - Mobile: 375x667 (iPhone SE)
   - Tablet: 768x1024 (iPad)
   - Desktop: 1440x900
   - Large Desktop: 1920x1080

## Common Responsive Patterns

### Pattern 1: Responsive Card Size
```dart
Container(
  width: context.responsive<double>(
    mobile: 170.0,
    tablet: 200.0,
    desktop: 220.0,
  ),
)
```

### Pattern 2: Responsive Font Size
```dart
Text(
  'Title',
  style: TextStyle(
    fontSize: context.responsive<double>(
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    ),
  ),
)
```

### Pattern 3: Conditional Rendering
```dart
if (context.isDesktop)
  SidebarNavigation()
else
  BottomNavigationBar()
```

### Pattern 4: Max Content Width
```dart
Container(
  constraints: BoxConstraints(
    maxWidth: context.maxContentWidth,
  ),
  child: content,
)
```

## Web-Specific Configurations

### Guest Browsing on Web
The app allows guest users to browse on web without requiring login first. Users can explore products and then login/signup when they want to make a purchase. This provides a better user experience on web platforms.

**Flow**:
- Web users → Main page (browse products as guest)
- Mobile users → Onboarding (first launch) → Login → Main page

This is configured in:

**`lib/main.dart`**:
- Orientation restrictions are only applied on mobile (not web)
- System UI overlay is only set on mobile platforms

**`lib/screens/splash/splash_screen.dart`**:
- Checks if running on web using `kIsWeb`
- On web: Always goes to `/main` (guest browsing allowed)
- On mobile: Shows onboarding on first launch

### Web Assets & Branding

**Favicon and App Icons**:
- All web icons use the app logo (`assets/images/logos/app_icon.png`)
- Favicon: `web/favicon.png` (automatically resized from app icon)
- PWA Icons:
  - `web/icons/Icon-192.png` (192x192)
  - `web/icons/Icon-512.png` (512x512)
  - Maskable versions for adaptive icons

**Web Manifest** (`web/manifest.json`):
- App name: "LipaCart - Fresh Groceries Delivered"
- Theme color: `#1B7F4E` (primary green)
- Orientation: `any` (supports all orientations on web)

**index.html**:
- Custom loading screen with app branding
- Proper favicon references
- Meta tags for SEO and PWA support

### Responsive Navigation
The app uses different navigation patterns based on screen size:

**Mobile (< 600px)**:
- Bottom navigation bar with 5 items
- Classic mobile app navigation

**Tablet/Desktop (≥ 600px)**:
- Sidebar navigation (240px width)
- App logo at top
- Vertical navigation items with labels
- More professional desktop feel

This is implemented in `lib/screens/main_shell.dart` using the responsive utilities.

## Implementation Checklist

- [x] Import responsive utilities
- [x] Wrap main content in ResponsiveContainer
- [x] Replace fixed padding with context.horizontalPadding
- [x] Use responsive values for sizes
- [x] Configure web to skip onboarding
- [x] Add responsive navigation (sidebar on desktop)
- [x] Disable orientation lock on web
- [x] Test on multiple screen sizes
- [ ] Update remaining screens (if any)
- [ ] Test on actual devices

## Examples

See these files for complete examples:
- `lib/screens/home/home_screen.dart` - Full responsive implementation
- `lib/screens/main_shell.dart` - Responsive navigation (bottom bar vs sidebar)
- `lib/screens/splash/splash_screen.dart` - Web-aware routing
- `lib/widgets/category_card.dart` - Responsive widget
- `lib/widgets/web_layout_wrapper.dart` - Custom responsive wrappers
- `lib/main.dart` - Platform-specific configurations
