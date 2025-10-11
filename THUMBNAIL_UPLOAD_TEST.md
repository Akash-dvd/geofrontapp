# Thumbnail Upload & Link Test

## The Problem
Files are being uploaded but not persisting in the `directus_files` table, causing foreign key constraint violations when trying to link them to problems.

## Quick Test

1. **Upload a test file NOW**:
```bash
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > /tmp/test.png

curl -X POST http://192.168.1.3:8055/files \
  -F "file=@/tmp/test.png" \
  -F "title=Test Upload" | jq '.'
```

2. **Immediately check if it's in the database**:
```bash
# Get the ID from above response, then:
FILE_ID="<paste-id-here>"

docker exec geofrontapp_postgres psql -U geofrontapp_user -d geofrontapp -c "SELECT id, filename_disk FROM directus_files WHERE id='$FILE_ID';"
```

3. **If it exists, try creating a problem with it**:
```bash
curl -X POST http://192.168.1.3:8055/items/problems \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"Test\",\"description\":\"Test\",\"difficulty\":\"beginner\",\"category\":\"geometry\",\"thumbnail\":\"$FILE_ID\"}" | jq '.'
```

## Expected Results

- ✅ File upload returns 200 with file ID
- ✅ File exists in `directus_files` table
- ✅ Problem creation succeeds with thumbnail

## If File Doesn't Persist

**Possible causes**:
1. **Transaction rollback** - Directus might be rolling back the file insert
2. **Permission issue** - Public role can't create files
3. **Storage issue** - Can't write to uploads directory

**Fix**: Go to Directus Admin → Settings → Roles & Permissions → Public role → directus_files collection → Enable CREATE permission

## Alternative: Use Directus Admin to Upload

1. Open http://192.168.1.3:8055/admin
2. Go to File Library
3. Upload a file manually
4. Copy the file ID
5. Test creating a problem with that ID via curl or Flutter app

This will confirm whether the issue is with programmatic uploads vs manual uploads.
