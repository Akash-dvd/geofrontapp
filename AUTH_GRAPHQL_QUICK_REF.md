# Authentication & GraphQL Quick Reference

## ✅ Questions Answered

### Q1: Do both local and cloud use Firebase Auth?
**YES!** Both modes use Firebase Authentication as the single source of truth.

### Q2: What determines which backend is used?
The `USE_DIRECTUS` build flag:
- `USE_DIRECTUS=true` → Local Directus backend
- `USE_DIRECTUS=false` → Cloud Hasura backend

### Q3: Are GraphQL queries different for Directus and Hasura?
**YES!** They have different schemas, so we have separate query files:
- `directus_problem_queries.dart` - For local Directus
- `hasura_problem_queries.dart` - For cloud Hasura

### Q4: Do Directus GraphQL queries use Firebase auth?
**YES!** Both backends receive Firebase ID token via `Authorization: Bearer <token>` header.

## Files Created/Updated

### ✅ New Files
1. **`graphql/hasura_problem_queries.dart`**
   - Hasura-specific GraphQL queries
   - Uses `uuid!` for IDs
   - Uses `created_at`, `updated_at` fields
   - Uses `insert_problems_one`, `update_problems_by_pk` mutations

2. **`AUTHENTICATION_ARCHITECTURE.md`**
   - Complete authentication flow documentation
   - Backend comparison
   - Security notes

### ✅ Renamed Files
- `problem_queries.dart` → **`directus_problem_queries.dart`**
  - Clarified it's for Directus only
  - Added Firebase auth documentation

### ✅ Updated Files
1. **`graphql_config.dart`**
   - Now supports BOTH Directus and Hasura
   - Auto-selects endpoint based on `BuildFlags.useDirectus`
   - Uses Firebase ID token for both backends via `AuthLink`

2. **`geoapp.dart`**
   - Exports both query files
   - Exports updated GraphQL config

## Architecture Summary

```
┌──────────────────────────┐
│  Firebase Authentication │  ← Single source of truth
└────────────┬─────────────┘
             │ ID Token (JWT)
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
┌──────────┐  ┌──────────┐
│ Directus │  │  Hasura  │  ← Data backends (switchable)
│  GraphQL │  │  GraphQL │
└──────────┘  └──────────┘
      ▲             ▲
      │             │
      └─────┬───────┘
            │
┌───────────┴────────────┐
│ DirectusProblemQueries │  ← Different query syntax
│  HasuraProblemQueries  │
└────────────────────────┘
```

## Key Differences: Directus vs Hasura

| Aspect | Directus (Local) | Hasura (Cloud) |
|--------|------------------|----------------|
| **Auth** | Firebase ID token (+ fallback to DIRECTUS_TOKEN) | Firebase ID token (required) |
| **ID Type** | `ID!` | `uuid!` |
| **Timestamps** | `date_created`, `date_updated` | `created_at`, `updated_at` |
| **User Field** | Not included | `user_id` (from JWT) |
| **Create Mutation** | `create_problems_item` | `insert_problems_one` |
| **Update Mutation** | `update_problems_item` | `update_problems_by_pk` |
| **Delete Mutation** | `delete_problems_item` | `delete_problems_by_pk` |
| **Sorting** | `sort: ["-date_created"]` | `order_by: {created_at: desc}` |
| **Thumbnail** | `thumbnail { id }` (nested) | `thumbnail_id` (direct) |

## Usage Example

### In Data Provider Implementation

```dart
// Directus Data Provider
import '../graphql/directus_problem_queries.dart';

@override
Future<List<Problem>> fetchProblems({int? limit, int? offset}) async {
  final result = await graphqlClient.query(
    QueryOptions(
      document: gql(DirectusProblemQueries.getAllProblems),  // ← Directus queries
      variables: {'limit': limit, 'offset': offset},
    ),
  );
  // ... parse response
}
```

```dart
// Hasura Data Provider
import '../graphql/hasura_problem_queries.dart';

@override
Future<List<Problem>> fetchProblems({int? limit, int? offset}) async {
  final result = await graphqlClient.query(
    QueryOptions(
      document: gql(HasuraProblemQueries.getAllProblems),  // ← Hasura queries
      variables: {'limit': limit, 'offset': offset},
    ),
  );
  // ... parse response
}
```

## GraphQL Client Auto-Configuration

The `GraphQLConfig` class automatically:
1. **Selects endpoint**: Directus or Hasura based on build flag
2. **Adds auth**: Firebase ID token to all requests
3. **Handles refresh**: Token refresh via Firebase SDK

```dart
// Automatically uses correct backend and Firebase auth
final client = GraphQLConfig.createClient();
```

## Environment Files

### `.env.local` (Directus)
```env
# Firebase Auth - REQUIRED
FIREBASE_API_KEY=your_key
FIREBASE_PROJECT_ID=your_project

# Directus Backend
DIRECTUS_URL=http://192.168.1.3:8055
DIRECTUS_TOKEN=optional_fallback  # Only for local dev
```

### `.env.cloud` (Hasura)
```env
# Firebase Auth - REQUIRED
FIREBASE_API_KEY=your_key
FIREBASE_PROJECT_ID=your_project

# Hasura Backend
HASURA_ENDPOINT=https://your-hasura.cloud/v1/graphql

# Supabase Storage
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_key
```

## Next Implementation Steps

1. **Firebase Auth Provider** (`firebase_auth_provider.dart`)
   ```dart
   @override
   Future<String?> getIdToken() async {
     final user = FirebaseAuth.instance.currentUser;
     return await user?.getIdToken();
   }
   ```

2. **Directus Data Provider** (`directus_data_provider.dart`)
   - Import `DirectusProblemQueries`
   - Use GraphQL client with Firebase auth
   - Parse Directus-specific response format

3. **Hasura Data Provider** (`hasura_data_provider.dart`)
   - Import `HasuraProblemQueries`
   - Use GraphQL client with Firebase auth
   - Parse Hasura-specific response format

## Testing Commands

```powershell
# Test local mode (Directus + Firebase)
.\scripts\switch_env.ps1 local run

# Test cloud mode (Hasura + Firebase)
.\scripts\switch_env.ps1 cloud run
```

---

**Bottom Line**: Firebase Auth everywhere, GraphQL queries differ by backend, authentication flow is identical!
