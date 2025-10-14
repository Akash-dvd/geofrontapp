# Hybrid Backend Authentication & GraphQL Architecture

## Overview

Both **local (Directus)** and **cloud (Hasura)** backends use **Firebase Authentication** as the single source of truth for user identity. The only difference is the data backend: Directus for local development, Hasura+Supabase for cloud/production.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Authentication                   │
│              (Single Source of Truth - Always)               │
│                                                               │
│  - signInWithEmailAndPassword()                              │
│  - getIdToken() → JWT with user claims                       │
│  - authStateChanges() → Stream<User?>                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Firebase ID Token (JWT)
                        │
            ┌───────────┴───────────┐
            │                       │
            ▼                       ▼
    ┌───────────────┐       ┌──────────────────┐
    │   LOCAL DEV   │       │   CLOUD/PROD     │
    │   (Directus)  │       │     (Hasura)     │
    └───────────────┘       └──────────────────┘
            │                       │
            │                       │
    ┌───────┴─────────┐     ┌──────┴───────────┐
    │  GraphQL API    │     │   GraphQL API    │
    │  (Directus)     │     │   (Hasura)       │
    │                 │     │                  │
    │  Header:        │     │  Header:         │
    │  Authorization: │     │  Authorization:  │
    │  Bearer <token> │     │  Bearer <token>  │
    └─────────────────┘     └──────────────────┘
```

## Authentication Flow

### 1. **User Sign-In** (Same for both modes)
```dart
// Firebase Auth handles this
await AppServices.auth.signInWithEmailAndPassword(email, password);
```

### 2. **Get Firebase ID Token** (Same for both modes)
```dart
// Get JWT token from Firebase
final idToken = await AppServices.auth.getIdToken();
// Returns: "eyJhbGciOiJSUzI1NiIs..." (JWT with user claims)
```

### 3. **Make API Requests** (Different backends, same auth)

#### Local Mode (Directus)
```dart
// GraphQL request to Directus
// Headers: Authorization: Bearer <firebase_id_token>
final result = await graphqlClient.query(
  QueryOptions(
    document: gql(DirectusProblemQueries.getAllProblems),
  ),
);
```

#### Cloud Mode (Hasura)
```dart
// GraphQL request to Hasura
// Headers: Authorization: Bearer <firebase_id_token>
final result = await graphqlClient.query(
  QueryOptions(
    document: gql(HasuraProblemQueries.getAllProblems),
  ),
);
```

## GraphQL Queries

### Why Separate Query Files?

Directus and Hasura have different GraphQL schemas:
- **Field naming**: Directus uses `date_created`, Hasura uses `created_at`
- **ID types**: Directus uses `ID!`, Hasura uses `uuid!`
- **Mutations**: Directus uses `create_problems_item`, Hasura uses `insert_problems_one`
- **Relationships**: Different nested object structures

### Query Files

#### 1. `directus_problem_queries.dart` (Local Development)
```dart
class DirectusProblemQueries {
  static const String getAllProblems = '''
    query GetProblems($limit: Int, $offset: Int) {
      problems(limit: $limit, offset: $offset, sort: ["-date_created"]) {
        id
        title
        description
        difficulty
        category
        geometry_data
        solution
        scalar_constraints
        object_constraints
        scalar_proof
        object_proof
        thumbnail { id }
        date_created
        date_updated
      }
    }
  ''';
}
```

**Authentication**: 
- Uses Firebase ID token via `Authorization: Bearer <token>` header
- Falls back to `DIRECTUS_TOKEN` from `.env.local` if not authenticated

#### 2. `hasura_problem_queries.dart` (Cloud/Production)
```dart
class HasuraProblemQueries {
  static const String getAllProblems = '''
    query GetProblems($limit: Int, $offset: Int) {
      problems(
        limit: $limit, 
        offset: $offset, 
        order_by: {created_at: desc}
      ) {
        id
        title
        description
        difficulty
        category
        geometry_data
        solution
        scalar_constraints
        object_constraints
        scalar_proof
        object_proof
        thumbnail_id
        created_at
        updated_at
        user_id
      }
    }
  ''';
}
```

**Authentication**: 
- Uses Firebase ID token via `Authorization: Bearer <token>` header
- Hasura validates JWT and extracts `user_id` from token claims
- Hasura enforces row-level security based on `user_id`

## GraphQL Client Configuration

### `graphql_config.dart` - Unified Client

The GraphQL client automatically:
1. Selects correct endpoint (Directus or Hasura) based on `BuildFlags.useDirectus`
2. Adds Firebase ID token to all requests via `AuthLink`
3. Handles token refresh automatically

```dart
class GraphQLConfig {
  static String get _graphqlEndpoint {
    if (BuildFlags.useDirectus) {
      return EnvConfig.directusUrl + '/graphql';  // http://192.168.1.3:8055/graphql
    } else {
      return EnvConfig.hasuraEndpoint;  // https://your-hasura.cloud/v1/graphql
    }
  }

