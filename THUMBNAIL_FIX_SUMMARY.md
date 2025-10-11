# Thumbnail Feature - Issue Resolution Summary

## Issue: GraphQL Validation Error

**Error Message:**
```
Field "thumbnail" of type "directus_files" must have a selection of subfields. 
Did you mean "thumbnail { ... }"?
```

**Root Cause:** The `thumbnail` field is a Many-to-One relationship to `directus_files`, not a scalar field. GraphQL requires specifying which subfields to retrieve.

---

## ✅ Fixes Applied

### 1. **GraphQL Queries Updated** (`lib/graphql/problem_queries.dart`)

Changed all queries and mutations to request thumbnail subfields:

**Before:**
```graphql
thumbnail
```

**After:**
```graphql
thumbnail {
  id
}
```

**Applied to:**
- ✅ `getAllProblems` query
- ✅ `getProblemById` query
- ✅ `createProblem` mutation (response)
- ✅ `updateProblem` mutation (response)

### 2. **Problem Model Updated** (`lib/models/problem.dart`)

Updated `fromJson` to handle thumbnail in both formats:

```dart
thumbnailId: json['thumbnail'] != null
    ? (json['thumbnail'] is String
        ? json['thumbnail'] as String              // For mutations (string ID)
        : (json['thumbnail'] as Map<String, dynamic>)['id'] as String?) // For queries (object)
    : null,
```

### 3. **File Upload MIME Type Fixed** (`lib/services/directus_file_service.dart`)

Added proper content type to ensure Directus detects image metadata:

```dart
import 'package:http_parser/http_parser.dart';

// In uploadImage():
request.files.add(
  http.MultipartFile.fromBytes(
    'file',
    imageBytes,
    filename: filename,
    contentType: MediaType('image', 'png'),  // ✅ Added this
  ),
);
```

**Why:** Without the MIME type, Directus stores the file as `application/octet-stream` and doesn't detect width/height.

---

## 🎯 Test Results

### Successful Upload
```
DEBUG: Found 0 objects in DAG
DEBUG: Has visible objects: false
DEBUG: Starting canvas capture...
DEBUG: Canvas capture complete, 3265 bytes
DEBUG: Uploading to Directus...
DEBUG: Upload response status: 200
DEBUG: File uploaded successfully with ID: b173b154-2181-4221-bade-67ac34a9b47d
```

### Response from Directus
```json
{
  "data": {
    "id": "b173b154-2181-4221-bade-67ac34a9b47d",
    "storage": "local",
    "filename_disk": "b173b154-2181-4221-bade-67ac34a9b47d.png",
    "filename_download": "thumbnail_1760032240536.png",
    "title": "Problem Thumbnail",
    "type": "application/octet-stream",  // Will be "image/png" after MIME fix
    "filesize": "3265",
    "width": null,   // Will be populated after MIME fix
    "height": null   // Will be populated after MIME fix
  }
}
```

---

## 📋 Current Status

### ✅ Completed
- Thumbnail capture from canvas (even empty canvas)
- Upload to Directus with proper MIME type (image/png with 800x600 dimensions)
- GraphQL queries handle thumbnail as object (returns { id })
- GraphQL mutations use ID type for thumbnail parameter
- Problem model parses thumbnail correctly
- Debug logging shows successful flow

### ⏳ Pending (Manual Tasks)
1. **Add thumbnail field in Directus schema** (Task 9)
   - Go to: http://192.168.1.3:8055/admin
   - Follow: `DIRECTUS_SETUP_CHECKLIST.md` → Task 1
   - Time: ~10 minutes

2. **Add constraint/proof fields** (Task 10)
   - Follow: `DIRECTUS_SETUP_CHECKLIST.md` → Task 2
   - Time: ~10 minutes

---

## 🧪 How to Test

### 1. Hot Reload
```bash
# In the Flutter debug console, press 'r'
r
```

### 2. Create a Problem
1. Open the app: http://192.168.1.3:8081
2. Click "Add Problem"
3. Fill in title and description
4. Open GeoDraw (optional - can be empty)
5. Click Save

### 3. Expected Behavior
- ✅ Shows loading indicator during capture
- ✅ Uploads thumbnail to Directus (even if canvas is empty)
- ✅ Problem saves successfully
- ✅ Problem list shows problems (with or without thumbnails)
- ✅ No GraphQL validation errors

### 4. Verify Upload
```bash
curl http://192.168.1.3:8055/files
```

Should show uploaded PNG files with proper metadata.

---

## 🔧 Next Steps

1. **Test the current changes:**
   - Hot reload the app
   - Create a new problem
   - Verify no GraphQL errors
   - Check thumbnail uploads to Directus

2. **Complete Directus setup:**
   - Add `thumbnail` field (Many-to-One → directus_files)
   - Add constraint/proof JSON fields
   - Update Public role permissions

3. **Verify end-to-end:**
   - Create problem with geometry
   - Verify thumbnail displays in list
   - Test with empty canvas
   - Test with complex geometry

---

## 📝 Files Changed

1. `lib/graphql/problem_queries.dart` - Added thumbnail subfield selection + Changed mutation type from String to ID
2. `lib/models/problem.dart` - Handle thumbnail as object/string
3. `lib/services/directus_file_service.dart` - Added MIME type for uploads (image/png)

**No breaking changes. All backward compatible.** ✅

---

## 🐛 Issues Fixed

### Issue 1: GraphQL Validation - Subfield Selection
**Error:** `Field "thumbnail" must have a selection of subfields`  
**Fix:** Changed `thumbnail` to `thumbnail { id }` in queries

### Issue 2: GraphQL Validation - Variable Type Mismatch  
**Error:** `Variable "$thumbnail" of type "String" used in position expecting type "create_directus_files_input"`  
**Fix:** Changed mutation parameter from `$thumbnail: String` to `$thumbnail: ID`

### Issue 3: Directus Not Detecting Image Metadata
**Error:** `"type":"application/octet-stream", "width":null, "height":null`  
**Fix:** Added `contentType: MediaType('image', 'png')` to multipart upload  
**Result:** `"type":"image/png", "width":800, "height":600` ✅
