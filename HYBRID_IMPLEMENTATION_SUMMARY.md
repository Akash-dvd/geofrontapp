# Hybrid Backend Implementation Summary

## Files Created

### Environment Configuration
- `.env.local` - Local development environment template (Directus + Firebase)
- `.env.cloud` - Cloud production environment template (Hasura + Supabase + Firebase)
- `scripts/switch_env.sh` - Bash script to switch between local/cloud modes and run/build app

### Build & Runtime Configuration
- `lib/config/build_flags.dart` - Compile-time flags (USE_DIRECTUS) for tree-shaking
- `lib/config/env_config.dart` - Runtime environment variable access via flutter_dotenv

### Authentication Layer
- `lib/services/auth/auth_provider.dart` - Abstract authentication interface
- `lib/services/auth/firebase_auth_provider.dart` - Firebase Auth implementation (single source of truth)

### Data Layer  
- `lib/services/data/data_provider.dart` - Abstract data provider interface
- `lib/services/data/directus_data_provider.dart` - Directus REST API implementation (local)
- `lib/services/data/hasura_data_provider.dart` - Hasura GraphQL + Supabase implementation (cloud)
- `lib/services/data/data_provider_factory.dart` - Conditional factory based on BuildFlags

### Service Management
- `lib/services/app_services.dart` - Global service locator for auth and data providers

### Documentation & Tooling
- `README_HYBRID.md` - Complete architecture documentation and usage guide
- `.vscode/tasks.json` - VSCode tasks for local/cloud development and building

## Files Modified

- `.gitignore` - Added .env files and fb-admin.json to ignore list
- `pubspec.yaml` - Added flutter_dotenv dependency and .env asset
- `lib/main.dart` - Added dotenv loading, env validation, and service initialization hooks

## Architecture Summary

### Single Auth Source
- **Firebase Authentication** used in both local and cloud modes
- Firebase ID tokens authenticate all backend requests
- `FirebaseAuthProvider` implements `AuthProvider` interface

### Dual Data Backends
- **LOCAL**: `DirectusDataProvider` → Directus REST API
- **CLOUD**: `HasuraDataProvider` → Hasura GraphQL + Supabase Storage
- Factory pattern selects provider based on `BuildFlags.useDirectus`

### Compile-Time Switching
- `--dart-define=USE_DIRECTUS=true/false` controls which backend is compiled
- Directus code is **tree-shaken** in production builds (USE_DIRECTUS=false)
- Runtime config loaded from `.env` files

### Environment Management
- `.env.local` → Local Directus development
- `.env.cloud` → Cloud Hasura+Supabase production
- `switch_env.sh` script copies appropriate file to `.env`
- VSCode tasks provide UI for switching environments

## Usage

### Development
```bash
# Local with Directus
./scripts/switch_env.sh local run

# Cloud with Hasura+Supabase  
./scripts/switch_env.sh cloud run
```

### Production Builds
```bash
# Web (always cloud)
./scripts/switch_env.sh cloud build web --release

# Mobile (always cloud)
./scripts/switch_env.sh cloud build apk --release
```

### VSCode Tasks
- "Dev: Local (Directus)"
- "Dev: Cloud (Hasura+Supabase)"
- "Build: Web (Cloud)"
- "Build: APK (Cloud)"

## Implementation Status

### ✅ Complete
- Environment file templates
- Build flags and configuration
- Abstract interfaces (AuthProvider, DataProvider)
- Service factory and locator
- Switch script and VSCode tasks
- Documentation

### 🚧 TODO (Marked with // TODO comments)
- Firebase SDK initialization in main.dart
- FirebaseAuthProvider implementation (get token, sign in/out, etc.)
- DirectusDataProvider HTTP calls (fetchProblems, createProblem, uploadImage)
- HasuraDataProvider GraphQL queries and mutations
- Supabase storage integration
- Token validation/exchange for Directus (if needed)

## Next Steps for Developer

1. **Fill Environment Files**:
   - Copy `.env.local` and add your Firebase + Directus credentials
   - Copy `.env.cloud` and add your Firebase + Hasura + Supabase credentials

2. **Add Firebase Packages**:
   ```yaml
   dependencies:
     firebase_core: ^2.24.0
     firebase_auth: ^4.15.0
   ```

3. **Implement Firebase Auth**:
   - Initialize Firebase in `main.dart` with `EnvConfig` values
   - Implement `FirebaseAuthProvider` methods using `firebase_auth` package
   - Uncomment `AppServices.initialize()` in `main.dart`

4. **Implement Data Providers**:
   - Add HTTP client to `DirectusDataProvider`
   - Add GraphQL client to `HasuraDataProvider`
   - Implement CRUD operations with // TODO markers as guide

5. **Configure Backends**:
   - **Directus**: Set up Firebase token validation or use DIRECTUS_TOKEN fallback
   - **Hasura**: Configure JWT secret with Firebase issuer and jwk_url
   - **Supabase**: Create storage buckets with appropriate permissions

6. **Test Modes**:
   ```bash
   # Test local mode
   ./scripts/switch_env.sh local run
   
   # Test cloud mode
   ./scripts/switch_env.sh cloud run
   
   # Verify production build tree-shakes Directus
   flutter build web --dart-define=USE_DIRECTUS=false --analyze-size
   ```

## Key Principles

1. **Firebase Auth Always**: Single source of truth for authentication
2. **Compile-Time Switching**: `USE_DIRECTUS` flag enables tree-shaking
3. **Runtime Config**: `.env` files for secrets and URLs
4. **Minimal Invasion**: Existing business logic unchanged, only service wiring added
5. **Production Safety**: Directus code excluded from production builds

## Support

See `README_HYBRID.md` for:
- Detailed architecture explanation
- Firebase + Hasura JWT setup
- Supabase storage patterns
- Troubleshooting guide
- Code examples

---

**Status**: Wiring layer complete, SDK implementations pending (marked with // TODO)
