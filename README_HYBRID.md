# Hybrid Backend Architecture

This document explains the hybrid local/cloud backend architecture with Firebase Authentication.

## Architecture Overview

### Authentication
- **Single source of truth**: Firebase Authentication (always used)
- Firebase ID tokens are used for all backend requests
- Both local and cloud backends authenticate via Firebase tokens

### Data Backends
- **LOCAL mode**: Directus REST API (development)
- **CLOUD mode**: Hasura GraphQL + Supabase Storage (production)

### Compile-Time Switching
- Uses `--dart-define=USE_DIRECTUS=true/false` for compile-time decisions
- Directus code is **tree-shaken** in production builds (USE_DIRECTUS=false)
- Environment variables loaded from `.env` files at runtime

---

## Quick Start

### 1. Setup Environment Files

Create `.env.local` and `.env.cloud` in project root (copy from `.env.local.template` and `.env.cloud.template`):

```bash
# .env.local - Local Development
APP_MODE=local
USE_DIRECTUS=true
FIREBASE_API_KEY=your_key
FIREBASE_PROJECT_ID=your_project
DIRECTUS_URL=http://192.168.1.3:8055
DIRECTUS_TOKEN=optional_admin_token
```

```bash
# .env.cloud - Cloud Production
APP_MODE=cloud
USE_DIRECTUS=false
FIREBASE_API_KEY=your_key
FIREBASE_PROJECT_ID=your_project
HASURA_GRAPHQL_ENDPOINT=https://your-hasura.app/v1/graphql
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

### 2. Switch Environments

```bash
# Local development with Directus
./scripts/switch_env.sh local run

# Cloud development with Hasura+Supabase
./scripts/switch_env.sh cloud run

# Production build (always cloud)
./scripts/switch_env.sh cloud build web --release
./scripts/switch_env.sh cloud build apk --release
```

### 3. VSCode Tasks

Use Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`):
- **Tasks: Run Task** → "Dev: Local (Directus)"
- **Tasks: Run Task** → "Dev: Cloud (Hasura+Supabase)"
- **Tasks: Run Build Task** → "Build: Web (Cloud)"

---

## Architecture Details

### Firebase Authentication Integration

**All modes use Firebase Authentication**:

```dart
// 1. User signs in with Firebase
await FirebaseAuth.instance.signInWithEmailAndPassword(email, password);

// 2. Get Firebase ID token
final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();

// 3. Use token for backend requests
// - Directus: Can accept Firebase tokens or use fallback DIRECTUS_TOKEN
// - Hasura: Requires Firebase JWT with proper claims
```

### Directus Adapter (Local Mode)

**Option A: Firebase Token Passthrough (Recommended)**

Configure Directus to accept Firebase tokens:
1. Set up Directus with Firebase authentication provider
2. Configure token validation endpoint
3. DirectusDataProvider passes Firebase token directly

**Option B: Token Exchange (Fallback)**

If Directus can't accept Firebase tokens:
1. Create local endpoint that validates Firebase token
2. Endpoint returns Directus session token
3. Use session token for Directus API calls

**Option C: Development Fallback**

For quick local dev without auth setup:
1. Set `DIRECTUS_TOKEN` in `.env.local`
2. DirectusDataProvider uses static admin token
3. **Only for development, never in production!**

### Hasura Integration (Cloud Mode)

**JWT Configuration**:

Hasura must be configured to accept Firebase tokens:

```yaml
# Hasura JWT config
HASURA_GRAPHQL_JWT_SECRET: |
  {
    "type": "RS256",
    "jwk_url": "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
    "audience": "YOUR_FIREBASE_PROJECT_ID",
    "issuer": "https://securetoken.google.com/YOUR_FIREBASE_PROJECT_ID",
    "claims_map": {
      "x-hasura-allowed-roles": ["user", "admin"],
      "x-hasura-default-role": "user",
      "x-hasura-user-id": "user_id"
    }
  }
```

**Firebase Claims**:

Ensure Firebase custom claims include Hasura roles:

```javascript
// Set custom claims in Firebase Admin SDK
admin.auth().setCustomUserClaims(uid, {
  'https://hasura.io/jwt/claims': {
    'x-hasura-default-role': 'user',
    'x-hasura-allowed-roles': ['user', 'admin'],
    'x-hasura-user-id': uid,
  }
});
```

### Supabase Storage Integration

**Client-Side Uploads (Recommended)**:

