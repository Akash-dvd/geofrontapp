import 'package:geoapp/geoapp.dart';

/// Directus Data Provider for local development
/// Uses Supabase access tokens for authentication or falls back to DIRECTUS_TOKEN
class DirectusDataProvider implements DataProvider {
  final String _baseUrl;
  final String? _staticToken;
  final String _accessToken;

  DirectusDataProvider({
    required String accessToken,
  })  : _accessToken = accessToken,
        _baseUrl = EnvConfig.directusUrl,
        _staticToken = EnvConfig.directusToken;

  // TODO: Add HTTP client initialization
  // import 'package:http/http.dart' as http;

  Map<String, String> get _headers {
  // Prefer Supabase access token, fallback to static token for local dev
  final token = _accessToken.isNotEmpty ? _accessToken : _staticToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<Problem>> fetchProblems({int? limit, int? offset}) async {
    // TODO: Implement Directus REST API call
    // GET /items/problems?limit=$limit&offset=$offset
    // Parse response and return List<Problem>
    throw UnimplementedError('Directus API integration pending');
  }

  @override
  Future<Problem?> fetchProblemById(String id) async {
    // TODO: Implement Directus REST API call
    // GET /items/problems/$id
    throw UnimplementedError('Directus API integration pending');
  }

  @override
  Future<Problem> createProblem(Problem problem) async {
    // TODO: Implement Directus REST API call
    // POST /items/problems with problem data
    throw UnimplementedError('Directus API integration pending');
  }

  @override
  Future<Problem> updateProblem(String id, Problem problem) async {
    // TODO: Implement Directus REST API call
    // PATCH /items/problems/$id with updated data
    throw UnimplementedError('Directus API integration pending');
  }

  @override
  Future<void> deleteProblem(String id) async {
    // TODO: Implement Directus REST API call
    // DELETE /items/problems/$id
    throw UnimplementedError('Directus API integration pending');
  }

  @override
  Future<String> uploadImage(String filePath, String fileName) async {
    // TODO: Implement Directus file upload
    // POST /files with multipart form data
    // Return the file ID from Directus
    throw UnimplementedError('Directus file upload pending');
  }

  @override
  String getImageUrl(String imageReference) {
    // Directus file URLs: {baseUrl}/assets/{fileId}
    if (imageReference.startsWith('http')) {
      return imageReference;
    }
    return '$_baseUrl/assets/$imageReference';
  }
}
