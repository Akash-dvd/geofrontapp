# ✅ Hardcoded Configuration Setup Complete

## What Changed

### ✅ No More .env Files!
- All configuration is now **hardcoded in Dart**
- Works perfectly on **ALL platforms** (Android, iOS, Web, Desktop)
- More secure - compiled into the binary
- No file access issues

### ✅ Files Updated

1. **`packages/geoapp/lib/config/env_config.dart`**
   - Removed flutter_dotenv dependency
   - Added compile-time constants
   - Supports --dart-define overrides for CI/CD

2. **`lib/main.dart`**
   - Removed dotenv.load()
   - Simplified initialization
   - Added EnvConfig.printConfig()

## 📝 How to Add Your Credentials

### Step 1: Open env_config.dart

```
packages/geoapp/lib/config/env_config.dart
```

### Step 2: Replace These Constants

Look for this section around line 15:

```dart
// ==================== Firebase Authentication ====================
static const String _firebaseApiKey = 'YOUR_FIREBASE_API_KEY_HERE';
static const String _firebaseAuthDomain = 'your-project.firebaseapp.com';
static const String _firebaseProjectId = 'your-firebase-project-id';
static const String _firebaseStorageBucket = 'your-project.appspot.com';
static const String _firebaseMessagingSenderId = '123456789012';
static const String _firebaseAppId = '1:123456789012:web:abc123def456';
```

**Replace with your actual Firebase values:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to ⚙️ Project Settings → General
4. Scroll to "Your apps" → Select your app
5. Copy the config object values

### Step 3: Update Hasura Configuration

Around line 28:

```dart
// ==================== Cloud Hasura Backend ====================
static const String _hasuraEndpoint = 'https://your-project.hasura.app/v1/graphql';
static const String? _hasuraAdminSecret = null;
```

**Replace with:**
1. Go to Hasura Cloud Console
2. Copy your GraphQL endpoint
3. (Optional) Copy admin secret from Settings → Env vars

### Step 4: Update Supabase Configuration

Around line 35:

```dart
// ==================== Cloud Supabase Storage ====================
static const String _supabaseUrl = 'https://your-project.supabase.co';
static const String _supabaseAnonKey = 'your-supabase-anon-key-here';
static const String? _supabaseServiceRoleKey = null;
```

**Replace with:**
1. Go to Supabase Dashboard → Project Settings → API
2. Copy "Project URL"
3. Copy "anon public" key
4. (Optional) Copy "service_role" key

## 📋 Example Configuration

Here's what it should look like with real values:

```dart
// ==================== Firebase Authentication ====================
static const String _firebaseApiKey = 'AIzaSyC_actual_key_here';
static const String _firebaseAuthDomain = 'geofrontapp-prod.firebaseapp.com';
static const String _firebaseProjectId = 'geofrontapp-prod';
static const String _firebaseStorageBucket = 'geofrontapp-prod.appspot.com';
static const String _firebaseMessagingSenderId = '123456789012';
static const String _firebaseAppId = '1:123456789012:web:abc123def456';

// ==================== Local Directus Backend ====================
static const String _directusUrl = 'http://192.168.1.3:8055';
static const String? _directusToken = null; // Optional

// ==================== Cloud Hasura Backend ====================
static const String _hasuraEndpoint = 'https://my-hasura.hasura.app/v1/graphql';
static const String? _hasuraAdminSecret = null; // Optional

// ==================== Cloud Supabase Storage ====================
static const String _supabaseUrl = 'https://abcdefgh.supabase.co';
static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
static const String? _supabaseServiceRoleKey = null; // Server-side only
```

## 🚀 How to Run

### Local Mode (Directus)
```powershell
flutter run --dart-define=USE_DIRECTUS=true
# Or just: flutter run (default is true)
```

### Cloud Mode (Hasura + Supabase)
```powershell
flutter run --dart-define=USE_DIRECTUS=false
```

### Production Build
```powershell
# Android APK (Cloud mode)
flutter build apk --dart-define=USE_DIRECTUS=false

# iOS (Cloud mode)
flutter build ios --dart-define=USE_DIRECTUS=false

# Web (Cloud mode)
flutter build web --dart-define=USE_DIRECTUS=false
```

## 🔐 Security Notes

### ✅ Good:
- Compiled into binary (harder to extract than .env files)
- Works on all platforms
- No file bundling issues
- Type-safe at compile time

### ⚠️ Important:
- **Don't commit sensitive keys to public repos**
- Use separate Firebase projects for dev/prod
- Never expose service role keys in client code
- Consider using --dart-define for production secrets

## 🎯 Validation

The app will validate on startup and show:

```
═════════════════════════════════════════
Environment Configuration
═════════════════════════════════════════
Mode: cloud
Firebase Project: geofrontapp-prod
Hasura Endpoint: https://my-hasura.hasura.app/v1/graphql
Supabase URL: https://abcdefgh.supabase.co
═════════════════════════════════════════
🚀 Starting app in CLOUD (Hasura+Supabase) mode
```

If any required values are missing, you'll see:
```
Configuration error: FIREBASE_API_KEY not set!
Update the constants in env_config.dart with your actual values.
```

## 🔄 Switching Modes

### Change Default Mode
In `build_flags.dart`:
```dart
// For local Directus (development)
static const bool useDirectus = true;

// For cloud Hasura (production)
static const bool useDirectus = false;
```

### Override at Build Time
```powershell
# Use cloud even if default is local
flutter run --dart-define=USE_DIRECTUS=false

# Use local even if default is cloud
flutter run --dart-define=USE_DIRECTUS=true
```

## 📊 What You Need

Send me these values and I'll help you update the file:

### 🔥 Firebase
```
FIREBASE_API_KEY=
FIREBASE_AUTH_DOMAIN=
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_APP_ID=
```

### 🟣 Hasura
```
HASURA_GRAPHQL_ENDPOINT=
```

### 🟢 Supabase
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

---

**Next**: Paste your actual credentials and I'll update `env_config.dart` for you! 🚀
