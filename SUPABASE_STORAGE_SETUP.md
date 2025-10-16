# Supabase Storage Setup for Problem Thumbnails

## 🎯 Current Error

```
ERROR: Supabase upload failed: 400
ERROR: Response body: {"statusCode":"403","error":"Unauthorized","message":"new row violates row-level security policy"}
```

**Cause:** Supabase Storage bucket `problem-images` either doesn't exist or has no RLS policies allowing uploads.

---

## ✅ Step-by-Step Setup

### 1. Create Storage Bucket

1. Go to **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your project: **ahcndokbcggdymszuhpn**
3. Click **Storage** in the left sidebar
4. Click **New bucket** button
5. Configure bucket:
   - **Name:** `problem-images`
   - **Public bucket:** ✅ **Checked** (so thumbnails can be viewed without auth)
   - **File size limit:** 50 MB (optional)
   - **Allowed MIME types:** `image/png,image/jpeg,image/jpg` (optional)
6. Click **Create bucket**

---

### 2. Configure RLS Policies for Upload

After creating the bucket, you need to add policies to allow authenticated Firebase users to upload.

#### Policy 1: Allow Authenticated Users to Upload Their Own Files

1. In **Storage** → **Policies** tab
2. Click **New Policy** for the `problem-images` bucket
3. Choose **Custom** policy
4. Configure:
   - **Policy Name:** `Allow authenticated upload to own folder`
   - **Policy Definition:** `INSERT`
   - **Target roles:** `authenticated`
   - **USING expression:**
   ```sql
   (bucket_id = 'problem-images')
   ```
   - **WITH CHECK expression:**
   ```sql
   (bucket_id = 'problem-images' AND (storage.foldername(name))[1] = auth.uid()::text)
   ```

5. Click **Review** → **Save policy**

**What this does:** Allows authenticated users to upload files into folders that match their Firebase UID (e.g., `0ll8ul6UhxbDmJXigmjfJxjeroP2/thumbnails/...`)

---

#### Policy 2: Allow Public Read Access (For Viewing Thumbnails)

1. Click **New Policy** again
2. Choose **Custom** policy
3. Configure:
   - **Policy Name:** `Allow public read access`
   - **Policy Definition:** `SELECT`
   - **Target roles:** `anon, authenticated`
   - **USING expression:**
   ```sql
   (bucket_id = 'problem-images')
   ```

4. Click **Review** → **Save policy**

**What this does:** Allows anyone (authenticated or anonymous) to view/download the thumbnail images.

---

### 3. Alternative: Simpler Policy (For Testing)

If the above doesn't work immediately, you can use a simpler policy for testing:

#### Simple Upload Policy (Testing Only)

1. **New Policy** → **Custom**
2. Configure:
   - **Policy Name:** `Allow all authenticated uploads`
   - **Policy Definition:** `INSERT`
   - **Target roles:** `authenticated`
   - **USING expression:**
   ```sql
   true
   ```
   - **WITH CHECK expression:**
   ```sql
   (bucket_id = 'problem-images')
   ```

**⚠️ Warning:** This allows any authenticated user to upload anywhere in the bucket. Use only for testing!

---

## 🔐 Understanding Firebase Auth + Supabase RLS

### The Challenge

Your app uses **Firebase Authentication**, but Supabase expects **Supabase Auth** for RLS policies.

### The Solution

You need to **exchange Firebase JWT for Supabase JWT** before uploading files.

---

## 🔧 Code Fix: Exchange Firebase Token for Supabase Token

### Current Code Issue

Your `SupabaseFileService` is using Firebase UID as the path, but Supabase RLS doesn't recognize Firebase users.

### Fixed Implementation

