# Build Modes & Tree-Shaking

## Development (Local Directus)
```powershell
# Run locally with Directus backend
flutter run --dart-define=USE_DIRECTUS=true -d chrome

# What gets included:
✅ DirectusProblemQueries
✅ Directus GraphQL endpoint
✅ Firebase auth → Directus JWT validation
❌ HasuraProblemQueries (removed by tree-shaking)
❌ Hasura/Supabase endpoints (not used)
```

## Production (Cloud Hasura+Supabase)
```powershell
# Build for production (defaults to cloud)
flutter build web

# OR explicitly specify cloud mode
flutter build web --dart-define=USE_DIRECTUS=false

# What gets included:
✅ HasuraProblemQueries
✅ Hasura GraphQL endpoint
✅ Supabase configuration
✅ Firebase auth → Hasura JWT validation
❌ DirectusProblemQueries (removed by tree-shaking)
❌ Directus endpoint (not compiled into bundle)
```

## How Tree-Shaking Works

### Compile-Time Constants
```dart
// BuildFlags.useDirectus is a compile-time constant
static const bool useDirectus = bool.fromEnvironment('USE_DIRECTUS', defaultValue: false);

// Dart compiler evaluates this at compile time:
String get getAllProblems => BuildFlags.useDirectus
    ? DirectusProblemQueries.getAllProblems  // Dead code if useDirectus=false
    : HasuraProblemQueries.getAllProblems;   // Dead code if useDirectus=true
```

### Result
- **Production builds** (no --dart-define): Only Hasura code in final bundle
- **Local builds** (--dart-define=USE_DIRECTUS=true): Only Directus code in bundle
- **Security**: Directus endpoint never exposed in production JavaScript
- **Size**: Smaller bundle (unused backend code removed)

## Verify Tree-Shaking

```powershell
# Build production bundle
flutter build web --release

# Check compiled JavaScript
cd build\web
grep -r "DirectusProblemQueries" .  # Should find NOTHING
grep -r "192.168.1.3" .              # Should find NOTHING (local IP)
grep -r "HasuraProblemQueries" .    # Should find code
```

## Configuration Summary

| Mode | Command | Backend | Default |
|------|---------|---------|---------|
| **Local Dev** | `flutter run --dart-define=USE_DIRECTUS=true` | Directus @ 192.168.1.3:8055 | No |
| **Production** | `flutter build web` | Hasura + Supabase | **Yes** ✅ |

## Security Benefits

1. **Local IP never in production**: `192.168.1.3:8055` removed from bundle
2. **Smaller attack surface**: Only one backend compiled
3. **No sensitive local config**: Directus admin credentials not in code
4. **Environment isolation**: Dev and prod completely separate

## Best Practices

✅ **DO**: Run local dev with `--dart-define=USE_DIRECTUS=true`
✅ **DO**: Build production without any flags (defaults to cloud)
✅ **DO**: Use Firebase for auth in both environments
❌ **DON'T**: Add `--dart-define=USE_DIRECTUS=true` to production builds
❌ **DON'T**: Hardcode local IPs in production-accessible code paths
