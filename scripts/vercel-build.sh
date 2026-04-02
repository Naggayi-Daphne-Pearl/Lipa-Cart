#!/bin/bash
set -e

echo "==> Installing Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
export PATH="/tmp/flutter/bin:/tmp/flutter/bin/cache/dart-sdk/bin:$PATH"

echo "==> Flutter version:"
flutter --version

echo "==> Getting dependencies..."
flutter pub get

echo "==> Building web release..."
flutter build web --release --base-href / --no-tree-shake-icons \
  --dart-define=API_BASE_URL="${API_BASE_URL:-https://lipa-cart-strapi-production.up.railway.app}" \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" \
  --dart-define=SENTRY_ENV=production \
  --dart-define=IMGBB_API_KEY="${IMGBB_API_KEY:-}"

echo "==> Build complete!"
