import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for uploading files to Supabase Storage
class SupabaseFileService {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String bucketName;

  SupabaseFileService({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.bucketName = 'problem-images',
  });

  /// Upload a thumbnail to Supabase Storage using optional Supabase authentication
  ///
  /// [bytes] - The image bytes to upload
  /// [problemId] - The problem ID (used in the file path)
  /// [userId] - The Supabase user ID (used in the file path)
  /// [filename] - Optional filename (defaults to problem_id.png)
  ///
  /// Returns the storage key (path) on success, null on failure
  Future<String?> uploadThumbnail({
    required Uint8List bytes,
    required String problemId,
  required String userId,
    String? filename,
  }) async {
    try {
      final actualFilename = filename ?? '$problemId.png';
      final storagePath = '$userId/thumbnails/$actualFilename';

      final url = Uri.parse(
        '$supabaseUrl/storage/v1/object/$bucketName/$storagePath',
      );

      debugPrint('DEBUG: Uploading to Supabase Storage: $storagePath');

      final sessionToken =
          Supabase.instance.client.auth.currentSession?.accessToken;

      // Use anon key for public bucket (RLS bypassed for public buckets)
      final headers = {
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
        'Content-Type': 'image/png',
        'x-upsert': 'true', // Overwrite if exists
        if (sessionToken != null && sessionToken.isNotEmpty)
          'X-Supabase-Access-Token': sessionToken,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Supabase upload successful: $storagePath');
        return storagePath;
      } else {
        debugPrint('ERROR: Supabase upload failed: ${response.statusCode}');
        debugPrint('ERROR: Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ERROR: Supabase upload exception: $e');
      return null;
    }
  }

  /// Get public URL for a stored file
  String getPublicUrl(String storagePath) {
    return '$supabaseUrl/storage/v1/object/public/$bucketName/$storagePath';
  }

  /// Delete a file from storage
  Future<bool> deleteFile(String storagePath) async {
    try {
      final url = Uri.parse(
        '$supabaseUrl/storage/v1/object/$bucketName/$storagePath',
      );

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ERROR: Supabase delete exception: $e');
      return false;
    }
  }
}
