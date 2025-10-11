# Thumbnail Implementation Guide

## Overview
This guide explains how to implement canvas thumbnail capture and display for problems in GeoFrontApp.

## Architecture

### Components Created
1. **DirectusFileService** (`lib/services/directus_file_service.dart`) - Handles file uploads to Directus
2. **CanvasCapture** (`lib/utils/canvas_capture.dart`) - Captures GeoDraw canvas as PNG images
3. **Problem Model** - Updated with `thumbnailId` field
4. **GraphQL Queries** - Updated to include `thumbnail` field

### Data Flow
```
GeoDraw Canvas → CanvasCapture → PNG Bytes → DirectusFileService → Directus Files API → File ID → Problem.thumbnailId
```

## Implementation Steps

### 1. Update Directus Schema (Manual - 10 minutes)
Follow `directus/ADD_THUMBNAIL_FIELD.md`:
- Add `thumbnail` field (Many-to-One → directus_files)
- Configure as Image interface
- Update Public role permissions

### 2. Capture Canvas on Save

When saving a problem with geometry data, capture the canvas:

```dart
import '../services/directus_file_service.dart';
import '../utils/canvas_capture.dart';
import 'package:geodraw/geodraw.dart';

Future<String?> _captureThumbnail(Map<String, dynamic> geometryData) async {
  try {
    // Decode geometry data to DAGManager
    final decoder = GeoDrawDecoder();
    final dagManager = decoder.decode(geometryData);
    
    // Capture canvas as PNG (800x600 thumbnail)
    final imageBytes = await CanvasCapture.captureAsPng(
      dagManager: dagManager,
      width: 800,
      height: 600,
      backgroundColor: Colors.white,
      showGrid: false, // Clean thumbnail without grid
    );
    
    if (imageBytes == null) return null;
    
    // Upload to Directus
    final fileService = DirectusFileService(
      baseUrl: 'http://192.168.1.3:8055',
    );
    
    final fileId = await fileService.uploadImage(
      imageBytes: imageBytes,
      filename: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.png',
      title: 'Problem Thumbnail',
    );
    
    return fileId;
  } catch (e) {
    print('Error capturing thumbnail: $e');
    return null;
  }
}
```

### 3. Update Problem Form Screen

Modify `_saveProblem()` method in `problem_form_screen.dart`:

```dart
void _saveProblem() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  final title = _titleController.text.trim();
  final description = _descriptionController.text.trim();
  final solution = _solutionController.text.trim().isNotEmpty 
      ? _solutionController.text.trim() 
      : null;

  // Capture thumbnail if geometry data exists
  String? thumbnailId;
  if (_geometryData != null) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    thumbnailId = await _captureThumbnail(_geometryData!);
    
    // Hide loading indicator
    if (mounted) Navigator.of(context).pop();
  }

  if (widget.isEditing) {
    context.read<ProblemBloc>().add(
      UpdateProblem(
        id: widget.problem!.id,
        title: title,
        description: description,
        difficulty: _selectedDifficulty,
        category: _selectedCategory,
        geometryData: _geometryData,
        solution: solution,
        thumbnailId: thumbnailId, // Add this parameter
      ),
    );
  } else {
    context.read<ProblemBloc>().add(
      CreateProblem(
        title: title,
        description: description,
        difficulty: _selectedDifficulty,
        category: _selectedCategory,
        geometryData: _geometryData,
        solution: solution,
        thumbnailId: thumbnailId, // Add this parameter
      ),
    );
  }
}
```

### 4. Update BLoC Events

Add `thumbnailId` parameter to `CreateProblem` and `UpdateProblem` events in `problem_event.dart`:

```dart
class CreateProblem extends ProblemEvent {
  final String title;
  final String description;
  final ProblemDifficulty difficulty;
  final ProblemCategory category;
  final Map<String, dynamic>? geometryData;
  final String? solution;
  final String? thumbnailId; // Add this

  const CreateProblem({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    this.geometryData,
    this.solution,
    this.thumbnailId, // Add this
  });

  @override
  List<Object?> get props => [title, description, difficulty, category, geometryData, solution, thumbnailId];
}

class UpdateProblem extends ProblemEvent {
  final String id;
  final String title;
  final String description;
  final ProblemDifficulty difficulty;
  final ProblemCategory category;
  final Map<String, dynamic>? geometryData;
  final String? solution;
  final String? thumbnailId; // Add this

  const UpdateProblem({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    this.geometryData,
    this.solution,
    this.thumbnailId, // Add this
  });

  @override
  List<Object?> get props => [id, title, description, difficulty, category, geometryData, solution, thumbnailId];
}
```

