import 'package:geoapp/geoapp.dart';
import '../../config/env_config.dart';
import 'data_provider.dart';

/// Hasura + Supabase Data Provider for cloud/production
/// Uses Firebase ID token for Hasura JWT authentication
/// Uses Supabase for file storage
class HasuraDataProvider implements DataProvider {
  final String _hasuraEndpoint;
  final String _supabaseUrl;
  final String _supabaseAnonKey;
  final String _idToken;

  HasuraDataProvider({
    required String idToken,
  })  : _idToken = idToken,
        _hasuraEndpoint = EnvConfig.hasuraEndpoint,
        _supabaseUrl = EnvConfig.supabaseUrl,
        _supabaseAnonKey = EnvConfig.supabaseAnonKey;

  // TODO: Add GraphQL and HTTP client initialization
  // import 'package:graphql_flutter/graphql_flutter.dart';
  // import 'package:http/http.dart' as http;

  Map<String, String> get _graphqlHeaders {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_idToken', // Firebase ID token for Hasura JWT
    };
  }

  Map<String, String> get _supabaseHeaders {
    return {
      'apikey': _supabaseAnonKey,
      'Authorization': 'Bearer $_idToken', // Firebase token or Supabase token
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
