#!/bin/bash

# LipaCart Vercel Deployment Script
# This script builds and deploys your Flutter web app to Vercel

set -e  # Exit on error

echo "🚀 LipaCart Vercel Deployment"
echo "=============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed. Please install Flutter first.${NC}"
    exit 1
fi

# Check if vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo -e "${BLUE}📦 Installing Vercel CLI...${NC}"
    npm install -g vercel
fi

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean

# Get dependencies
echo -e "${BLUE}📦 Getting dependencies...${NC}"
flutter pub get

# Build for web
echo -e "${BLUE}🔨 Building Flutter web app...${NC}"
flutter build web --release --web-renderer canvaskit --base-href /

# Check if build was successful
if [ ! -d "build/web" ]; then
    echo -e "${RED}❌ Build failed! build/web directory not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
echo ""

# Copy vercel.json to build folder
echo -e "${BLUE}📋 Copying Vercel configuration...${NC}"
cp vercel.json build/web/

# Deploy to Vercel
echo -e "${BLUE}🚀 Deploying to Vercel...${NC}"
cd build/web
vercel --prod

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${BLUE}🌐 Your app should be live at the URL shown above.${NC}"
echo ""
