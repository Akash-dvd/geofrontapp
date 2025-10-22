/// AI-powered natural language to geometry command conversion service.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Response from the AI service
class AIResponse {
  final bool isSuccess;
  final List<String>? commands;
  final String? error;

  AIResponse._({
    required this.isSuccess,
    this.commands,
    this.error,
  });

  factory AIResponse.success(List<String> commands) {
    return AIResponse._(
      isSuccess: true,
      commands: commands,
    );
  }

  factory AIResponse.error(String error) {
    return AIResponse._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Configuration for the AI service
class AIServiceConfig {
  final String apiEndpoint;
  final String? apiKey;
  final Duration timeout;
  final int maxRetries;

  const AIServiceConfig({
    required this.apiEndpoint,
    this.apiKey,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  /// Default configuration for local development
  /// Points to Python solver server running on network
  factory AIServiceConfig.development() {
    return const AIServiceConfig(
      apiEndpoint: 'http://192.168.1.3:5000/graphql',
    );
  }

  /// Production configuration
  factory AIServiceConfig.production(
    String apiEndpoint, {
    String? apiKey,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) {
    return AIServiceConfig(
      apiEndpoint: apiEndpoint,
      apiKey: apiKey,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }
  
  /// Network configuration (for cross-device access)
  factory AIServiceConfig.network({String host = '192.168.1.3', int port = 5000}) {
    return AIServiceConfig(
      apiEndpoint: 'http://$host:$port/graphql',
    );
  }
}

/// Service for converting natural language descriptions into geometry commands
class AIService {
  final AIServiceConfig config;
  final http.Client _client;

  AIService({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Generate geometry commands from natural language description
  Future<AIResponse> generateCommands(String description) async {
    if (description.trim().isEmpty) {
      return AIResponse.error('Description cannot be empty');
    }

    int attempts = 0;
    Exception? lastException;

    while (attempts < config.maxRetries) {
      attempts++;

      try {
        final response = await _makeRequest(description);
        return _parseResponse(response);
      } on http.ClientException catch (e) {
        lastException = e;
        if (attempts < config.maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        }
      } on FormatException catch (e) {
        return AIResponse.error('Invalid response format: ${e.message}');
      } catch (e) {
        return AIResponse.error('Unexpected error: $e');
      }
    }

    return AIResponse.error(
      'Failed after ${config.maxRetries} attempts: ${lastException?.toString() ?? "Unknown error"}',
    );
  }

  Future<Map<String, dynamic>> _makeRequest(String description) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (config.apiKey != null) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    final body = jsonEncode({
      'description': description,
      'prompt': _buildPrompt(description),
    });

    final response = await _client
        .post(
          Uri.parse(config.apiEndpoint),
          headers: headers,
          body: body,
        )
        .timeout(config.timeout);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _buildPrompt(String description) {
    return '''
You are a geometry construction assistant. Convert the following natural language description into a sequence of geometry commands.

Available commands:
- point(x, y, label): Create a free point at coordinates with label
- line(p1, p2, label): Create a line through two points
- segment(p1, p2, label): Create a segment between two points
- circle(center, point, label): Create a circle with center through point
- circle(center, radius, label): Create a circle with center and radius
- perpendicular(line, point, label): Create perpendicular line through point
- parallel(line, point, label): Create parallel line through point
- midpoint(p1, p2, label): Create midpoint between two points
- intersection(obj1, obj2, label): Find intersection points
- triangle(p1, p2, p3, label): Create triangle
- polygon(p1, p2, ..., pN, label): Create polygon
- regular(n, center, vertex, label): Create regular n-gon
- perpbisector(p1, p2, label): Perpendicular bisector of segment
- bisector(p1, vertex, p2, label): Angle bisector
- tangent(circle, point, label): Tangent from point to circle
- reflect(object, line, label): Reflect object about line
- rotate(object, center, angle, label): Rotate object about center
- dilate(object, center, factor, label): Scale object from center

Rules:
1. Generate valid command syntax following the format above
2. Use descriptive uppercase labels (A, B, C, etc. for points)
3. Include all intermediate construction steps
4. Order commands by dependencies (use objects only after they're created)
5. Return ONLY a JSON array of command strings, no explanation
6. Each command must be a valid string that can be parsed

User description: $description

Return format example: ["point(0, 0, A)", "point(5, 0, B)", "line(A, B, AB)"]

Return only the JSON array:
''';
  }

  AIResponse _parseResponse(Map<String, dynamic> response) {
    try {
      // Try different response formats
      List<String> commands;

      if (response.containsKey('commands')) {
        commands = (response['commands'] as List<dynamic>).cast<String>();
      } else if (response.containsKey('data') && response['data'] is List) {
        commands = (response['data'] as List<dynamic>).cast<String>();
      } else if (response.containsKey('result')) {
        final result = response['result'];
        if (result is List) {
          commands = (result).cast<String>();
        } else if (result is String) {
          // Try to parse as JSON array
          commands = (jsonDecode(result) as List<dynamic>).cast<String>();
        } else {
          throw FormatException('Unexpected result type: ${result.runtimeType}');
        }
      } else {
        throw FormatException('Response missing commands field: ${response.keys}');
      }

      if (commands.isEmpty) {
        return AIResponse.error('No commands generated');
      }

      return AIResponse.success(commands);
    } catch (e) {
      return AIResponse.error('Failed to parse response: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
