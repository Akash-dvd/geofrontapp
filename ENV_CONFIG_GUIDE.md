# Environment Configuration Guide: .env vs dart-define

## ✅ Hybrid System Implemented

The app now supports **BOTH** configuration methods with automatic priority:

```
Priority: --dart-define > .env file > fallback
```

## 📋 Comparison

| Feature | `.env` Files | `--dart-define` |
|---------|--------------|-----------------|
| **Use Case** | Local development | Production builds |
| **Platform Support** | ❌ Issues on iOS/Web | ✅ All platforms |
| **Security** | ❌ File in app bundle | ✅ Compiled into binary |
| **Change Without Rebuild** | ✅ Yes | ❌ No |
| **Type Safety** | ❌ Runtime | ✅ Compile-time |
| **Easy Switching** | ✅ Very easy | ❌ Need rebuild |
| **Secret Safety** | ❌ Can be extracted | ⚠️ Harder (not impossible) |

## 🎯 Recommended Usage

### 1. **Local Development** - Use `.env` files
```powershell
# Easy switching between configs
.\scripts\switch_env.ps1 local run
.\scripts\switch_env.ps1 cloud run
```

### 2. **Production Builds** - Use `--dart-define`
```powershell
# Compile secrets into the app
flutter build apk `
  --dart-define=APP_MODE=cloud `
  --dart-define=USE_DIRECTUS=false `
  --dart-define=FIREBASE_API_KEY=your_key `
  --dart-define=FIREBASE_PROJECT_ID=your_project `
  --dart-define=HASURA_GRAPHQL_ENDPOINT=https://your-hasura.app/v1/graphql `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### 3. **CI/CD Pipelines** - Use `--dart-define-from-file`
```powershell
# Store secrets in a file (not committed to git)
flutter build apk --dart-define-from-file=config/prod.env
```

## 📁 File Structure

```
geofrontapp/
├── .env                    # Active config (copied from .env.local or .env.cloud)
├── .env.local              # Template for local dev
├── .env.cloud              # Template for cloud/prod
├── .gitignore              # ← .env files should be in here!
├── config/
│   ├── prod.env           # Production dart-define values (CI/CD)
│   └── staging.env        # Staging dart-define values (CI/CD)
└── scripts/
    ├── switch_env.ps1     # PowerShell helper
    └── switch_env.sh      # Bash helper
```

## 🔧 How It Works

### Priority System
```dart
class EnvConfig {
  static String _get(String key, {String fallback = ''}) {
    // 1. Try compile-time dart-define (HIGHEST PRIORITY)
    const dartDefine = String.fromEnvironment(key);
    if (dartDefine.isNotEmpty) return dartDefine;

    // 2. Try runtime .env file
    if (dotenv.isInitialized) {
      final envValue = dotenv.maybeGet(key);
      if (envValue != null) return envValue;
    }

    // 3. Use fallback (LOWEST PRIORITY)
    return fallback;
  }
}
```

### Usage in Code
```dart
// Always use EnvConfig - it handles both systems automatically
final apiKey = EnvConfig.firebaseApiKey;  // Gets from dart-define OR .env
```

## 📝 Configuration Methods

### Method 1: `.env` Files (Development)

**Step 1:** Copy template
```powershell
# For local Directus development
Copy-Item .env.local .env

# For cloud Hasura development
Copy-Item .env.cloud .env
```

**Step 2:** Fill in values in `.env`
```env
FIREBASE_API_KEY=AIzaSyC...
FIREBASE_PROJECT_ID=my-project
HASURA_GRAPHQL_ENDPOINT=https://my-hasura.app/v1/graphql
```

**Step 3:** Run app
```powershell
flutter run  # Reads from .env file
```

**✅ Pros:**
- Easy to switch between local/cloud
- No rebuild needed
- Good for development

**❌ Cons:**
- File must be bundled with app
- Can be extracted from app bundle
- May not work on all platforms

---

### Method 2: `--dart-define` (Production)

**Step 1:** Create dart-define file
```powershell
# config/prod.env
FIREBASE_API_KEY=AIzaSyC...
FIREBASE_PROJECT_ID=my-project
HASURA_GRAPHQL_ENDPOINT=https://my-hasura.app/v1/graphql
SUPABASE_URL=https://my-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
```

**Step 2:** Build with dart-define
```powershell
# Option A: From file (recommended)
flutter build apk --dart-define-from-file=config/prod.env

# Option B: Inline (for scripts)
flutter build apk `
  --dart-define=FIREBASE_API_KEY=AIzaSyC... `
  --dart-define=FIREBASE_PROJECT_ID=my-project `
  --dart-define=HASURA_GRAPHQL_ENDPOINT=https://my-hasura.app/v1/graphql
