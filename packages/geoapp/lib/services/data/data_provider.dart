import 'package:geoapp/geoapp.dart';

/// Abstract data provider interface for backend operations
/// Implementations handle Directus (local) or Hasura+Supabase (cloud)
abstract class DataProvider {
  /// Fetch all problems with optional pagination
  Future<List<Problem>> fetchProblems({int? limit, int? offset});

  /// Fetch a single problem by ID
  Future<Problem?> fetchProblemById(String id);

  /// Create a new problem
  Future<Problem> createProblem(Problem problem);

  /// Update an existing problem
  Future<Problem> updateProblem(String id, Problem problem);

  /// Delete a problem
  Future<void> deleteProblem(String id);

  /// Upload an image and return the URL
  /// Returns the public URL or file ID that can be used to reference the image
  Future<String> uploadImage(String filePath, String fileName);

  /// Get the full URL for an image reference
  /// Converts file IDs or relative paths to absolute URLs
  String getImageUrl(String imageReference);
}
