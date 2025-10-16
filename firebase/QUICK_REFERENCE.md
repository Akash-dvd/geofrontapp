# 🚀 Quick Deployment Reference

## Prerequisites Setup (One-Time)

```powershell
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Verify setup
firebase projects:list
```

## Deploy Commands

### Option 1: Full Build & Deploy (Recommended)
```powershell
.\firebase\build-and-deploy.ps1
```
✅ Cleans, builds, and deploys in one command

### Option 2: Build Only (for testing)
```powershell
.\firebase\build-web.ps1
```
✅ Just builds, allows local testing before deploy

### Option 3: Deploy Only (after building)
```powershell
firebase deploy --only hosting
```
✅ Use if build is already complete

## Test Before Deploy

```powershell
# After building, test locally
firebase serve --only hosting
# Opens at: http://localhost:5000

# Or test with Flutter
flutter run -d chrome --release
```

## Live URLs (After Deployment)

- Primary: https://aksharaintelligence-41f4a.web.app
- Secondary: https://aksharaintelligence-41f4a.firebaseapp.com

## Build Configurations

### Cloud Mode (Production - Hasura + Supabase)
```powershell
flutter build web --release --dart-define=USE_DIRECTUS=false
```

### Local Mode (Development - Directus)
```powershell
flutter build web --release --dart-define=USE_DIRECTUS=true
```

## File Structure

```
geofrontapp/
├── firebase/              # Deployment scripts
│   ├── build-and-deploy.ps1
│   ├── build-web.ps1
│   └── README.md
├── firebase.json          # Firebase config (must be at root)
├── .firebaserc           # Project ID (must be at root)
├── build/web/            # Build output (gets deployed)
└── DEPLOYMENT.md         # Full documentation
```

## Troubleshooting

### Firebase CLI not found
```powershell
npm install -g firebase-tools
```

### Not logged in
```powershell
firebase login
```

### Build fails
```powershell
flutter clean
flutter pub get
flutter doctor
```

### Wrong backend deployed
Rebuild with correct `--dart-define` flag and redeploy

## Common Workflows

### 1. Quick Deploy
```powershell
.\firebase\build-and-deploy.ps1
```

### 2. Test Then Deploy
```powershell
.\firebase\build-web.ps1
firebase serve --only hosting  # Test at localhost:5000
firebase deploy --only hosting  # Deploy if OK
```

### 3. Emergency Rollback
```powershell
firebase hosting:rollback
```

## Performance Tips

- ✅ Use `--web-renderer canvaskit` for desktop (better graphics)
- ✅ Use `--web-renderer html` for mobile (smaller size)
- ✅ Use `--web-renderer auto` to let Flutter decide
- ✅ Test both dev and release builds
- ✅ Check build size with `build-web.ps1` (shows MB)

## Support

- Firebase: https://firebase.google.com/docs/hosting
- Flutter Web: https://flutter.dev/web
- Full docs: See [DEPLOYMENT.md](../DEPLOYMENT.md)
