# Supabase Storage Setup Guide

Setup guide for Supabase Storage buckets ONLY. Client uploads files directly to Supabase Storage, all data queries go through Hasura.

---

## 🎯 Overview

**Important Architecture Clarification:**
- ✅ **Hasura handles all data** (problems table, queries, mutations)
- ✅ **Supabase Storage handles files** (thumbnails, images)
- ✅ **Client talks to both:** Hasura for data, Supabase Storage for file uploads

**What this guide sets up:**
- Storage bucket: `problem-images` (public, for file uploads only)
- 4 RLS policies (SELECT, INSERT, UPDATE, DELETE)
- File organization: `{firebase-uid}/thumbnails/{filename}`

**What this guide does NOT set up:**
- ❌ Database tables (handled by Hasura/Postgres)
- ❌ GraphQL API (handled by Hasura)
- ❌ Data permissions (handled by Hasura)

---

## 📋 Prerequisites

- Supabase account and project created
- Project URL: `https://YOUR_PROJECT.supabase.co`
- Firebase authentication configured in your app
- Hasura already configured and pointing to Supabase Postgres database

---

## 🚀 Setup Method 1: Dashboard (Recommended)

### Step 1: Create Storage Bucket

1. Go to: https://supabase.com/dashboard/project/ahcndokbcggdymszuhpn/storage/buckets
2. Click **"New bucket"**
3. Configure:
   - **Name:** `problem-images`
   - **Public bucket:** ✅ **MUST CHECK THIS**
   - **File size limit:** `50` MB
   - **Allowed MIME types:** `image/png, image/jpeg, image/jpg, image/webp`
4. Click **"Create bucket"**

### Step 2: Create RLS Policies

Go to: https://supabase.com/dashboard/project/ahcndokbcggdymszuhpn/storage/policies

#### Policy 1: Public Read Access
- Click **"New Policy"** → Select `problem-images` bucket
- **Policy name:** `Public read access to thumbnails`
- **Allowed operation:** `SELECT`
- **Target roles:** Select **`public`**
- **Policy definition (USING):**
  ```sql
  bucket_id = 'problem-images'
  ```
- Click **"Review"** → **"Save policy"**

#### Policy 2: Authenticated Uploads
- Click **"New Policy"** → Select `problem-images` bucket
- **Policy name:** `Firebase authenticated uploads`
- **Allowed operation:** `INSERT`
- **Target roles:** Select **`public`**
- **Policy definition (WITH CHECK):**
  ```sql
  bucket_id = 'problem-images'
  ```
- Click **"Review"** → **"Save policy"**

#### Policy 3: Authenticated Updates
- Click **"New Policy"** → Select `problem-images` bucket
- **Policy name:** `Firebase authenticated updates`
- **Allowed operation:** `UPDATE`
- **Target roles:** Select **`public`**
- **USING expression:**
  ```sql
  bucket_id = 'problem-images'
  ```
- **WITH CHECK expression:**
  ```sql
  bucket_id = 'problem-images'
  ```
- Click **"Review"** → **"Save policy"**

#### Policy 4: Authenticated Deletes
- Click **"New Policy"** → Select `problem-images` bucket
- **Policy name:** `Firebase authenticated deletes`
- **Allowed operation:** `DELETE`
- **Target roles:** Select **`public`**
- **Policy definition (USING):**
  ```sql
  bucket_id = 'problem-images'
  ```
- Click **"Review"** → **"Save policy"**

---

## 🚀 Setup Method 2: SQL (If Dashboard Fails)

### Step 1: Create Bucket (Dashboard Only)

**⚠️ Note:** Bucket creation must be done via Dashboard due to permissions.

Go to: https://supabase.com/dashboard/project/ahcndokbcggdymszuhpn/storage/buckets
- Click "New bucket"
- Name: `problem-images`
- Public: ✅ Yes
- Create

### Step 2: Create Policies via SQL

Go to: https://supabase.com/dashboard/project/ahcndokbcggdymszuhpn/sql

Copy and paste this SQL script:

