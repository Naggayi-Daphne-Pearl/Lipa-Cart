# Vercel Deployment - Quick Start

## 🔴 Why You're Getting 404 NOT_FOUND

The 404 error happens because:

1. **Vercel doesn't natively support Flutter** - It can't build Flutter apps automatically
2. **You need to upload pre-built files** - The `build/web` folder, not the source code
3. **Missing routing configuration** - Vercel needs to redirect all routes to `index.html`

## ✅ Quick Fix (5 minutes)

### Step 1: Build Your App Locally

```bash
flutter build web --release --web-renderer canvaskit
```

This creates the `build/web` folder with all your compiled app files.

### Step 2: Deploy Using the Script (Easiest)

I've created a deployment script for you:

```bash
./deploy-vercel.sh
```

This script will:
- Clean previous builds
- Build your Flutter app
- Deploy to Vercel automatically

**First time?** You'll be asked to:
1. Login to Vercel (opens browser)
2. Choose your account
3. Name your project (e.g., "lipa-cart")

### Step 3: Done! 🎉

Your app will be live at: `https://your-project-name.vercel.app`

---

## 🛠 Manual Deployment (If Script Doesn't Work)

### Build locally:
```bash
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit
```

### Deploy the build folder:
```bash
cd build/web
vercel --prod
```

Follow the prompts, and your app will be live!

---

## 📝 Important Notes

### Current Issue
Your Vercel project is trying to build from source code, but Vercel doesn't know how to compile Flutter.

### Solution
You have 3 options:

1. **Use the deployment script** (Recommended ⭐)
   ```bash
   ./deploy-vercel.sh
   ```

2. **Manual CLI deployment** (Simple)
   - Build locally: `flutter build web --release`
   - Deploy: `cd build/web && vercel --prod`

3. **GitHub Actions** (Automated 🤖)
   - Set up GitHub secrets (see WEB_DEPLOYMENT.md)
   - Push to main branch
   - Auto-deploys on every push

### What I've Already Set Up For You

✅ `vercel.json` - Handles routing (redirects all paths to index.html)
✅ `deploy-vercel.sh` - Automated deployment script
✅ `.github/workflows/deploy-vercel.yml` - GitHub Actions config
✅ `web/index.html` - Proper loading screen with your logo

---

## 🚨 Common Issues & Fixes

### "404 NOT_FOUND" Error
**Cause**: Deploying source code instead of built files
**Fix**: Use the deployment script or deploy from `build/web` folder

### "Blank White Screen"
**Cause**: Wrong base-href or missing files
**Fix**:
```bash
flutter build web --release --base-href /
```

### "Can't find vercel command"
**Fix**:
```bash
npm install -g vercel
```

### "Build taking too long"
**Tip**: Use canvaskit renderer for better performance:
```bash
flutter build web --release --web-renderer canvaskit
```

---

## 🎯 Recommended Workflow

### For Development:
```bash
flutter run -d chrome
```

### For Deployment:
```bash
./deploy-vercel.sh
```

### For Automated Deployment:
- Set up GitHub Actions (see docs/WEB_DEPLOYMENT.md)
- Just push to main: `git push origin main`
- Automatic deployment! ✨

---

## 📚 More Information

- Full deployment guide: `docs/WEB_DEPLOYMENT.md`
- Desktop optimizations: `docs/DESKTOP_OPTIMIZATIONS.md`
- Responsive design guide: `docs/RESPONSIVE_WEB_GUIDE.md`

---

## ⚡ Quick Commands Cheat Sheet

```bash
# Build for web
flutter build web --release

# Deploy (after building)
cd build/web && vercel --prod

# Or use the script (builds + deploys)
./deploy-vercel.sh

# Test locally
flutter run -d chrome

# Check what's in your build
ls -la build/web/
```

---

## 🎉 Next Steps

1. Run `./deploy-vercel.sh`
2. Wait for build to complete (~2-3 minutes)
3. Click the deployment URL
4. Your app is live! 🚀

**Need help?** Check the full documentation in `docs/WEB_DEPLOYMENT.md`
