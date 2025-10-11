# URGENT FIX: Thumbnail Field Configuration Issue

## Problem Identified

The `thumbnail` field exists in GraphQL schema but has **INVALID_FOREIGN_KEY** error, meaning:
- ✅ Field exists in schema
- ❌ Database foreign key not properly configured
- ❌ Cannot save problems with thumbnail references

## Error Messages

1. **GraphQL**: `create_directus_files_input` requires storage + filename_download
2. **REST API**: `Invalid foreign key for field "thumbnail" in collection "problems"`

## Root Cause

**The thumbnail field was added to the schema but not properly configured as a Many-to-One relationship with foreign key constraint.**

---

## SOLUTION: Fix Directus Schema Configuration

### Option 1: Quick Fix via SQL (RECOMMENDED)

Run this SQL to properly set up the foreign key:

```bash
docker exec -it geofrontapp_postgres psql -U directus -d directus
```

```sql
-- Check current thumbnail column
\d problems

-- If thumbnail column doesn't have foreign key, add it:
ALTER TABLE problems 
ADD CONSTRAINT problems_thumbnail_fk 
FOREIGN KEY (thumbnail) 
REFERENCES directus_files(id) 
ON DELETE SET NULL;

-- Verify
\d problems

-- Exit
\q
```

### Option 2: Fix via Directus Admin UI (PROPER WAY)

1. Open Directus Admin: http://192.168.1.3:8055/admin

2. Go to: **Settings → Data Model → problems**

3. **Delete the existing `thumbnail` field** (if misconfigured)

4. **Create new field:**
   - Click "+ Create Field"
   - Select **"Many to One"** (relationship type)
   - Related Collection: **`directus_files`**
   - Field Key: **`thumbnail`**
   - Interface: **"File"** or "Image"
   - Make it **Optional/Nullable**

5. **Save** and wait for schema to update

6. **Test** with curl:
   ```bash
   curl -X POST http://192.168.1.3:8055/items/problems \
     -H "Content-Type: application/json" \
     -d '{
       "title":"Test",
       "description":"Test",
       "difficulty":"beginner",
       "category":"geometry",
       "thumbnail":"d4428061-5c50-4b34-b09c-664983b6b65d"
     }'
   ```

---

## Why This Happened

The schema introspection shows the field exists in GraphQL, but:
- The field might have been created manually in database
- Or created through migrations without proper relationship setup
- The foreign key constraint is missing/broken

---

## After Fix

Once the foreign key is properly set up:

✅ REST API will accept: `"thumbnail": "file-id-string"`
✅ GraphQL will work with simple ID reference
✅ Problems will save with thumbnails
✅ Cascading deletes will work properly

---

## Test After Fix

```bash
# Should succeed:
curl -X POST http://192.168.1.3:8055/items/problems \
  -H "Content-Type: application/json" \
  -d '{
    "title":"Test Thumbnail",
    "description":"Testing after fix",
    "difficulty":"beginner",
    "category":"geometry",
    "thumbnail":"d4428061-5c50-4b34-b09c-664983b6b65d"
  }' | jq '.'
```

Should return:
```json
{
  "data": {
    "id": "...",
    "title": "Test Thumbnail",
    "thumbnail": "d4428061-5c50-4b34-b09c-664983b6b65d"
  }
}
```

---

## Priority

🔴 **CRITICAL** - This blocks thumbnail feature completely

**Action Required**: Fix the Directus schema configuration before thumbnail feature can work.