```sql
-- ============================================================================
-- Supabase Storage RLS Policies for problem-images bucket
-- ============================================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Public read access to thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Firebase authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Firebase authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Firebase authenticated deletes" ON storage.objects;

-- Policy 1: Allow public read access (for viewing thumbnails)
CREATE POLICY "Public read access to thumbnails"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'problem-images'
);

-- Policy 2: Allow uploads (INSERT)
CREATE POLICY "Firebase authenticated uploads"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'problem-images'
);

-- Policy 3: Allow updates (for upsert functionality)
CREATE POLICY "Firebase authenticated updates"
ON storage.objects
FOR UPDATE
TO public
USING (
  bucket_id = 'problem-images'
)
WITH CHECK (
  bucket_id = 'problem-images'
);

-- Policy 4: Allow deletes (for cleanup)
CREATE POLICY "Firebase authenticated deletes"
ON storage.objects
FOR DELETE
TO public
USING (
  bucket_id = 'problem-images'
);

-- Verify all policies created
SELECT 
  policyname,
  cmd AS operation,
  roles::text AS target_roles
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname ILIKE '%firebase%'
ORDER BY cmd, policyname;

-- Expected result: 4 policies (DELETE, INSERT, SELECT, UPDATE)
```

Click **"Run"** or press `Ctrl+Enter`.

**Expected output:** A table showing 4 policies.

---

## 🔍 Verification

Run this SQL query to verify setup:

```sql
-- Check bucket configuration
SELECT 
  id,
  name,
  public,
  file_size_limit / 1024 / 1024 AS size_limit_mb
FROM storage.buckets
WHERE id = 'problem-images';

-- Check policies
SELECT 
  policyname,
  cmd AS operation
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND (policyname ILIKE '%problem%' OR policyname ILIKE '%firebase%')
ORDER BY cmd;
```

**Expected:**
- ✅ Bucket: `problem-images`, public: `true`, size_limit_mb: `50`
- ✅ 4 policies: DELETE, INSERT, SELECT, UPDATE

---

## 🧪 Test Upload (Optional)

Test with curl after setup:

```bash
# Replace with your Supabase anon key
SUPABASE_URL="https://YOUR_PROJECT.supabase.co"
ANON_KEY="your-anon-key-from-supabase-dashboard"

# Create a test PNG file first, then:
curl -X POST \
  "$SUPABASE_URL/storage/v1/object/problem-images/test-uid/thumbnails/test.png" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: image/png" \
  --data-binary @test.png

# Expected: Success response with file path
```

---

## ⚠️ Troubleshooting

### Error: "permission denied for schema storage"

**Cause:** SQL Editor doesn't have permissions to create buckets.

**Solution:** Create bucket via Dashboard (Step 1 of Method 1), then run only the policies SQL.

---

### Error: "policy already exists"

**Cause:** Policy with that name already created.

**Solution:** Good! Skip that policy or drop it first with:
```sql
DROP POLICY IF EXISTS "policy-name-here" ON storage.objects;
```

---

### Error: "Bucket not found"

**Cause:** Bucket name mismatch or not created.

**Solution:** 
1. Check bucket exists in Dashboard → Storage
2. Verify name is exactly `problem-images` (no typos)
3. Create bucket if missing

---

### Error: "RLS policy violation" during upload

**Cause:** Policies not created or bucket not public.

**Solution:**
1. Check bucket is public: Dashboard → Storage → problem-images → Configuration
2. Verify all 4 policies exist: Dashboard → Storage → Policies
3. Run verification SQL query above

---

### Upload works but can't view file

**Cause:** Bucket not set to public.

**Solution:** 
1. Go to: Dashboard → Storage → problem-images → Configuration
2. Toggle **"Public bucket"** to ON
3. Save changes

---

## 📊 Configuration Details

### Bucket Settings
| Setting | Value | Purpose |
|---------|-------|---------|
| Name | `problem-images` | Matches app configuration |
| Public | `true` | Allows public URL access for viewing |
| Size Limit | 50 MB | Prevents abuse |
| MIME Types | `image/png`, `image/jpeg`, `image/jpg`, `image/webp` | Only images allowed |

### File Structure
```
problem-images/
  └── {firebase-uid}/
      └── thumbnails/
          ├── temp_1234567890.png
          ├── temp_1234567891.png
          └── ...
```

