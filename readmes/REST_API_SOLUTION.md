# Solution: Use REST API for Problem Mutations

## Problem
- ✅ REST API: Accepts thumbnail as plain UUID string - **WORKS!**
- ❌ GraphQL: Requires complex `create_directus_files_input` object - **FAILS!**

## Root Cause
Directus GraphQL schema defines thumbnail field type as `create_directus_files_input` (for creating new files), but we want to link EXISTING files by ID. The REST API handles this correctly, but GraphQL doesn't.

## Solution
Use **REST API for mutations** (create/update/delete) and keep **GraphQL for queries** (list/read).

## Implementation

### Update `lib/bloc/problem_bloc.dart`:

Replace GraphQL mutations with HTTP REST API calls:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// In _onCreateProblem:
Future<void> _onCreateProblem(CreateProblem event, Emitter<ProblemState> emit) async {
  try {
    emit(ProblemOperationInProgress(...));
    
    // Use REST API instead of GraphQL
    final response = await http.post(
      Uri.parse('http://192.168.1.3:8055/items/problems'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'title': event.title,
        'description': event.description,
        'difficulty': event.difficulty.name,
        'category': event.category.name,
        'geometry_data': event.geometryData,
        'solution': event.solution,
        'thumbnail': event.thumbnailId,  // Plain string UUID!
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      final newProblem = Problem.fromJson(responseData['data']);
      // ... rest of success handling
    } else {
      emit(ProblemError(message: 'Failed to create problem: ${response.body}'));
    }
  } catch (e) {
    emit(ProblemError(message: e.toString()));
  }
}
```

### Benefits:
- ✅ Works with existing thumbnail UUID
- ✅ Simpler code
- ✅ No GraphQL type mismatches
- ✅ Consistent with REST API behavior

### Keep GraphQL for:
- ✅ `getAllProblems` - Works fine
- ✅ `getProblemById` - Works fine  
- ✅ Queries are fine, only mutations have the issue

---

**Would you like me to implement this REST API approach?** It's the cleanest solution given the GraphQL schema limitation.
