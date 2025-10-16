# Firebase Deployment Guide

## Prerequisites

### 1. Install Firebase CLI

**Using npm:**
```powershell
npm install -g firebase-tools
```

**Verify installation:**
```powershell
firebase --version
```

### 2. Login to Firebase

```powershell
firebase login
```

This will open your browser for authentication.

### 3. Verify Project

```powershell
firebase projects:list
```

You should see: `aksharaintelligence-41f4a`

## Build & Deploy Options

### Option 1: Build and Deploy (One Command)

```powershell
.\build-and-deploy.ps1
```

This script will:
1. Clean previous builds
2. Get dependencies
3. Build web app (release mode, cloud backend)
4. Deploy to Firebase Hosting

### Option 2: Build Only

```powershell
.\build-web.ps1
```

Use this if you want to:
- Test the build locally first
- Inspect the build output
- Deploy manually later

### Option 3: Deploy Only (After Building)

```powershell
firebase deploy --only hosting
```

## Manual Build Commands

If you prefer manual control:

```powershell
# Clean
flutter clean

# Get dependencies
flutter pub get

# Build for production (cloud mode)
flutter build web --release --dart-define=USE_DIRECTUS=false --web-renderer canvaskit

# Deploy
firebase deploy --only hosting
```

## Build Configurations

### Cloud Mode (Hasura + Supabase)
```powershell
flutter build web --release --dart-define=USE_DIRECTUS=false
```

### Local Mode (Directus)
```powershell
flutter build web --release --dart-define=USE_DIRECTUS=true
```

### Web Renderers

**CanvasKit (Recommended for Desktop):**
- Better performance
- Better graphics quality
- Larger download size (~2MB)
```powershell
--web-renderer canvaskit
```

**HTML (Recommended for Mobile):**
- Smaller download size
- Faster initial load
- Some graphics limitations
```powershell
--web-renderer html
```

**Auto (Default):**
- Chooses based on device
```powershell
--web-renderer auto
```

## Testing Production Build Locally

After building, test locally before deploying:

```powershell
# Serve the built files
firebase serve --only hosting

# Or use Flutter
flutter run -d chrome --release
```

Open: http://localhost:5000

## Deployment URLs

After successful deployment, your app will be available at:

- **Primary:** https://aksharaintelligence-41f4a.web.app
- **Secondary:** https://aksharaintelligence-41f4a.firebaseapp.com

## Troubleshooting

### Firebase CLI Not Found
```powershell
npm install -g firebase-tools
```

### Not Logged In
```powershell
firebase login
firebase projects:list  # Verify login
```

### Build Fails
```powershell
flutter clean
flutter pub get
flutter doctor  # Check for issues
```

### Deployment Fails
```powershell
# Check Firebase project
firebase use --add

# Try deploying again
firebase deploy --only hosting --debug
```

### Wrong Backend Configuration

If you deployed with wrong backend:
1. Rebuild with correct `--dart-define`
2. Deploy again

## Firebase Configuration Files

- **firebase.json** - Hosting configuration
- **.firebaserc** - Project settings
- **build/web/** - Build output (what gets deployed)

## CI/CD Integration

For automated deployments, use GitHub Actions:

```yaml
name: Deploy to Firebase
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release --dart-define=USE_DIRECTUS=false
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: aksharaintelligence-41f4a
```

## Build Output Structure

```
build/web/
├── index.html
├── main.dart.js
├── flutter.js
├── flutter_service_worker.js
├── manifest.json
├── version.json
├── assets/
│   ├── AssetManifest.json
│   ├── FontManifest.json
│   ├── NOTICES
│   └── fonts/
├── canvaskit/
└── icons/
```

## Performance Tips

1. **Enable Compression:** Already configured in firebase.json
2. **Cache Static Assets:** Headers configured for 1 year
3. **Use CanvasKit for Desktop:** Better performance
4. **Optimize Images:** Compress before uploading
5. **Lazy Load:** Load features on demand

## Security

- Firebase Hosting uses HTTPS by default
- Configure CSP headers if needed
- Use Firebase Security Rules for backend
- Keep admin secrets secure (not in build)

## Cost

Firebase Hosting free tier includes:
- 10 GB storage
- 360 MB/day bandwidth
- Custom domain support

Check: https://firebase.google.com/pricing

## Support

- Flutter Web: https://flutter.dev/web
- Firebase Hosting: https://firebase.google.com/docs/hosting
- Firebase CLI: https://firebase.google.com/docs/cli
