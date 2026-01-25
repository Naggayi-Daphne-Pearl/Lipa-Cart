# Web Deployment Guide

This guide covers deploying the LipaCart app to web platforms.

## Building for Web

### Development Build
```bash
flutter run -d chrome
```

### Production Build
```bash
flutter build web --release
```

The build output will be in the `build/web` directory.

## Web Features

### Guest Browsing
- ✅ Users can browse products without logging in
- ✅ Login required only for checkout and orders
- ✅ Better conversion rates with low-friction browsing

### Responsive Design
- ✅ Mobile: Bottom navigation (< 600px)
- ✅ Tablet/Desktop: Sidebar navigation (≥ 600px)
- ✅ Max content width constraint (prevents stretching)
- ✅ Responsive padding and spacing

### PWA Support
The app is configured as a Progressive Web App (PWA):
- ✅ Can be installed on desktop/mobile
- ✅ Works offline (with service worker)
- ✅ App-like experience in browser
- ✅ Custom app icon and splash screen

## Deployment Options

### 1. Firebase Hosting (Recommended)

**Install Firebase CLI**:
```bash
npm install -g firebase-tools
```

**Login to Firebase**:
```bash
firebase login
```

**Initialize Firebase in your project**:
```bash
firebase init hosting
```

When prompted:
- Public directory: `build/web`
- Single-page app: `Yes`
- Overwrite index.html: `No`

**Deploy**:
```bash
flutter build web --release
firebase deploy --only hosting
```

### 2. Netlify

**Via Netlify CLI**:
```bash
npm install -g netlify-cli
flutter build web --release
netlify deploy --dir=build/web --prod
```

**Via Netlify Web Interface**:
1. Push your code to GitHub
2. Connect your repository to Netlify
3. Set build command: `flutter build web --release`
4. Set publish directory: `build/web`

### 3. Vercel

**Install Vercel CLI**:
```bash
npm install -g vercel
```

**Deploy**:
```bash
flutter build web --release
cd build/web
vercel --prod
```

### 4. GitHub Pages

**Add to `pubspec.yaml`**:
```yaml
dependencies:
  # ... other dependencies
```

**Build and deploy**:
```bash
flutter build web --release --base-href "/your-repo-name/"
```

Then push the `build/web` contents to the `gh-pages` branch.

### 5. Custom Server (Apache/Nginx)

**Build**:
```bash
flutter build web --release
```

**Copy files**:
```bash
cp -r build/web/* /var/www/html/
```

**Apache .htaccess** (for client-side routing):
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

**Nginx config**:
```nginx
server {
    listen 80;
    server_name yourdomain.com;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

## Environment Configuration

### Base URL
For apps not hosted at the root, set the base href:

```bash
flutter build web --release --base-href "/subdirectory/"
```

### API Endpoints
Update your API base URLs for production in your environment config files.

## Performance Optimization

### 1. Enable Web Renderers
Flutter offers different web renderers:

**HTML renderer** (better for text-heavy apps):
```bash
flutter build web --web-renderer html
```

**CanvasKit renderer** (better for graphics):
```bash
flutter build web --web-renderer canvaskit
```

**Auto** (Flutter chooses based on device):
```bash
flutter build web --web-renderer auto
```

### 2. Enable Tree Shaking
Already enabled by default in release builds, removes unused code.

### 3. Compress Assets
Most hosting platforms automatically compress assets. For custom servers, enable gzip:

**Apache** (.htaccess):
```apache
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/css application/javascript application/json
</IfModule>
```

**Nginx**:
```nginx
gzip on;
gzip_types text/html text/css application/javascript application/json;
```

## Testing Before Deployment

### Local Testing
```bash
flutter build web --release
cd build/web
python3 -m http.server 8000
```

Then open `http://localhost:8000`

### Check Performance
1. Open Chrome DevTools
2. Go to Lighthouse tab
3. Run audit for Performance, Accessibility, Best Practices, SEO

### Test Different Screen Sizes
- Mobile: 375×667
- Tablet: 768×1024
- Desktop: 1440×900
- Large Desktop: 1920×1080

## Post-Deployment Checklist

- [ ] Test on multiple browsers (Chrome, Safari, Firefox, Edge)
- [ ] Verify favicon appears correctly
- [ ] Test responsive layout on different screen sizes
- [ ] Verify guest browsing works
- [ ] Test login/signup flow
- [ ] Check cart and checkout functionality
- [ ] Test PWA installation
- [ ] Verify analytics tracking (if configured)
- [ ] Test social sharing meta tags
- [ ] Check SSL certificate (HTTPS)

## Monitoring

### Analytics
Consider adding web analytics:
- Google Analytics
- Plausible
- Mixpanel
- Amplitude

### Error Tracking
Implement error tracking:
- Sentry
- Firebase Crashlytics
- Bugsnag

## SEO Optimization

### Meta Tags
The app includes basic meta tags in `web/index.html`. Add more as needed:

```html
<meta property="og:title" content="LipaCart - Fresh Groceries Delivered">
<meta property="og:description" content="Fresh groceries delivered to your doorstep">
<meta property="og:image" content="/icons/Icon-512.png">
<meta name="twitter:card" content="summary_large_image">
```

### Sitemap
Generate a sitemap.xml for better SEO:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://yourdomain.com/</loc>
    <priority>1.0</priority>
  </url>
</urlset>
```

## Troubleshooting

### Blank Screen After Deploy
- Check browser console for errors
- Verify `--base-href` matches your hosting path
- Ensure all files copied correctly

### Routing Issues
- Add .htaccess or nginx rewrite rules
- Verify service worker configuration

### Slow Loading
- Enable gzip compression
- Use CDN for assets
- Optimize image sizes
- Consider using CanvasKit renderer

## Support

For issues specific to deployment platforms:
- Firebase: https://firebase.google.com/support
- Netlify: https://www.netlify.com/support/
- Vercel: https://vercel.com/support