Update `packages/geoapp/lib/services/data/supabase_file_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupabaseFileService {
  final SupabaseClient _client;

  SupabaseFileService(this._client);

  /// Upload thumbnail to Supabase Storage with Firebase user authentication
  Future<String?> uploadThumbnail(
    Uint8List bytes,
    int problemId,
    String firebaseUid,
  ) async {
    try {
      // 1. Get Firebase ID token
      final firebaseToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (firebaseToken == null) {
        debugPrint('ERROR: No Firebase token available');
        return null;
      }

      // 2. Exchange Firebase token for Supabase session
      // This signs the user into Supabase using their Firebase credentials
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.firebase,
        idToken: firebaseToken,
      );

      if (response.user == null) {
        debugPrint('ERROR: Failed to authenticate with Supabase using Firebase token');
        return null;
      }

      debugPrint('✅ Authenticated with Supabase as user: ${response.user!.id}');

      // 3. Now upload the file (RLS policies will work!)
      final fileName = 'thumbnails/problem_${problemId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '$firebaseUid/$fileName';

      debugPrint('DEBUG: Uploading to Supabase Storage: $filePath');

      final uploadResponse = await _client.storage
          .from('problem-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      debugPrint('✅ Upload successful: $uploadResponse');

      // 4. Get public URL
      final publicUrl = _client.storage
          .from('problem-images')
          .getPublicUrl(filePath);

      debugPrint('✅ Public URL: $publicUrl');
      return publicUrl;

    } catch (e, stackTrace) {
      debugPrint('ERROR: Supabase upload failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
```

---

## 🚀 Alternative: Use Service Role Key (Backend Only)

If you're uploading from a **backend** (not Flutter web), you can bypass RLS using the **service role key**:

```dart
// ⚠️ NEVER expose service_role key in Flutter web app!
// This is for backend/server-side only
final supabase = SupabaseClient(
  'https://YOUR_PROJECT.supabase.co',
  'YOUR_SERVICE_ROLE_KEY', // ← From Supabase Dashboard → Settings → API
);

// Now uploads bypass RLS
await supabase.storage.from('problem-images').uploadBinary(...);
```

**⚠️ Security Warning:** Never use `service_role` key in client-side code (Flutter web)! It bypasses all security.

---

## 📋 Quick Checklist

- [ ] Create `problem-images` bucket in Supabase Storage
- [ ] Make bucket **public** (so thumbnails are viewable)
- [ ] Add RLS policy: Allow authenticated users to upload to their own folder
- [ ] Add RLS policy: Allow public read access
- [ ] Update `SupabaseFileService` to exchange Firebase token for Supabase session
- [ ] Test: Sign in with email/password → Create problem → Check upload succeeds

---

## 🧪 Test After Setup

1. **Refresh your Flutter web app** (localhost:8080)
2. **Sign in** with email/password: `test@example.com`
3. **Create a new problem** with a canvas drawing
4. **Check browser console** for:
   ```
   ✅ Authenticated with Supabase as user: <supabase-user-id>
   ✅ Upload successful: ...
   ✅ Public URL: https://YOUR_PROJECT.supabase.co/storage/v1/object/public/problem-images/...
   ```

---

## 🎯 Expected Flow

```
Flutter App (Cloud Mode)
    ↓
1. Firebase Sign-In (email/password)
    ↓
2. Get Firebase ID Token
    ↓
3. Exchange Firebase Token → Supabase Session
    ↓
4. Upload file to Supabase Storage
    ↓ (RLS checks Supabase session)
5. RLS Policy: ✅ Allow (user authenticated + uploading to own folder)
    ↓
6. File uploaded successfully!
    ↓
7. Get public URL
    ↓
8. Save URL to Hasura database
```

---

## 🔍 Troubleshooting

### Error: "Invalid JWT"
- **Cause:** Firebase token not properly exchanged
- **Fix:** Ensure `signInWithIdToken()` is called before upload

### Error: "Bucket not found"
- **Cause:** Bucket name mismatch
- **Fix:** Verify bucket name is exactly `problem-images`

### Error: "RLS policy violation"
- **Cause:** No policy allows the operation
- **Fix:** Check policies in Supabase Dashboard → Storage → Policies

### Error: "Anonymous key requires auth"
- **Cause:** Using `anon` key but user not authenticated
- **Fix:** Call `signInWithIdToken()` first to authenticate with Supabase

---

## ✅ Summary

**The issue:** Supabase doesn't recognize Firebase users by default.

**The solution:**
1. Create `problem-images` bucket
2. Add RLS policies for uploads/reads
3. Exchange Firebase token for Supabase session **before** uploading
4. Upload file (RLS now works because Supabase knows who the user is)

**Key insight:** Firebase handles authentication, Supabase handles storage, but they need to be connected via `signInWithIdToken()`.
