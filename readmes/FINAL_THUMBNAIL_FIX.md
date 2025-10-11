# Final Fix: Thumbnail Relationship Input Type

## The Issue

Directus GraphQL expects relationship fields to be passed as **input objects**, not raw IDs.

### Error
```
Variable "$thumbnail" of type "ID" used in position expecting type "create_directus_files_input"
```

### Root Cause
When creating/updating a problem with a Many-to-One relationship to `directus_files`, Directus expects:
```graphql
thumbnail: { id: "file-uuid" }  # ✅ Object with id field
```

NOT:
```graphql
thumbnail: "file-uuid"  # ❌ Just the ID string
```

---

## ✅ The Solution

### 1. GraphQL Mutation Variable Types

**File: `lib/graphql/problem_queries.dart`**

```graphql
mutation CreateProblem(
  $thumbnail: create_directus_files_input  # ✅ Input object type
) {
  create_problems_item(data: {
    thumbnail: $thumbnail
  }) {
    thumbnail {
      id
    }
  }
}

mutation UpdateProblem(
  $thumbnail: update_directus_files_input  # ✅ Input object type for updates
) {
  update_problems_item(data: {
    thumbnail: $thumbnail
  }) {
    thumbnail {
      id
    }
  }
}
```

### 2. BLoC Variables Formatting

**File: `lib/bloc/problem_bloc.dart`**

```dart
// In _onCreateProblem and _onUpdateProblem:
final result = await _graphQLClient.mutate(
  MutationOptions(
    document: gql(ProblemQueries.createProblem),
    variables: {
      'title': event.title,
      'description': event.description,
      // ... other fields
      'thumbnail': event.thumbnailId != null 
          ? {'id': event.thumbnailId}  // ✅ Wrap ID in object
          : null,
    },
  ),
);
```

---

## 📊 How It Works

### Full Flow

1. **Canvas Capture**
   ```dart
   final imageBytes = await CanvasCapture.captureAsPng(...);
   // Returns: Uint8List (3,265 bytes for empty canvas)
   ```

2. **Upload to Directus**
   ```dart
   final fileId = await DirectusFileService().uploadImage(
     imageBytes: imageBytes,
     filename: 'thumbnail_${timestamp}.png',
   );
   // Returns: "4d9cf706-6286-493b-aa96-8565812843b0"
   ```

3. **Create Problem with Thumbnail**
   ```dart
   context.read<ProblemBloc>().add(
     CreateProblem(
       title: 'My Problem',
       thumbnailId: fileId,  // String ID from upload
     ),
   );
   ```

4. **BLoC Formats for GraphQL**
   ```dart
   variables: {
     'thumbnail': fileId != null ? {'id': fileId} : null,
   }
   // Sends: { "thumbnail": { "id": "4d9cf706..." } }
   ```

5. **GraphQL Mutation**
   ```graphql
   mutation CreateProblem($thumbnail: create_directus_files_input) {
     create_problems_item(data: { thumbnail: $thumbnail }) {
       id
       thumbnail {
         id
       }
     }
   }
   ```

6. **Directus Response**
   ```json
   {
     "data": {
       "create_problems_item": {
         "id": "123",
         "thumbnail": {
           "id": "4d9cf706-6286-493b-aa96-8565812843b0"
         }
       }
     }
   }
   ```

---

## 🧪 Verification

### Schema Confirmed
```bash
curl -X POST http://192.168.1.3:8055/graphql -d '{
  "query": "{ __type(name: \"problems\") { fields { name type { name kind } } } }"
}'
```

**Result:**
```json
{
  "name": "thumbnail",
  "type": {
    "name": "directus_files",
    "kind": "OBJECT"
  }
}
```
✅ Field exists in schema

### Input Type Confirmed
```bash
curl -X POST http://192.168.1.3:8055/graphql -d '{
  "query": "{ __type(name: \"create_directus_files_input\") { inputFields { name } } }"
}'
```

**Result:**
```json
{
  "inputFields": [
    { "name": "id" },
    { "name": "storage" },
    { "name": "filename_disk" },
    ...
  ]
}
```
✅ Has `id` field - that's what we pass!

---

## ✅ Final Changes Summary

### Files Modified

1. **lib/graphql/problem_queries.dart**
   - `createProblem`: `$thumbnail: create_directus_files_input`
   - `updateProblem`: `$thumbnail: update_directus_files_input`

2. **lib/bloc/problem_bloc.dart**
   - `_onCreateProblem`: `'thumbnail': fileId != null ? {'id': fileId} : null`
   - `_onUpdateProblem`: `'thumbnail': fileId != null ? {'id': fileId} : null`

### No Changes Needed
- ✅ `problem_form_screen.dart` - Still passes string ID
- ✅ `problem_event.dart` - Still uses String? thumbnailId
- ✅ `problem.dart` - Still stores string ID
- ✅ `directus_file_service.dart` - Still returns string ID

**The transformation happens only in the BLoC layer!** 🎯

---

## 🎉 Expected Result

After hot reload:
```bash
# In Flutter console
r
```

Then create a problem:
- ✅ Canvas captures successfully (3,265 bytes)
- ✅ File uploads to Directus (image/png, 800x600)
- ✅ Problem saves with thumbnail relationship
- ✅ No GraphQL validation errors
- ✅ Problem appears in list

---

## 📝 Key Learnings

1. **Directus relationship fields** require input object types, not scalar IDs
2. **create_directus_files_input** has an `id` field for linking existing files
3. **The BLoC layer** is the right place to transform data formats
4. **GraphQL introspection** (`__type` queries) is essential for debugging schema issues

---

## 🔗 Related Documentation

- [Directus GraphQL Relationships](https://docs.directus.io/reference/graphql.html#one-to-many-many-to-one)
- [GraphQL Input Types](https://graphql.org/graphql-js/mutations-and-input-types/)
- [Directus Files API](https://docs.directus.io/reference/files.html)