### Public URL Format
```
https://YOUR_PROJECT.supabase.co/storage/v1/object/public/problem-images/{firebase-uid}/thumbnails/{filename}
```

---

## 🏗️ Architecture Clarification

### How Client Interacts with Services

```
Flutter Client
    │
    ├──► Hasura GraphQL API
    │    └─► All data operations (problems, queries, mutations)
    │    └─► Connects to: Supabase Postgres Database
    │
    └──► Supabase Storage API  
         └─► File uploads/downloads only (thumbnails, images)
         └─► Returns: Storage path (saved to database via Hasura)
```

### Data Flow for Creating a Problem with Thumbnail

1. **Capture thumbnail** → PNG bytes
2. **Upload to Supabase Storage** (Client → Supabase Storage API)
   - Returns: `"uid/thumbnails/file.png"`
3. **Save problem via Hasura** (Client → Hasura → Supabase Postgres)
   - Sends: `thumbnail_id = "uid/thumbnails/file.png"`
4. **Display thumbnail** → Construct URL:
   - `https://supabase.co/.../problem-images/{thumbnail_id}`

**Key Point:** Client knows about Supabase Storage for files ONLY. All database operations go through Hasura.

---

## 🔐 Security Model

### Why Public Bucket?

**Q:** Isn't this insecure?

**A:** No, because:
1. **Firebase Auth** controls who can access the app
2. **Hasura permissions** control who can create/view problems (via GraphQL)
3. **Thumbnails are public-facing images** (displayed in UI)
4. **Supabase anon key required** for API requests
5. **File paths include Firebase UID** (prevents collisions)

### What's Protected?

- **App access:** Firebase Authentication
- **Problem data:** Hasura GraphQL permissions
- **Database queries:** Hasura row-level security
- **Upload functionality:** App checks auth before allowing upload
- **API access:** Requires Supabase anon key

### What's Public?

- **Viewing thumbnails:** Anyone with the URL can view (intended behavior)
- **Storage bucket:** Public read access enabled (for displaying images)

This is appropriate for thumbnails that are meant to be displayed publicly anyway.

---

## 🔄 Rollback (If Needed)

To remove everything:

```sql
-- Delete all policies
DROP POLICY IF EXISTS "Public read access to thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Firebase authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Firebase authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Firebase authenticated deletes" ON storage.objects;

-- Delete all files in bucket (optional)
DELETE FROM storage.objects WHERE bucket_id = 'problem-images';

-- Delete bucket (via Dashboard only)
-- Dashboard → Storage → problem-images → Settings → Delete bucket
```

---

## ✅ Checklist

- [ ] Bucket `problem-images` created
- [ ] Bucket set to **public**
- [ ] File size limit: 50 MB
- [ ] MIME types configured
- [ ] Policy 1: SELECT (public read) ✓
- [ ] Policy 2: INSERT (uploads) ✓
- [ ] Policy 3: UPDATE (updates) ✓
- [ ] Policy 4: DELETE (deletes) ✓
- [ ] Verification SQL runs successfully
- [ ] Test upload works (optional)

---

## 🚀 Next Steps

After completing this setup:

1. **Test in your Flutter app:**
   - Run app in cloud mode
   - Sign in with Firebase (email/password or anonymous)
   - Create a problem with a drawing
   - Check console for upload success

2. **Expected console output:**
   ```
   DEBUG: Uploading to Supabase Storage: {uid}/thumbnails/temp_xxx.png
   ✅ Supabase upload successful: {uid}/thumbnails/temp_xxx.png
   DEBUG: Problem created successfully
   ```

3. **Verify in Supabase Dashboard:**
   - Go to: Storage → problem-images
   - You should see files organized by Firebase UID
   - Click file → Copy URL → Open in browser (should display image)

---

## 📚 References

- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
- [Supabase RLS Policies](https://supabase.com/docs/guides/storage/security/access-control)
- [Storage Dashboard](https://supabase.com/dashboard/project/ahcndokbcggdymszuhpn/storage)
- [SQL Editor](https://supabase.com/dashboard/project/ahcndokbcggdymszuhpn/sql)

---

**Status:** Ready to use after completing setup! 🎉
