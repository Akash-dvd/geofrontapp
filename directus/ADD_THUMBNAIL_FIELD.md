# Add Thumbnail Field to Problems Collection

This guide shows how to add a thumbnail/image field to the `problems` collection in Directus to store canvas screenshots.

## Prerequisites

- Directus admin access at http://192.168.1.3:8055
- `problems` collection already exists

## Step 1: Open Directus Admin

1. Navigate to http://192.168.1.3:8055/admin
2. Log in with your admin credentials

## Step 2: Navigate to Problems Collection

1. Click on **Settings** (gear icon) in the sidebar
2. Click on **Data Model**
3. Find and click on the **problems** collection

## Step 3: Add Thumbnail Field

1. Click **+ Create Field** button
2. Select **"Many to One"** relationship type
3. Configure the field:
   - **Field Name**: `thumbnail`
   - **Related Collection**: `directus_files`
   - **Display Template**: `{{title}}` (optional)
   - **Interface**: File (Image)
   
4. In the **Interface** tab:
   - Select "Image" interface
   - Configure allowed file types: `image/jpeg`, `image/png`, `image/webp`
   - Set folder: (optional - create a "thumbnails" folder)

5. In the **Field** tab:
   - Check **"Nullable"** (thumbnail is optional)

6. Click **Save**

## Step 4: Update Public Role Permissions

1. Go to **Settings** → **Access Control** → **Public** role
2. Find the **problems** collection
3. Ensure the **thumbnail** field is included in read permissions:
   - Under **Read** permissions, check that `thumbnail` is in the allowed fields list
   - If not, add it to the field list

4. Also update **directus_files** collection permissions:
   - Public role should have **Read** access to files
   - This allows fetching thumbnail images

5. Click **Save**

## Step 5: Verify Schema

Test with a GraphQL query:

```graphql
query TestThumbnail {
  problems(limit: 1) {
    id
    title
    thumbnail
  }
}
```

The `thumbnail` field should now be available and will contain the Directus file ID when set.

## Using Thumbnails in the App

### Uploading a Thumbnail

```dart
// Capture canvas as PNG
final imageBytes = await CanvasCapture.captureAsPng(
  dagManager: dagManager,
  width: 800,
  height: 600,
);

// Upload to Directus
final fileService = DirectusFileService(
  baseUrl: 'http://192.168.1.3:8055',
);
final fileId = await fileService.uploadImage(
  imageBytes: imageBytes!,
  filename: 'problem_${problem.id}_thumbnail.png',
  title: 'Thumbnail for ${problem.title}',
);

// Save problem with thumbnail
final problem = Problem(
  // ... other fields
  thumbnailId: fileId,
);
```

### Displaying Thumbnails

```dart
// Get thumbnail URL
final fileService = DirectusFileService(
  baseUrl: 'http://192.168.1.3:8055',
);

if (problem.thumbnailId != null) {
  final thumbnailUrl = fileService.getFileUrl(
    problem.thumbnailId!,
    width: 300,
    height: 200,
    fit: 'cover',
    quality: 80,
  );
  
  // Display in UI
  Image.network(thumbnailUrl);
}
```

## Directus File URLs

Files are accessible at:
- Full size: `http://192.168.1.3:8055/assets/{fileId}`
- Resized: `http://192.168.1.3:8055/assets/{fileId}?width=300&height=200&fit=cover&quality=80`

Parameters:
- `width`: Target width in pixels
- `height`: Target height in pixels
- `fit`: `cover` (crop), `contain` (fit inside), `inside`, `outside`
- `quality`: 1-100 (JPEG quality)

## Testing

### Create Problem with Thumbnail

```bash
# First upload image
curl -X POST http://192.168.1.3:8055/files \
  -F "file=@thumbnail.png" \
  -F "title=Test Thumbnail"

# Response will contain file ID, e.g., "abc123"

# Then create problem with thumbnail
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { create_problems_item(data: { title: \"Test\", description: \"Test\", difficulty: \"beginner\", category: \"geometry\", thumbnail: \"abc123\" }) { id title thumbnail } }"
  }'
```

### Fetch Problem with Thumbnail

```bash
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { problems { id title thumbnail } }"
  }'
```

## Troubleshooting

### Thumbnail Not Showing
- Check that Public role has read access to `directus_files`
- Verify file was uploaded successfully
- Check network tab for 404 errors on asset URLs

### Upload Failing
- Ensure `directus_files` collection has create permissions
- Check file size limits in Directus settings
- Verify file type is allowed (PNG, JPEG, WebP)

### Permission Errors
- Go to Settings → Access Control
- Update Public role permissions for both `problems` and `directus_files`
- Ensure thumbnail field is in allowed fields list

## Summary

After completing these steps:
1. ✅ `thumbnail` field added to problems collection
2. ✅ Field linked to `directus_files` collection  
3. ✅ Public read permissions configured
4. ✅ GraphQL queries include thumbnail field
5. ✅ Ready to upload and display canvas screenshots

The thumbnail field stores the Directus file ID, which can be used to construct URLs for displaying images at various sizes.