```dart
// 1. Get signed upload URL
final signedUrl = await supabaseClient.storage
    .from('problem-images')
    .createSignedUploadUrl('$userId/$fileName');

// 2. Upload file
await http.put(signedUrl, body: fileBytes);

// 3. Get public URL
final publicUrl = supabaseClient.storage
    .from('problem-images')
    .getPublicUrl('$userId/$fileName');
```

**Server-Side Operations**:

Use `SUPABASE_SERVICE_ROLE_KEY` for admin operations (never expose to clients).

---

## Code Organization

### Service Layer

```
lib/services/
├── app_services.dart              # Global service locator
├── auth/
│   ├── auth_provider.dart         # Abstract interface
│   └── firebase_auth_provider.dart # Firebase implementation
└── data/
    ├── data_provider.dart         # Abstract interface
    ├── directus_data_provider.dart # Local Directus impl
    ├── hasura_data_provider.dart   # Cloud Hasura+Supabase impl
    └── data_provider_factory.dart  # Conditional factory
```

### Configuration

```
lib/config/
├── build_flags.dart    # Compile-time flags (USE_DIRECTUS)
└── env_config.dart     # Runtime environment variables
```

### Usage in App

```dart
// Get services from locator
final auth = AppServices.auth;
final data = AppServices.data;

// Use data provider (implementation hidden)
final problems = await data.fetchProblems();
final imageUrl = data.getImageUrl(problem.thumbnail);

// Auth operations
await auth.signInWithEmailAndPassword(email, password);
final idToken = await auth.getIdToken();
```

---

## Production Build Checklist

✅ **CRITICAL**: Always build production with `USE_DIRECTUS=false`

```bash
# ✅ CORRECT - Directus code tree-shaken
flutter build web --dart-define=USE_DIRECTUS=false --release

# ❌ WRONG - Includes unnecessary Directus code
flutter build web --release
```

✅ Use `.env.cloud` with production credentials
✅ Verify Firebase JWT claims include Hasura roles
✅ Test Hasura authentication with Firebase tokens
✅ Configure Supabase storage bucket permissions
✅ Never commit `.env`, `.env.local`, `.env.cloud` files

---

## Development Workflow

### Initial Setup

1. Fill in `.env.local` with local Directus URL
2. Fill in `.env.cloud` with Hasura + Supabase credentials
3. Configure Firebase project
4. Set up Hasura JWT validation
5. Configure Supabase storage buckets

### Daily Development

```bash
# Work on local features
./scripts/switch_env.sh local run

# Test cloud integration
./scripts/switch_env.sh cloud run

# Build for production
./scripts/switch_env.sh cloud build web --release
```

### Testing Auth Flow

1. Sign in with Firebase
2. Verify ID token is obtained
3. Check backend accepts token:
   - Directus: Token validation or fallback
   - Hasura: JWT claims parsed correctly
4. Test data operations with authenticated user

---

## Troubleshooting

### "Missing required environment variable"
- Check `.env` file exists and has all required keys
- Run `./scripts/switch_env.sh {local|cloud} run` to copy env file

### "Firebase token rejected by Hasura"
- Verify Hasura JWT config matches Firebase project
- Check custom claims are set: `https://hasura.io/jwt/claims`
- Ensure token hasn't expired (refresh with `forceRefresh: true`)

### "Directus authentication failed"
- Option 1: Configure Directus to accept Firebase tokens
- Option 2: Set `DIRECTUS_TOKEN` in `.env.local` as fallback
- Check token is passed in Authorization header

### "Build includes Directus code in production"
- Always use `--dart-define=USE_DIRECTUS=false` for production builds
- Verify with: `flutter build --analyze-size`

---

## Next Steps

### TODO: Implement SDK Details

1. **Firebase Auth**:
   - Add `firebase_core` and `firebase_auth` packages
   - Implement `FirebaseAuthProvider` methods
   - Handle auth state changes

2. **Directus Integration**:
   - Add HTTP client for REST API calls
   - Implement CRUD operations in `DirectusDataProvider`
   - Add file upload with multipart/form-data
   - Configure token validation or fallback

3. **Hasura Integration**:
   - Set up GraphQL client with Firebase token
   - Write queries/mutations for `HasuraDataProvider`
   - Implement subscriptions for real-time updates

4. **Supabase Integration**:
   - Add Supabase client SDK
   - Implement signed URL uploads
   - Configure storage bucket permissions

---

## Resources

- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Hasura JWT Authentication](https://hasura.io/docs/latest/auth/authentication/jwt/)
- [Supabase Storage](https://supabase.com/docs/guides/storage)
- [Directus Authentication](https://docs.directus.io/reference/authentication)
