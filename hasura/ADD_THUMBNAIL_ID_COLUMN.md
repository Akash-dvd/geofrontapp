# Add thumbnail_id Column to Problems Table

## 🎯 Purpose

Add `thumbnail_id` column to the `problems` table in **Supabase Postgres** (accessed via Hasura) to store Supabase Storage file paths directly.

---

## 🏗️ Architecture Note

**Important:** Hasura uses **Supabase's Postgres database** as its data source. So:
- Run SQL in **Supabase SQL Editor** (easier) OR **Hasura Console** (same database)
- Hasura will automatically see the new column
- GraphQL schema will update automatically

---

## 📋 Current Schema vs New Schema

### Current Schema (Complex)
```
problems → image_id (FK) → images → thumb_key (storage path)
```

### New Schema (Simple)
```
problems → thumbnail_id (storage path directly)
```

**Why simpler?** No need to create a separate image record for each thumbnail.

---

## 🚀 SQL Command

Run this in **Supabase SQL Editor**: https://supabase.com/dashboard/project/ahcndokbcggdymszuhpn/sql

```sql
-- Add thumbnail_id column to problems table
ALTER TABLE problems 
ADD COLUMN IF NOT EXISTS thumbnail_id TEXT;

-- Add comment explaining the field
COMMENT ON COLUMN problems.thumbnail_id IS 'Supabase Storage path for problem thumbnail (e.g., {firebase-uid}/thumbnails/{filename}.png)';

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'problems'
AND column_name IN ('image_id', 'thumbnail_id')
ORDER BY ordinal_position;
```

---

## ✅ Expected Result

You should see both columns (we're keeping `image_id` for backwards compatibility):

| column_name | data_type | is_nullable |
|-------------|-----------|-------------|
| image_id | uuid | YES |
| **thumbnail_id** | **text** | **YES** |

**Note:** Both fields can coexist. You can use `thumbnail_id` for new problems and keep `image_id` for any existing problems that used the old system.

---

## 🔍 Check if Column Already Exists

```sql
-- Check if thumbnail_id column exists
SELECT EXISTS (
  SELECT 1 
  FROM information_schema.columns 
  WHERE table_name = 'problems' 
  AND column_name = 'thumbnail_id'
) AS column_exists;
```

If it returns `true`, the column already exists and you're good to go!

---

## 📊 How to Run This

### Option 1: Supabase SQL Editor (Recommended)

Since Hasura is using Supabase's Postgres database:

1. Go to: https://supabase.com/dashboard/project/ahcndokbcggdymszuhpn/sql
2. Click **"New Query"**
3. Paste the SQL command above
4. Click **"Run"** or press `Ctrl+Enter`

### Option 2: Hasura Console

1. Go to: https://cloud.hasura.io/projects
2. Select your project: **premium-turkey-36**
3. Click **"Launch Console"**
4. Go to **Data** tab → **SQL** section
5. Paste the SQL command above
6. Click **"Run"**

**Both work! Use whichever you prefer.**

---

## 🧪 Test After Adding

Try creating a problem again in your Flutter app. You should see:

```
✅ GraphQL AuthLink: Got token for user 0ll8ul6UhxbDmJXigmjfJxjeroP2
DEBUG: BLoC received CreateProblem event
DEBUG: Title: test problem
DEBUG: ThumbnailId: 0ll8ul6UhxbDmJXigmjfJxjeroP2/thumbnails/temp_xxx.png
DEBUG: Problem created successfully
DEBUG: New problem ID: ...
```

---

## ⚠️ Important Notes

1. **Hasura uses Supabase's Postgres database** - they share the same database
2. The `thumbnail_id` stores the **path** to the file in Supabase Storage
3. The actual thumbnail image is stored in Supabase Storage bucket `problem-images`
4. The full public URL is constructed as:
   ```
   https://YOUR_PROJECT.supabase.co/storage/v1/object/public/problem-images/{thumbnail_id}
   ```
5. The old `images` table with `thumb_key` is not needed for this simple approach

---

## 🎯 Data Flow

```
1. User creates problem with drawing
   ↓
2. Canvas captured as PNG
   ↓
3. Upload to Supabase Storage
   → Returns: "0ll8ul6UhxbDmJXigmjfJxjeroP2/thumbnails/temp_xxx.png"
   ↓
4. Save problem to Hasura with thumbnail_id
   → Field: thumbnail_id = "0ll8ul6UhxbDmJXigmjfJxjeroP2/thumbnails/temp_xxx.png"
   ↓
5. When displaying, construct URL:
   → https://YOUR_PROJECT.supabase.co/storage/v1/object/public/problem-images/{thumbnail_id}
```

---

## ✅ Success Criteria

After adding the column and testing:

- [ ] SQL command runs without errors
- [ ] Column `thumbnail_id` appears in table schema
- [ ] Flutter app can create problems with thumbnails
- [ ] GraphQL mutation succeeds
- [ ] Problem created with thumbnail_id stored in database

---

**Run the SQL command now to fix the "field not found" error!** 🚀
