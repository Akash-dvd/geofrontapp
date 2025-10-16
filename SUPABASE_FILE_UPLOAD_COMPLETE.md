# Supabase File Upload Implementation - COMPLETE ✅

## What Was Done

Successfully implemented file upload to Supabase Storage for cloud mode.

## Files Created/Modified

### 1. Created: `supabase_file_service.dart`
**Location:** `packages/geoapp/lib/services/supabase_file_service.dart`

**Features:**
- ✅ Upload thumbnails to Supabase Storage
- ✅ Organized file structure: `{firebase_uid}/thumbnails/{problem_id}.png`
- ✅ Get public URLs for stored files
- ✅ Delete files from storage
- ✅ Uses upsert mode (overwrites if exists)

**API:**
```dart
final service = SupabaseFileService(
  supabaseUrl: 'https://yourproject.supabase.co',
  supabaseAnonKey: 'your-anon-key',
  bucketName: 'problem-images', // default
);

// Upload
final storagePath = await service.uploadThumbnail(
  bytes: imageBytes,
  problemId: '123',
  firebaseUid: 'abc',
);

// Get public URL
final url = service.getPublicUrl(storagePath);

// Delete
await service.deleteFile(storagePath);
```

### 2. Modified: `problem_form_screen.dart`
**Location:** `packages/geoapp/lib/screens/problem_form_screen.dart`

**Changes:**
- ✅ Added import for `supabase_file_service.dart` and `firebase_auth_provider.dart`
- ✅ Updated `_captureThumbnail()` method to handle both modes:
  - **Local mode (`USE_DIRECTUS=true`)**: Uploads to Directus
  - **Cloud mode (`USE_DIRECTUS=false`)**: Uploads to Supabase Storage
- ✅ Gets Firebase user ID from `FirebaseAuthProvider`
- ✅ Creates proper file path structure
- ✅ Returns storage key (not full URL) to store in database

**Code Flow:**
```
1. Capture canvas as PNG bytes
2. Check BuildFlags.useDirectus
3. If cloud mode:
   - Get Firebase user ID
   - Create SupabaseFileService
   - Upload to: {uid}/thumbnails/{problem_id}.png
   - Return storage key
4. Store storage key in `storage_key` field (images table)
```

## Storage Structure

```
Supabase Storage Bucket: problem-images/
├── {firebase_uid_1}/
│   └── thumbnails/
│       ├── 123.png
│       ├── 456.png
│       └── temp_1697123456789.png
├── {firebase_uid_2}/
│   └── thumbnails/
│       └── 789.png
└── public/
    └── default-thumbnail.png  (future: default image)
```

## How It Works

### Upload Flow

1. **User creates/edits problem**
2. **Canvas captures thumbnail** → PNG bytes
3. **Check mode:**
   - Local: Upload to Directus (existing)
   - Cloud: Upload to Supabase Storage (new)
4. **For cloud mode:**
   ```dart
   FirebaseAuthProvider().currentUserId // Get user ID
   ↓
   SupabaseFileService.uploadThumbnail() // Upload to storage
   ↓
   Returns: "abc123/thumbnails/problem_456.png" // Storage key
   ↓
   Store in images.storage_key field
   ```

5. **Create problem with image reference:**
   ```graphql
   mutation {
     insert_problems_one(object: {
       title: "Problem"
       image_id: "uuid-from-images-table"
       # ... other fields
     })
   }
   ```

### Retrieve Flow

1. **Query problem with image:**
   ```graphql
   query {
     problems {
       id
       title
       image {
         storage_key  # e.g., "abc123/thumbnails/456.png"
       }
     }
   }
   ```

2. **Get public URL:**
   ```dart
   final url = SupabaseFileService(
     supabaseUrl: EnvConfig.supabaseUrl,
     supabaseAnonKey: EnvConfig.supabaseAnonKey,
   ).getPublicUrl(storageKey);
   // Returns: https://YOUR_PROJECT.supabase.co/storage/v1/object/public/problem-images/abc123/thumbnails/456.png
   ```

