# Cloud Mode Fix: Supabase Storage + Hasura Integration

## 🎉 Summary

Successfully integrated Supabase Storage for thumbnails with Hasura GraphQL backend in cloud mode.

---

## ✅ What Was Fixed

### 1. **Supabase Storage Setup**
- Created `problem-images` bucket (public)
- Added 4 RLS policies:
  - SELECT (public read access)
  - INSERT (authenticated uploads)
  - UPDATE (authenticated updates)
  - DELETE (authenticated deletes)

### 2. **Firebase Authentication**
- All 3 auth methods enabled in Firebase Console:
  - ✅ Email/Password
  - ✅ Google Sign-In
  - ✅ Anonymous
- App automatically signs in anonymously on startup (cloud mode)

### 3. **File Upload Service**
- `SupabaseFileService` uploads thumbnails to Supabase Storage
- Uses Firebase UID for folder structure: `{firebase-uid}/thumbnails/{filename}`
- Returns storage path (e.g., `0ll8ul6UhxbDmJXigmjfJxjeroP2/thumbnails/temp_1760456855751.png`)

### 4. **Problem BLoC Fix** (CRITICAL)
**Problem:** Code was hard-coded to use Directus REST API (`http://192.168.1.3:8055`) even in cloud mode

**Solution:** Changed to use GraphQL mutations that work for both backends:
```dart
// OLD (REST API - Directus only):
final response = await http.post(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  ...
);

// NEW (GraphQL - works for both):
final result = await _graphQLClient.mutate(
  MutationOptions(
    document: gql(ProblemQueries.createProblem), // Auto-switches based on BuildFlags
    variables: {...},
  ),
);
```

---

## 🔄 Complete Flow (Cloud Mode)

```
1. User opens app
   ↓
2. Firebase Auth initializes
   ↓
3. Anonymous sign-in (if no user)
   ↓
4. User creates problem with drawing
   ↓
5. Canvas captured as PNG (Uint8List)
   ↓
6. SupabaseFileService.uploadThumbnail()
   - Gets Firebase ID token
   - Uploads to: {firebase-uid}/thumbnails/{filename}
   - Returns storage path
   ↓
7. ProblemBloc.createProblem()
   - Calls Hasura GraphQL mutation
   - Sends thumbnail_id (storage path)
   - Hasura saves problem with thumbnail path
   ↓
8. Problem created successfully!
   - ID: From Hasura
   - Thumbnail URL: https://YOUR_PROJECT.supabase.co/storage/v1/object/public/problem-images/{storage-path}
```

---

## 📁 Files Modified

### 1. `packages/geoapp/lib/services/supabase_file_service.dart`
- Added `import 'package:firebase_auth/firebase_auth.dart'`
- Changed to use Firebase token instead of anon key
- Added proper error handling

### 2. `packages/geoapp/lib/bloc/problem_bloc.dart`
- **Line 167-179:** Changed from REST API to GraphQL mutation
- **Line 182-209:** Changed response handling for GraphQL result
- Now supports both Hasura (`insert_problems_one`) and Directus (`create_problems_item`)

### 3. `supabase/` (New Directory)
- `setup-storage.sql` - Simple bucket + policies setup
- `setup-storage-advanced.sql` - Advanced with helper functions
- `setup-storage-policies-only.sql` - Policies only (for SQL editor)
- `test-storage.sql` - Verification queries
- `add-read-policy.sql` - Add missing SELECT policy
- `README.md` - Complete setup documentation

---

## 🧪 Testing

### Test 1: Upload Success
```
✅ Firebase initialized successfully
✅ User already signed in: 0ll8ul6UhxbDmJXigmjfJxjeroP2
DEBUG: Canvas capture complete, 5548 bytes
DEBUG: Uploading to Supabase Storage: 0ll8ul6UhxbDmJXigmjfJxjeroP2/thumbnails/temp_1760456855751.png
✅ Supabase upload successful: 0ll8ul6UhxbDmJXigmjfJxjeroP2/thumbnails/temp_1760456855751.png
DEBUG: Problem created successfully
DEBUG: New problem ID: 42, ThumbnailId: 0ll8ul6UhxbDmJXigmjfJxjeroP2/thumbnails/temp_1760456855751.png
```

---

## 🔐 Security Model

### Application Level
- **Firebase Auth:** Controls who can access the app
- **Hasura Permissions:** Controls CRUD operations on problems
- **Supabase RLS:** Controls file upload/read access

### Storage Organization
- Files organized by Firebase UID: `{uid}/thumbnails/{filename}`
- Public bucket allows read access (for viewing thumbnails)
- Upload/delete require authentication (checked by app)

### Why This Works
- Thumbnails are public-facing images (not sensitive)
- Hasura permissions control who can create/view problems
- Firebase Auth ensures only authenticated users use the app
- File paths include Firebase UID preventing collisions

---

## 📊 Hasura Schema

```sql
CREATE TABLE problems (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT NOT NULL,
  category TEXT NOT NULL,
  geometry_data JSONB,
  solution TEXT,
  thumbnail_id TEXT,  -- ← Supabase storage path
  user_id TEXT,       -- ← From Firebase JWT
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**thumbnail_id format:** `{firebase-uid}/thumbnails/{filename}.png`

**Public URL:** `https://YOUR_PROJECT.supabase.co/storage/v1/object/public/problem-images/{thumbnail_id}`

---

## 🚀 Next Steps

1. **Test Email/Password Sign-In**
   - Sign out of anonymous
   - Sign in with test@example.com
   - Create problem
   - Verify thumbnail uploads

2. **Implement Google Sign-In**
   - Add `google_sign_in` package
   - Configure OAuth credentials
   - Test sign-in flow

3. **Add Thumbnail Display**
   - Use `thumbnail_id` to construct public URL
   - Display in problem list
   - Add placeholder for missing thumbnails

4. **Error Handling**
   - Handle upload failures gracefully
   - Retry logic for network errors
   - Show user-friendly error messages

---

## 📝 Configuration

### Supabase
- **Project:** ahcndokbcggdymszuhpn
- **Bucket:** problem-images (public)
- **Base URL:** https://YOUR_PROJECT.supabase.co

### Hasura
- **Endpoint:** https://premium-turkey-36.hasura.app/v1/graphql
- **Auth:** Firebase JWT (x-hasura-user-id from token)

### Firebase
- **Project:** aksharaintelligence-41f4a
- **Auth Methods:** Email/Password, Google, Anonymous
- **Token:** Used for both Hasura and Supabase

---

## ✅ Status

- [x] Supabase Storage configured
- [x] Firebase Auth working
- [x] File upload working
- [x] Hasura GraphQL mutation working
- [x] Anonymous sign-in working
- [ ] Email/Password sign-in tested
- [ ] Google sign-in implemented
- [ ] Thumbnail display in UI
- [ ] Error handling polished

---

## 🎯 Key Learnings

1. **Supabase RLS requires policies** - Even for public buckets
2. **Firebase Auth !== Supabase Auth** - Can't use `auth.uid()` in RLS with Firebase
3. **GraphQL > REST** - More flexible, works across backends
4. **BuildFlags important** - Code must check mode before choosing endpoints
5. **Storage path as ID** - Simpler than managing separate file records

**Status: Cloud mode file upload WORKING! 🎉**
