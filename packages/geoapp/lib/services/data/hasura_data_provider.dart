import 'package:geoapp/geoapp.dart';

/// Edge gateway + Supabase Data Provider for cloud/production
/// Uses Supabase access tokens for authentication against the Worker gateway
/// and Supabase Storage for media uploads.
class HasuraDataProvider implements DataProvider {
  // ignore: unused_field
  final String _graphqlEndpoint;
  final String _supabaseUrl;
  final String _supabaseAnonKey;
  final String _accessToken;

  HasuraDataProvider({
    required String accessToken,
  })  : _accessToken = accessToken,
        _graphqlEndpoint = EnvConfig.edgeGraphqlEndpoint,
        _supabaseUrl = EnvConfig.supabaseUrl,
        _supabaseAnonKey = EnvConfig.supabaseAnonKey;

  // TODO: Add GraphQL and HTTP client initialization
  // import 'package:graphql_flutter/graphql_flutter.dart';
  // import 'package:http/http.dart' as http;

  // ignore: unused_element
  Map<String, String> get _graphqlHeaders {
    return {
      'Content-Type': 'application/json',
      if (_accessToken.isNotEmpty) 'Authorization': 'Bearer $_accessToken',
    };
  }

  // ignore: unused_element
  Map<String, String> get _supabaseHeaders {
    return {
      'apikey': _supabaseAnonKey,
      if (_accessToken.isNotEmpty) 'Authorization': 'Bearer $_accessToken',
    };
  }

  @override
  Future<List<Problem>> fetchProblems({int? limit, int? offset}) async {
    // TODO: Implement Hasura GraphQL query
    // query GetProblems($limit: Int, $offset: Int) {
    //   problems(limit: $limit, offset: $offset, order_by: {created_at: desc}) {
    //     id, title, description, difficulty, category, ...
    //   }
    // }
    throw UnimplementedError('Hasura GraphQL integration pending');
  }

  @override
  Future<Problem?> fetchProblemById(String id) async {
    // TODO: Implement Hasura GraphQL query
    // query GetProblem($id: uuid!) {
    //   problems_by_pk(id: $id) { ... }
    // }
    throw UnimplementedError('Hasura GraphQL integration pending');
  }

  @override
  Future<Problem> createProblem(Problem problem) async {
    // TODO: Implement Hasura GraphQL mutation
    // mutation CreateProblem($object: problems_insert_input!) {
    //   insert_problems_one(object: $object) { ... }
    // }
    throw UnimplementedError('Hasura GraphQL integration pending');
  }

  @override
  Future<Problem> updateProblem(String id, Problem problem) async {
    // TODO: Implement Hasura GraphQL mutation
    // mutation UpdateProblem($id: uuid!, $changes: problems_set_input!) {
    //   update_problems_by_pk(pk_columns: {id: $id}, _set: $changes) { ... }
    // }
    throw UnimplementedError('Hasura GraphQL integration pending');
  }

  @override
  Future<void> deleteProblem(String id) async {
    // TODO: Implement Hasura GraphQL mutation
    // mutation DeleteProblem($id: uuid!) {
    //   delete_problems_by_pk(id: $id) { id }
    // }
    throw UnimplementedError('Hasura GraphQL integration pending');
  }

  @override
  Future<String> uploadImage(String filePath, String fileName) async {
    // TODO: Implement Supabase Storage upload
    // 1. Get signed upload URL from Supabase
    // 2. Upload file to Supabase storage bucket
    // 3. Return public URL or file path
    // POST {supabaseUrl}/storage/v1/object/{bucket}/{path}
    throw UnimplementedError('Supabase storage upload pending');
  }

  @override
  String getImageUrl(String imageReference) {
    // Supabase public URLs: {supabaseUrl}/storage/v1/object/public/{bucket}/{path}
    if (imageReference.startsWith('http')) {
      return imageReference;
    }
    return '$_supabaseUrl/storage/v1/object/public/problem-images/$imageReference';
  }
}