```

**✅ Pros:**
- Compiled into binary (more secure)
- Works on all platforms
- No file bundling needed
- Type-safe at compile time

**❌ Cons:**
- Requires rebuild to change
- Need to manage multiple config files
- Longer command lines

---

## 🚀 Production Build Scripts

### Android APK (Cloud)
```powershell
flutter build apk `
  --release `
  --dart-define=APP_MODE=cloud `
  --dart-define=USE_DIRECTUS=false `
  --dart-define=FIREBASE_API_KEY=$env:FIREBASE_API_KEY `
  --dart-define=FIREBASE_AUTH_DOMAIN=$env:FIREBASE_AUTH_DOMAIN `
  --dart-define=FIREBASE_PROJECT_ID=$env:FIREBASE_PROJECT_ID `
  --dart-define=FIREBASE_STORAGE_BUCKET=$env:FIREBASE_STORAGE_BUCKET `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=$env:FIREBASE_MESSAGING_SENDER_ID `
  --dart-define=FIREBASE_APP_ID=$env:FIREBASE_APP_ID `
  --dart-define=HASURA_GRAPHQL_ENDPOINT=$env:HASURA_ENDPOINT `
  --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
```

### iOS (Cloud)
```powershell
flutter build ios `
  --release `
  --dart-define-from-file=config/prod.env
```

### Web (Cloud)
```powershell
flutter build web `
  --release `
  --dart-define-from-file=config/prod.env
```

## 🔐 Security Best Practices

### ✅ DO:
1. **Use `--dart-define` for production** - More secure than .env files
2. **Store secrets in CI/CD environment variables** - Not in repo
3. **Use different Firebase projects** - Dev vs Prod
4. **Add `.env` to `.gitignore`** - Never commit secrets
5. **Use Supabase RLS (Row Level Security)** - Backend protection

### ❌ DON'T:
1. **Don't commit `.env` files with secrets** - Use templates only
2. **Don't use same keys for dev/prod** - Separate environments
3. **Don't expose service role keys** - Server-side only
4. **Don't rely only on client secrets** - Backend must validate

## 🔍 Debugging Configuration

### Check Current Config
```dart
// In main.dart or any screen
EnvConfig.printConfig();
```

Output:
```
═════════════════════════════════════════
Environment Configuration
═════════════════════════════════════════
Mode: cloud
Firebase Project: my-project-prod
Hasura Endpoint: https://my-hasura.app/v1/graphql
Supabase URL: https://my-project.supabase.co
═════════════════════════════════════════
```

### Validate on Startup
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env if available (development)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('No .env file found (using dart-define)');
  }
  
  // Validate required variables
  EnvConfig.validate();  // Throws if missing
  
  // Print config for debugging
  EnvConfig.printConfig();
  
  runApp(const GeoFrontApp());
}
```

## 📊 Migration Strategy

### Phase 1: Development (Now)
- ✅ Use `.env` files
- ✅ Easy switching between local/cloud
- ✅ No build overhead

### Phase 2: Staging/Testing
- ⏭️ Switch to `--dart-define-from-file`
- ⏭️ Test on all platforms
- ⏭️ Validate secret security

### Phase 3: Production
- ⏭️ CI/CD with `--dart-define` from secrets
- ⏭️ No `.env` files bundled
- ⏭️ Platform-specific optimizations

## 🎯 Quick Commands

```powershell
# Local development (Directus)
.\scripts\switch_env.ps1 local run

# Cloud development (Hasura)
.\scripts\switch_env.ps1 cloud run

# Production APK (with dart-define)
flutter build apk --dart-define-from-file=config/prod.env

# Check current config
flutter run --dart-define=DEBUG_CONFIG=true
```

## 📝 Summary

| Scenario | Recommended Method | Command |
|----------|-------------------|---------|
| Local Dev | `.env.local` | `.\scripts\switch_env.ps1 local run` |
| Cloud Dev | `.env.cloud` | `.\scripts\switch_env.ps1 cloud run` |
| CI/CD Build | `--dart-define-from-file` | `flutter build apk --dart-define-from-file=config/prod.env` |
| Production Release | `--dart-define` from CI secrets | `flutter build apk --dart-define=KEY=value` |

---

**Current Status**: ✅ Hybrid system implemented - uses both .env AND dart-define with automatic priority!
