# Supabase Cloud Setup Guide

Complete setup for Supabase backend with Firebase authentication.

## Table of Contents
1. [Database Schema](#database-schema)
2. [Row Level Security](#row-level-security)
3. [Hasura Configuration](#hasura-configuration)
4. [Storage Setup](#storage-setup)

---

## Database Schema

### Step 1: Drop Existing Tables

Run in **Supabase SQL Editor**:

```sql
-- Drop existing tables
DROP TABLE IF EXISTS problems CASCADE;
DROP TABLE IF EXISTS images CASCADE;
```

### Step 2: Create Tables

```sql
-- Images/Files table (matches Directus files structure)
CREATE TABLE images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  storage_key TEXT NOT NULL,           -- Supabase storage path
  filename TEXT,
  mime TEXT,
  size BIGINT,
  width INTEGER,
  height INTEGER,
  thumb_key TEXT,                      -- Thumbnail storage path
  title TEXT,
  description TEXT,
  owner_uid TEXT,                      -- Firebase UID
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Problems table (matches Directus problems structure)
CREATE TABLE problems (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT,                     -- 'easy', 'medium', 'hard'
  category TEXT,                       -- 'geometry', 'algebra', etc.
  geometry_data JSONB,                 -- GeoDraw canvas state
  solution TEXT,
  scalar_constraints JSONB,            -- Constraint definitions
  object_constraints JSONB,
  scalar_proof JSONB,                  -- Proof steps
  object_proof JSONB,
  status TEXT DEFAULT 'draft',         -- 'draft', 'published'
  image_id UUID REFERENCES images(id) ON DELETE SET NULL,
  owner_uid TEXT,                      -- Firebase UID
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### Step 3: Create Indexes

```sql
-- Indexes for performance
CREATE INDEX idx_problems_owner ON problems(owner_uid);
CREATE INDEX idx_problems_status ON problems(status);
CREATE INDEX idx_problems_created ON problems(created_at DESC);
CREATE INDEX idx_images_owner ON images(owner_uid);
```

### Step 4: Create Update Trigger

```sql
-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_problems_updated_at BEFORE UPDATE ON problems
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_images_updated_at BEFORE UPDATE ON images
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## Row Level Security (RLS)

### Enable RLS

```sql
ALTER TABLE problems ENABLE ROW LEVEL SECURITY;
ALTER TABLE images ENABLE ROW LEVEL SECURITY;
```

### Problems Table Policies

```sql
-- CREATE: Users can create problems (owner_uid auto-set)
CREATE POLICY "Users can create own problems"
  ON problems FOR INSERT
  WITH CHECK (auth.uid()::text = owner_uid);

-- READ: Users can read their own drafts OR published problems
CREATE POLICY "Users can read own or published problems"
  ON problems FOR SELECT
  USING (
    owner_uid = auth.uid()::text 
    OR status = 'published'
  );

-- UPDATE: Users can only update their own problems (can't change owner_uid)
CREATE POLICY "Users can update own problems"
  ON problems FOR UPDATE
  USING (owner_uid = auth.uid()::text)
  WITH CHECK (owner_uid = auth.uid()::text);

-- DELETE: Users can only delete their own problems
CREATE POLICY "Users can delete own problems"
  ON problems FOR DELETE
  USING (owner_uid = auth.uid()::text);
```

### Images Table Policies

```sql
-- CREATE: Users can upload images
CREATE POLICY "Users can upload images"
  ON images FOR INSERT
  WITH CHECK (auth.uid()::text = owner_uid);

-- READ: Users can read their own images or images linked to accessible problems
CREATE POLICY "Users can read accessible images"
  ON images FOR SELECT
  USING (
    owner_uid = auth.uid()::text
    OR EXISTS (
      SELECT 1 FROM problems 
      WHERE problems.image_id = images.id 
      AND (problems.owner_uid = auth.uid()::text OR problems.status = 'published')
    )
  );

-- UPDATE: Users can update own images
CREATE POLICY "Users can update own images"
  ON images FOR UPDATE
  USING (owner_uid = auth.uid()::text)
  WITH CHECK (owner_uid = auth.uid()::text);

-- DELETE: Users can delete own images
CREATE POLICY "Users can delete own images"
  ON images FOR DELETE
  USING (owner_uid = auth.uid()::text);
```

---

## Hasura Configuration

### Step 1: Connect to Supabase Database

**IMPORTANT:** Get your database password from **Supabase Dashboard → Settings → Database → Connection String** (click "Show password")

**Recommended: Use Session Pooler (IPv4 compatible)**

```
postgresql://postgres.ahcndokbcggdymszuhpn:URL_ENCODED_PASSWORD@aws-0-us-east-1.pooler.supabase.com:5432/postgres
```

**Alternative: Transaction Pooler (port 6543)**

```
postgresql://postgres.ahcndokbcggdymszuhpn:URL_ENCODED_PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

**Note:** 
- **Password**: Use the database password from Supabase (NOT your Supabase account password)
- **Username format for pooler**: `postgres.PROJECT_REF` (e.g., `postgres.ahcndokbcggdymszuhpn`)
- **URL-encode special characters**: `%` → `%25`, `@` → `%40`, `;` → `%3B`, etc.
- Direct connection (port 5432 without pooler) may fail due to IPv6
- This is PostgreSQL authentication, NOT Firebase user authentication



Transaction pooler

postgresql://postgres.ahcndokbcggdymszuhpn:AXrYf%255r%2AbV2KQR@aws-1-us-east-1.pooler.supabase.com:6543/postgres


### Step 2: Track Tables

1. Data → public → Track `problems` table
2. Data → public → Track `images` table
3. Track foreign key relationship: `problems.image_id → images.id`

### Step 3: Configure Firebase JWT

**Environment Variable:** `HASURA_GRAPHQL_JWT_SECRET`

```json
{
  "type": "RS256",
  "jwk_url": "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  "audience": "aksharaintelligence-41f4a",
  "issuer": "https://securetoken.google.com/aksharaintelligence-41f4a",
  "claims_map": {
    "x-hasura-default-role": "user",
    "x-hasura-allowed-roles": ["user"],
    "x-hasura-user-id": "user_id"
  }
}
```

### Step 4: Configure Permissions

#### Problems Table - "user" role

**SELECT Permission:**
```yaml
Row select permission:
  Custom check:
    _or:
      - owner_uid: { _eq: X-Hasura-User-Id }
      - status: { _eq: "published" }

Column select permissions:
  - id
  - title
  - description
  - difficulty
  - category
  - geometry_data
  - solution
  - scalar_constraints
  - object_constraints
  - scalar_proof
  - object_proof
  - status
  - image_id
  - owner_uid
  - created_at
  - updated_at
```

**INSERT Permission:**
```yaml
Row insert permission:
  Custom check:
    owner_uid: { _eq: X-Hasura-User-Id }

Column insert permissions:
  - title
  - description
  - difficulty
  - category
  - geometry_data
  - solution
  - scalar_constraints
  - object_constraints
  - scalar_proof
  - object_proof
  - image_id

Column presets:
  owner_uid: X-Hasura-User-Id
  status: "draft"
```

**UPDATE Permission:**
```yaml
Row update permission:
  Custom check:
    owner_uid: { _eq: X-Hasura-User-Id }

Post-update check:
  owner_uid: { _eq: X-Hasura-User-Id }

Column update permissions:
  - title
  - description
  - difficulty
  - category
  - geometry_data
  - solution
  - scalar_constraints
  - object_constraints
  - scalar_proof
  - object_proof
  - status
  - image_id
```

**DELETE Permission:**
```yaml
Row delete permission:
  Custom check:
    owner_uid: { _eq: X-Hasura-User-Id }
```

#### Images Table - "user" role

**SELECT Permission:**
```yaml
Row select permission:
  Custom check:
    _or:
      - owner_uid: { _eq: X-Hasura-User-Id }
      - _exists:
          _table: { schema: "public", name: "problems" }
          _where:
            _and:
              - image_id: { _eq: id }
              - _or:
                  - owner_uid: { _eq: X-Hasura-User-Id }
                  - status: { _eq: "published" }

Column select permissions: (all columns)
```

**INSERT Permission:**
```yaml
Row insert permission:
  Custom check:
    owner_uid: { _eq: X-Hasura-User-Id }

Column insert permissions:
  - storage_key
  - filename
  - mime
  - size
  - width
  - height
  - thumb_key
  - title
  - description

Column presets:
  owner_uid: X-Hasura-User-Id
```

**UPDATE Permission:**
```yaml
Row update permission:
  Custom check:
    owner_uid: { _eq: X-Hasura-User-Id }

Post-update check:
  owner_uid: { _eq: X-Hasura-User-Id }

Column update permissions:
  - storage_key
  - filename
  - mime
  - size
  - width
  - height
  - thumb_key
  - title
  - description
```

**DELETE Permission:**
```yaml
Row delete permission:
  Custom check:
    owner_uid: { _eq: X-Hasura-User-Id }
```

---

## Storage Setup

### Step 1: Create Storage Bucket

In **Supabase Dashboard** → Storage:

1. Create bucket: `problem-images`
2. Make it **public** for reading (or use signed URLs)

### Step 2: Storage Policies

```sql
-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload own images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'problem-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to read their own images + public images
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

### Storage Path Structure

```
problem-images/
  {firebase_uid}/
    thumbnails/
      {problem_id}.png
    original/
      {problem_id}.png
  public/
    default-thumbnail.png
```

---

## Verification Checklist

- [ ] Tables created (problems, images)
- [ ] Indexes created
- [ ] Update triggers working
- [ ] RLS enabled on both tables
- [ ] All RLS policies created
- [ ] Hasura connected to Supabase DB
- [ ] Tables tracked in Hasura
- [ ] Firebase JWT configured in Hasura
- [ ] Hasura permissions configured for both tables
- [ ] Storage bucket created
- [ ] Storage policies configured
- [ ] Test Firebase auth → Hasura token validation
- [ ] Test problem CRUD with RLS
- [ ] Test file upload to storage

---

## Firebase Configuration

Your Firebase project is already configured in `env_config.dart`:

```dart
Firebase Project: aksharaintelligence-41f4a
API Key: AIzaSyBJY_qpHKvCZerJrXAuZ9kFWWJKzHqDq3c
Auth Domain: aksharaintelligence-41f4a.firebaseapp.com
```

Firebase tokens will contain:
- `user_id`: Firebase UID (maps to `owner_uid` in Postgres)
- `iss`: `https://securetoken.google.com/aksharaintelligence-41f4a`
- `aud`: `aksharaintelligence-41f4a`

---

## Testing

### Test Authentication Flow

```bash
# 1. Sign in with Firebase (get token)
# 2. Send GraphQL query with token

curl -X POST https://premium-turkey-36.hasura.app/v1/graphql \
  -H "Authorization: Bearer <firebase_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { problems { id title owner_uid } }"
  }'
```

### Expected Behavior

✅ User can create problems (owner_uid auto-set)
✅ User can read own drafts
✅ User can read published problems from others
✅ User can update/delete only own problems
✅ User cannot change owner_uid
✅ User cannot read other users' drafts

---

## Troubleshooting

### "JWTInvalid" error
- Verify JWT secret in Hasura matches Firebase project
- Check token expiration (Firebase tokens expire after 1 hour)
- Verify `iss` and `aud` match your Firebase project

### Permission denied errors
- Check RLS policies are enabled
- Verify `owner_uid` matches Firebase UID
- Check Hasura permissions configured correctly

### Storage upload fails
- Verify storage bucket exists and is public
- Check storage policies
- Ensure Firebase UID in path matches authenticated user

---

## Production Deployment

1. **Build Flutter app with cloud flag:**
   ```powershell
   flutter build web --dart-define=USE_DIRECTUS=false
   ```

2. **Verify local config removed:**
   ```powershell
   cd build\web
   Select-String -Pattern "192.168.1.3" -Path *.js
   # Should return NOTHING
   ```

3. **Deploy to hosting:**
   - Firebase Hosting
   - Vercel
   - Netlify
   - etc.

4. **Set environment variables if needed:**
   - `HASURA_GRAPHQL_ENDPOINT`
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

All done! 🎉
