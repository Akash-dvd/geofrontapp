import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

/// Service for uploading files to Directus
class DirectusFileService {
  final String baseUrl;
  final String? authToken;

  DirectusFileService({required this.baseUrl, this.authToken});

  /// Upload an image file to Directus and return the file ID
  ///
  /// [imageBytes] - The image data as bytes
  /// [filename] - The name of the file (e.g., "thumbnail.png")
  /// [title] - Optional title for the file in Directus
  ///
  /// Returns the Directus file ID on success, null on failure
  Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String filename,
    String? title,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/files');
      final request = http.MultipartRequest('POST', uri);

      // Add file with proper content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
          contentType: MediaType('image', 'png'),
        ),
      );

      // Add title if provided
      if (title != null) {
        request.fields['title'] = title;
      }

      // Add auth token if available
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      // Send request
      debugPrint('DEBUG: Sending upload request to $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('DEBUG: Upload response status: ${response.statusCode}');
      debugPrint('DEBUG: Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final fileId = jsonResponse['data']['id'] as String;
        debugPrint('DEBUG: File uploaded successfully with ID: $fileId');
        return fileId;
      } else {
        debugPrint(
          'ERROR: Failed to upload image: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: Exception uploading image: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get the full URL for a Directus file by its ID
  ///
  /// [fileId] - The Directus file ID
  /// [width] - Optional width for image transformation
  /// [height] - Optional height for image transformation
  /// [fit] - Optional fit parameter (cover, contain, inside, outside)
  /// [quality] - Optional quality (1-100)
  ///
  /// Returns the full URL to access the file
  String getFileUrl(
    String fileId, {
    int? width,
    int? height,
    String? fit,
    int? quality,
  }) {
    final params = <String>[];

    if (width != null) params.add('width=$width');
    if (height != null) params.add('height=$height');
    if (fit != null) params.add('fit=$fit');
    if (quality != null) params.add('quality=$quality');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';

    return '$baseUrl/assets/$fileId$queryString';
  }

  /// Delete a file from Directus
  ///
  /// [fileId] - The Directus file ID to delete
  ///
  /// Returns true on success, false on failure
  Future<bool> deleteFile(String fileId) async {
    try {
      final uri = Uri.parse('$baseUrl/files/$fileId');
      final headers = <String, String>{};

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint(
          'Failed to delete file: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
}