  static GraphQLClient createClient() {
    final AuthLink authLink = AuthLink(
      getToken: () async {
        // Get Firebase ID token for BOTH backends
        final idToken = await AppServices.auth.getIdToken();
        return idToken != null ? 'Bearer $idToken' : null;
      },
    );
    // ... rest of configuration
  }
}
```

## Data Provider Implementation

### How Providers Use Queries

#### Directus Data Provider
```dart
import '../graphql/directus_problem_queries.dart';

class DirectusDataProvider implements DataProvider {
  @override
  Future<List<Problem>> fetchProblems({int? limit, int? offset}) async {
    final result = await graphqlClient.query(
      QueryOptions(
        document: gql(DirectusProblemQueries.getAllProblems),
        variables: {'limit': limit, 'offset': offset},
      ),
    );
    // Parse Directus-specific response structure
    final problems = result.data!['problems'] as List;
    return problems.map((p) => Problem.fromJson(p)).toList();
  }
}
```

#### Hasura Data Provider
```dart
import '../graphql/hasura_problem_queries.dart';

class HasuraDataProvider implements DataProvider {
  @override
  Future<List<Problem>> fetchProblems({int? limit, int? offset}) async {
    final result = await graphqlClient.query(
      QueryOptions(
        document: gql(HasuraProblemQueries.getAllProblems),
        variables: {'limit': limit, 'offset': offset},
      ),
    );
    // Parse Hasura-specific response structure
    final problems = result.data!['problems'] as List;
    return problems.map((p) => Problem.fromJson(p)).toList();
  }
}
```

## Backend-Specific Configurations

### Local Mode (Directus)

**Environment** (`.env.local`):
```env
# Firebase Auth (required)
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your-app.firebaseapp.com
FIREBASE_PROJECT_ID=your-firebase-project

# Directus Backend
DIRECTUS_URL=http://192.168.1.3:8055
DIRECTUS_TOKEN=optional_fallback_token_for_local_dev
```

**Build Command**:
```powershell
flutter run --dart-define=USE_DIRECTUS=true
```

**Authentication Flow**:
1. User signs in via Firebase → gets ID token
2. GraphQL requests to Directus include: `Authorization: Bearer <firebase_token>`
3. Directus validates token (or falls back to static token)

### Cloud Mode (Hasura)

**Environment** (`.env.cloud`):
```env
# Firebase Auth (required)
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your-app.firebaseapp.com
FIREBASE_PROJECT_ID=your-firebase-project

# Hasura Backend
HASURA_ENDPOINT=https://your-hasura.cloud/v1/graphql
HASURA_ADMIN_SECRET=your_admin_secret

# Supabase Storage
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_key
```

**Build Command**:
```powershell
flutter run --dart-define=USE_DIRECTUS=false
```

**Authentication Flow**:
1. User signs in via Firebase → gets ID token
2. GraphQL requests to Hasura include: `Authorization: Bearer <firebase_token>`
3. Hasura validates JWT using Firebase public keys
4. Hasura extracts `user_id` from JWT claims
5. Row-level security enforces data access based on `user_id`

## Key Points

### ✅ What's the Same (Both Modes)
1. **Firebase Authentication** - Always used for user sign-in
2. **ID Token Format** - Firebase JWT with user claims
3. **Authorization Header** - `Authorization: Bearer <token>`
4. **Token Refresh** - Handled automatically by Firebase SDK

### ❌ What's Different
1. **GraphQL Schema** - Directus vs Hasura field names/types
2. **Backend Endpoint** - Local Directus vs Cloud Hasura
3. **Query Syntax** - Separate query files for each backend
4. **File Storage** - Directus Files API vs Supabase Storage

## Environment Switching

```powershell
# Switch to local development (Directus)
.\scripts\switch_env.ps1 local run

# Switch to cloud (Hasura)
.\scripts\switch_env.ps1 cloud run

# Production build (tree-shakes Directus code)
.\scripts\switch_env.ps1 cloud build apk
```

## Security Notes

### Directus (Local)
- Firebase token preferred
- Can fall back to `DIRECTUS_TOKEN` for local dev without auth
- Less strict security for development

### Hasura (Cloud/Production)
- Firebase token **required** (no fallback)
- JWT claims include `user_id`
- Row-level security enforced via Hasura permissions
- Tokens validated against Firebase public keys

## Next Steps

1. **Implement Firebase Auth Provider** (`firebase_auth_provider.dart`)
2. **Implement Directus Data Provider** (use `DirectusProblemQueries`)
3. **Implement Hasura Data Provider** (use `HasuraProblemQueries`)
4. **Configure Hasura JWT** - Add Firebase public keys to Hasura config
5. **Test Both Modes** - Verify authentication works in local and cloud

---

**Summary**: Both backends use Firebase Auth. The `USE_DIRECTUS` flag only changes which **data backend** is queried (Directus vs Hasura), but authentication is always Firebase.
