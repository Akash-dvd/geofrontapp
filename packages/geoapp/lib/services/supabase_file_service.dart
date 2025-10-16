import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Upload a thumbnail to Supabase Storage using Firebase authentication
  ///
  /// [bytes] - The image bytes to upload
  /// [problemId] - The problem ID (used in the file path)
  /// [firebaseUid] - The Firebase user ID (used in the file path)
  /// [filename] - Optional filename (defaults to problem_id.png)
  ///
  /// Returns the storage key (path) on success, null on failure
  Future<String?> uploadThumbnail({
    required Uint8List bytes,
    required String problemId,
    required String firebaseUid,
    String? filename,
  }) async {
    try {
      // Get Firebase ID token for authentication
      final firebaseToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (firebaseToken == null) {
        print('ERROR: No Firebase token available for Supabase upload');
        return null;
      }

      final actualFilename = filename ?? '$problemId.png';
      final storagePath = '$firebaseUid/thumbnails/$actualFilename';

      final url = Uri.parse(
        '$supabaseUrl/storage/v1/object/$bucketName/$storagePath',
      );

      print('DEBUG: Uploading to Supabase Storage: $storagePath');

      // Use anon key for public bucket (RLS bypassed for public buckets)
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $supabaseAnonKey',
          'apikey': supabaseAnonKey,
          'Content-Type': 'image/png',
          'x-upsert': 'true', // Overwrite if exists
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Supabase upload successful: $storagePath');
        return storagePath;
      } else {
        print('ERROR: Supabase upload failed: ${response.statusCode}');
        print('ERROR: Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ERROR: Supabase upload exception: $e');
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
      print('ERROR: Supabase delete exception: $e');
      return false;
    }
  }
}