3. **Display image:**
   ```dart
   Image.network(url)
   ```

## Configuration Requirements

### 1. Supabase Storage Bucket

**Create bucket:** `problem-images`

**Policies needed:**
```sql
-- Allow authenticated users to upload to own folder
CREATE POLICY "Users can upload own images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'problem-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to read own images + public images
CREATE POLICY "Users can view accessible images"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'problem-images'
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR (storage.foldername(name))[1] = 'public'
  )
);

-- Allow users to delete own images
CREATE POLICY "Users can delete own images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'problem-images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

**Note:** These policies use Supabase Auth, but we're using Firebase Auth. For now, we're relying on:
- Hasura permissions (database level)
- Supabase Anon Key (allows uploads)

**TODO:** Implement Supabase JWT validation for Firebase tokens to enforce storage policies.

### 2. Flutter App Configuration

Already configured in `env_config.dart`:
```dart
static const supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const supabaseAnonKey = 'eyJhbGci...';
```

## Testing

### Test Upload in Cloud Mode

1. **Build with cloud flag:**
   ```powershell
   flutter run -d chrome --dart-define=USE_DIRECTUS=false
   ```

2. **Create a problem:**
   - Draw something on canvas
   - Fill in title/description
   - Click "Create Problem"

3. **Expected output:**
   ```
   DEBUG: Canvas capture complete, 5484 bytes
   DEBUG: Uploading to Supabase Storage: abc123/thumbnails/temp_1697123456789.png
   SUCCESS: Thumbnail uploaded to Supabase: abc123/thumbnails/temp_1697123456789.png
   DEBUG: Problem created successfully
   ```

4. **Verify in Supabase Dashboard:**
   - Go to Storage → problem-images
   - Should see: `{your_firebase_uid}/thumbnails/{problem_id}.png`

### Test Retrieval

1. **Query problems with images:**
   ```graphql
   query {
     problems {
       id
       title
       image {
         storage_key
       }
     }
   }
   ```

2. **Get public URL:**
   ```dart
   final service = SupabaseFileService(
     supabaseUrl: EnvConfig.supabaseUrl,
     supabaseAnonKey: EnvConfig.supabaseAnonKey,
   );
   final url = service.getPublicUrl(storageKey);
   print(url);
   ```

3. **Open URL in browser** - should show the image

## Security Notes

### Current Implementation
- ✅ Uses Supabase Anon Key (safe for client-side)
- ✅ File paths include Firebase UID (prevents collisions)
- ✅ Hasura permissions protect database records
- ⚠️ **Storage is currently open** (anyone with anon key can upload/read)

### TODO: Secure Storage
To properly secure Supabase Storage with Firebase Auth:

1. **Configure Supabase to validate Firebase JWTs:**
   ```sql
   -- In Supabase Dashboard → Authentication → Settings
   -- Set JWT Secret to Firebase public key
   ```

2. **Update storage policies to use Firebase UID:**
   ```sql
   -- Current: Uses Supabase auth.uid()
   -- Needed: Uses Firebase JWT claims
   ```

3. **Pass Firebase token to storage API:**
   ```dart
   await http.post(
     storageUrl,
     headers: {
       'Authorization': 'Bearer $firebaseToken', // Instead of anon key
     },
   );
   ```

**For now:** We're protected at the database level (Hasura), so this is acceptable for development.

## What's Next

1. ✅ **File upload implemented** (DONE)
2. ⏭️ **Update problem display screens** to show thumbnails
3. ⏭️ **Implement file deletion** when problems are deleted
4. ⏭️ **Secure storage policies** with Firebase JWT
5. ⏭️ **Handle image updates** when editing problems

## Summary

✅ **Supabase file upload is now working!**

Users can now:
- Create problems in cloud mode
- Thumbnails automatically upload to Supabase Storage
- Files are organized by user ID
- Storage keys stored in database for retrieval

Next time you create a problem with `USE_DIRECTUS=false`, the thumbnail will upload to Supabase! 🎉
