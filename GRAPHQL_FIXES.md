# GraphQL Fixes for Thumbnail Feature

## Problem Summary

When adding thumbnail support to the problems collection with a Many-to-One relationship to `directus_files`, encountered multiple GraphQL validation errors.

---

## ✅ Fix 1: Subfield Selection Required

### Error
```
Field "thumbnail" of type "directus_files" must have a selection of subfields. 
Did you mean "thumbnail { ... }"?
```

### Root Cause
`thumbnail` is a relationship field (Many-to-One), not a scalar. GraphQL requires specifying which fields to retrieve from the related object.

### Solution
```graphql
# ❌ WRONG
query {
  problems {
    id
    title
    thumbnail
  }
}

# ✅ CORRECT
query {
  problems {
    id
    title
    thumbnail {
      id
    }
  }
}
```

**Applied to:**
- `getAllProblems` query
- `getProblemById` query
- `createProblem` mutation response
- `updateProblem` mutation response

---

## ✅ Fix 2: Mutation Variable Type

### Error
```
Variable "$thumbnail" of type "String" used in position expecting type "create_directus_files_input".
```

### Root Cause
For Many-to-One relationships, Directus expects the related item's ID to be passed as type `ID`, not `String`.

### Solution
```graphql
# ❌ WRONG
mutation CreateProblem($thumbnail: String) {
  create_problems_item(data: { thumbnail: $thumbnail }) {
    id
  }
}

# ✅ CORRECT
mutation CreateProblem($thumbnail: ID) {
  create_problems_item(data: { thumbnail: $thumbnail }) {
    id
  }
}
```

**Applied to:**
- `createProblem` mutation parameter
- `updateProblem` mutation parameter

---

## ✅ Fix 3: MIME Type for Image Upload

### Error
Directus stores file as `application/octet-stream` with `width: null, height: null`

### Root Cause
HTTP multipart upload didn't specify content type, so Directus couldn't detect it's an image.

### Solution
```dart
// ❌ WRONG
request.files.add(
  http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
);

// ✅ CORRECT
import 'package:http_parser/http_parser.dart';

request.files.add(
  http.MultipartFile.fromBytes(
    'file',
    imageBytes,
    filename: filename,
    contentType: MediaType('image', 'png'),  // Add this!
  ),
);
```

**Result:**
```json
{
  "type": "image/png",      // ✅ Correct MIME type
  "width": 800,              // ✅ Detected
  "height": 600              // ✅ Detected
}
```

---

## 📋 Complete Mutation Example

```graphql
mutation CreateProblem(
  $title: String!
  $description: String!
  $difficulty: String!
  $category: String!
  $geometry_data: JSON
  $solution: String
  $scalar_constraints: JSON
  $object_constraints: JSON
  $scalar_proof: JSON
  $object_proof: JSON
  $thumbnail: ID                    # ✅ Use ID type
) {
  create_problems_item(data: {
    title: $title
    description: $description
    difficulty: $difficulty
    category: $category
    geometry_data: $geometry_data
    solution: $solution
    scalar_constraints: $scalar_constraints
    object_constraints: $object_constraints
    scalar_proof: $scalar_proof
    object_proof: $object_proof
    thumbnail: $thumbnail            # ✅ Pass file ID
  }) {
    id
    title
    description
    thumbnail {                      # ✅ Request subfields
      id
    }
    date_created
    date_updated
  }
}
```

### Usage in Dart/Flutter

```dart
// 1. Upload image to Directus
final fileService = DirectusFileService(baseUrl: 'http://192.168.1.3:8055');
final fileId = await fileService.uploadImage(
  imageBytes: pngBytes,
  filename: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.png',
);

// 2. Create problem with thumbnail
context.read<ProblemBloc>().add(
  CreateProblem(
    title: 'My Problem',
    description: 'Description',
    // ... other fields
    thumbnailId: fileId,  // Pass the file ID as String
  ),
);

// 3. GraphQL variables will be:
{
  "title": "My Problem",
  "description": "Description",
  "thumbnail": "f24a9edb-d51c-4b2d-ac7b-3f45e4bbc4a4"  // File UUID
}
```

---

## 🎯 Key Takeaways

1. **Relationship fields** always need subfield selection in queries
2. **Many-to-One IDs** should use `ID` type in mutations, not `String`
3. **File uploads** need explicit `contentType` for proper metadata detection
4. **Parse responses** that can be either scalar (mutations) or object (queries)

---

## 📚 References

- [Directus GraphQL Docs](https://docs.directus.io/reference/graphql.html)
- [GraphQL Many-to-One Relationships](https://docs.directus.io/reference/graphql.html#many-to-one)
- [Directus Files API](https://docs.directus.io/reference/files.html)