### 5. Update BLoC to Pass Thumbnail

In `problem_bloc.dart`, update the GraphQL mutation calls:

```dart
// In _onCreateProblem
final result = await _client.value.mutate(
  MutationOptions(
    document: gql(ProblemQueries.createProblem),
    variables: {
      'title': event.title,
      'description': event.description,
      'difficulty': event.difficulty.name,
      'category': event.category.name,
      'geometry_data': event.geometryData,
      'solution': event.solution,
      'thumbnail': event.thumbnailId, // Add this
    },
  ),
);

// In _onUpdateProblem
final result = await _client.value.mutate(
  MutationOptions(
    document: gql(ProblemQueries.updateProblem),
    variables: {
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'difficulty': event.difficulty.name,
      'category': event.category.name,
      'geometry_data': event.geometryData,
      'solution': event.solution,
      'thumbnail': event.thumbnailId, // Add this
    },
  ),
);
```

### 6. Display Thumbnails in Problem List

Update `problem_management_screen.dart` to show thumbnails as cards:

```dart
Widget _buildProblemCard(Problem problem) {
  final fileService = DirectusFileService(
    baseUrl: 'http://192.168.1.3:8055',
  );

  return Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail image
        if (problem.thumbnailId != null)
          Image.network(
            fileService.getFileUrl(
              problem.thumbnailId!,
              width: 400,
              height: 300,
              fit: 'cover',
              quality: 80,
            ),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 48),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          )
        else
          Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image, size: 48, color: Colors.grey),
            ),
          ),
        
        // Problem details
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                problem.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                problem.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(problem.difficulty.displayName),
                    backgroundColor: _getDifficultyColor(problem.difficulty),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(problem.category.displayName),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

## Testing

### 1. Test Thumbnail Capture
```dart
// In a test file
test('Canvas capture creates PNG bytes', () async {
  final dagManager = DAGManager();
  // Add some geometry objects...
  
  final imageBytes = await CanvasCapture.captureAsPng(
    dagManager: dagManager,
    width: 800,
    height: 600,
  );
  
  expect(imageBytes, isNotNull);
  expect(imageBytes!.length, greaterThan(0));
  // Verify PNG header
  expect(imageBytes.sublist(0, 8), equals([137, 80, 78, 71, 13, 10, 26, 10]));
});
```

### 2. Test File Upload
```bash
# Manual test - upload image
curl -X POST http://192.168.1.3:8055/files \
  -F "file=@test_thumbnail.png" \
  -F "title=Test Thumbnail"

# Should return: {"data": {"id": "abc123", ...}}
```

### 3. Test Problem Creation with Thumbnail
```bash
# Create problem with thumbnail field
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { create_problems_item(data: { title: \"Test\", description: \"Test\", difficulty: \"beginner\", category: \"geometry\", thumbnail: \"abc123\" }) { id title thumbnail } }"
  }'
```

## Troubleshooting

### Thumbnail Not Captured
- Check that `_geometryData` is not null
- Verify `GeoDrawDecoder` can decode the geometry data
- Check console for error messages from `CanvasCapture`

### Upload Failing
- Verify Directus is accessible at `http://192.168.1.3:8055`
- Check network connectivity
- Verify file size isn't too large (default Directus limit: 100MB)
- Check Directus logs: `docker logs directus`

### Thumbnail Not Displaying
- Check that `thumbnail` field exists in Directus schema
- Verify Public role has read access to `directus_files`
- Check browser console for 404 errors on asset URLs
- Verify file ID is correctly stored in problem record

### Performance Issues
- Reduce thumbnail size (e.g., 400x300 instead of 800x600)
- Compress images with lower quality setting (e.g., quality: 60)
- Use image caching in Flutter (Image.network does this automatically)
- Consider lazy loading for long lists

## Summary

After implementation:
- ✅ Problems have visual thumbnails showing canvas geometry
- ✅ Thumbnails auto-generated when saving problems
- ✅ Cards display thumbnails in problem list
- ✅ Files managed by Directus file system
- ✅ Responsive image loading with error handling
- ✅ Clean separation: capture → upload → store → display

The thumbnail system provides visual previews of geometric constructions, making it easier for users to browse and identify problems at a glance.
