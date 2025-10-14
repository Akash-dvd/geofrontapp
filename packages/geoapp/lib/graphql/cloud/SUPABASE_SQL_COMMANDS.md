# Quick Reference: Supabase SQL Commands

Copy-paste these commands directly into Supabase SQL Editor.

---

## 1. Drop Existing Tables

```sql
DROP TABLE IF EXISTS problems CASCADE;
DROP TABLE IF EXISTS images CASCADE;
```

---

## 2. Create Schema

```sql
-- Images table
CREATE TABLE images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  storage_key TEXT NOT NULL,
  filename TEXT,
  mime TEXT,
  size BIGINT,
  width INTEGER,
  height INTEGER,
  thumb_key TEXT,
  title TEXT,
  description TEXT,
  owner_uid TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Problems table
CREATE TABLE problems (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT,
  category TEXT,
  geometry_data JSONB,
  solution TEXT,
  scalar_constraints JSONB,
  object_constraints JSONB,
  scalar_proof JSONB,
  object_proof JSONB,
  status TEXT DEFAULT 'draft',
  image_id UUID REFERENCES images(id) ON DELETE SET NULL,
  owner_uid TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_problems_owner ON problems(owner_uid);
CREATE INDEX idx_problems_status ON problems(status);
CREATE INDEX idx_problems_created ON problems(created_at DESC);
CREATE INDEX idx_images_owner ON images(owner_uid);

-- Update trigger
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

## 3. Enable RLS and Create Policies

```sql
-- Enable RLS
ALTER TABLE problems ENABLE ROW LEVEL SECURITY;
ALTER TABLE images ENABLE ROW LEVEL SECURITY;

-- Problems policies
CREATE POLICY "Users can create own problems"
  ON problems FOR INSERT
  WITH CHECK (auth.uid()::text = owner_uid);

CREATE POLICY "Users can read own or published problems"
  ON problems FOR SELECT
  USING (owner_uid = auth.uid()::text OR status = 'published');

CREATE POLICY "Users can update own problems"
  ON problems FOR UPDATE
  USING (owner_uid = auth.uid()::text)
  WITH CHECK (owner_uid = auth.uid()::text);

CREATE POLICY "Users can delete own problems"
  ON problems FOR DELETE
  USING (owner_uid = auth.uid()::text);

-- Images policies
CREATE POLICY "Users can upload images"
  ON images FOR INSERT
  WITH CHECK (auth.uid()::text = owner_uid);

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

CREATE POLICY "Users can update own images"
  ON images FOR UPDATE
  USING (owner_uid = auth.uid()::text)
  WITH CHECK (owner_uid = auth.uid()::text);

CREATE POLICY "Users can delete own images"
  ON images FOR DELETE
  USING (owner_uid = auth.uid()::text);
```

---

## 4. Storage Policies

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

---

## Verification Queries

```sql
-- Check tables created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('problems', 'images');

-- Check RLS enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('problems', 'images');

-- List all policies
SELECT schemaname, tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('problems', 'images');

-- Check indexes
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN ('problems', 'images');
```

Done! ✅
