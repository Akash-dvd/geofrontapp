/// AI-powered natural language to geometry command conversion service.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/geometry_object.dart';
import '../core/dag/dag_manager.dart';

/// Response from the AI service
class AIResponse {
  final bool isSuccess;
  final List<String>? commands;
  final String? error;

  AIResponse._({required this.isSuccess, this.commands, this.error});

  factory AIResponse.success(List<String> commands) {
    return AIResponse._(isSuccess: true, commands: commands);
  }

  factory AIResponse.error(String error) {
    return AIResponse._(isSuccess: false, error: error);
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
  factory AIServiceConfig.network({
    String host = '192.168.1.3',
    int port = 5000,
  }) {
    return AIServiceConfig(apiEndpoint: 'http://$host:$port/graphql');
  }
}

/// Service for converting natural language descriptions into geometry commands
class AIService {
  final AIServiceConfig config;
  final http.Client _client;

  AIService({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  /// Generate geometry commands from natural language description
  /// [existingObjects] - Optional map of existing object labels to their types for incremental construction
  /// [usedLabels] - Optional set of labels already in use (to avoid conflicts)
  /// [canvasSize] - Optional canvas size to help AI spread points across the canvas
  /// [viewportCenter] - Optional viewport center to calculate world coordinate bounds
  /// [viewportZoom] - Optional viewport zoom to calculate world coordinate bounds
  Future<AIResponse> generateCommands(
    String description, {
    Map<String, String>? existingObjects,
    Set<String>? usedLabels,
    Size? canvasSize,
    Offset? viewportCenter,
    double? viewportZoom,
  }) async {
    if (description.trim().isEmpty) {
      return AIResponse.error('Description cannot be empty');
    }

    int attempts = 0;
    Exception? lastException;

    while (attempts < config.maxRetries) {
      attempts++;

      try {
        final response = await _makeRequest(
          description,
          existingObjects: existingObjects,
          usedLabels: usedLabels,
          canvasSize: canvasSize,
          viewportCenter: viewportCenter,
          viewportZoom: viewportZoom,
        );
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

  /// Generate commands with context from DAGManager (for incremental construction)
  Future<AIResponse> generateCommandsWithContext(
    String description,
    DAGManager dagManager,
  ) async {
    // Extract existing objects and their labels
    final existingObjects = <String, String>{};
    final usedLabels = <String>{};
    
    for (final node in dagManager.nodes.values) {
      final obj = node.object;
      if (obj is GeometryObject && obj.label.isNotEmpty) {
        final type = _getObjectTypeName(obj);
        existingObjects[obj.label] = type;
        usedLabels.add(obj.label);
        usedLabels.add(obj.id);
      }
    }

    // Extract canvas/viewport information
    final viewport = dagManager.viewport;
    final canvasSize = viewport?.canvasSize;
    final viewportCenter = viewport?.center;
    final viewportZoom = viewport?.zoom;

    return generateCommands(
      description,
      existingObjects: existingObjects,
      usedLabels: usedLabels,
      canvasSize: canvasSize,
      viewportCenter: viewportCenter,
      viewportZoom: viewportZoom,
    );
  }

  String _getObjectTypeName(GeometryObject obj) {
    final className = obj.runtimeType.toString();
    // Convert class name to readable type
    if (className.contains('Point')) return 'point';
    if (className.contains('Line')) return 'line';
    if (className.contains('Segment')) return 'segment';
    if (className.contains('Circle')) return 'circle';
    if (className.contains('Arc')) return 'arc';
    if (className.contains('Polygon')) return 'polygon';
    if (className.contains('PolyLine')) return 'polyline';
    if (className.contains('PolyArc')) return 'polyarc';
    if (className.contains('Triangle')) return 'triangle';
    if (className.contains('Union')) return 'union';
    return 'object';
  }

  Future<Map<String, dynamic>> _makeRequest(
    String description, {
    Map<String, String>? existingObjects,
    Set<String>? usedLabels,
    Size? canvasSize,
    Offset? viewportCenter,
    double? viewportZoom,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (config.apiKey != null) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    final body = jsonEncode({
      'description': description,
      'prompt': _buildPrompt(
        description,
        existingObjects: existingObjects,
        usedLabels: usedLabels,
        canvasSize: canvasSize,
        viewportCenter: viewportCenter,
        viewportZoom: viewportZoom,
      ),
    });

    debugPrint(
      'AIService: POST ${config.apiEndpoint} (desc length=${description.length})',
    );

    final response = await _client
        .post(Uri.parse(config.apiEndpoint), headers: headers, body: body)
        .timeout(config.timeout);

    debugPrint(
      'AIService: Response ${response.statusCode} (${response.body.length} bytes)',
    );

    if (response.statusCode != 200) {
      debugPrint('AIService: Non-200 response body => ${response.body}');
      throw http.ClientException(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _buildPrompt(
    String description, {
    Map<String, String>? existingObjects,
    Set<String>? usedLabels,
    Size? canvasSize,
    Offset? viewportCenter,
    double? viewportZoom,
  }) {
    final existingContext = existingObjects != null && existingObjects.isNotEmpty
        ? _buildExistingObjectsContext(existingObjects)
        : '';
    
    final labelPolicy = _buildLabelPolicy(usedLabels);
    
    final allCommands = _buildAllCommandsList();
    
    final canvasContext = _buildCanvasContext(
      canvasSize: canvasSize,
      viewportCenter: viewportCenter,
      viewportZoom: viewportZoom,
    );

    return '''
You are a geometry construction assistant. Convert the following natural language description into a sequence of geometry commands.

$allCommands

Label Policy:
$labelPolicy

$canvasContext

${existingContext.isNotEmpty ? 'Existing Construction:\n$existingContext\n' : ''}
Rules:
1. Generate valid command syntax following the format above
2. Follow the label policy strictly:
   - Points: Use UPPERCASE letters (A, B, C, ..., Z, then AA, AB, ..., ZZ, etc.)
   - Lines, Segments, Circles, Arcs: Use lowercase letters (a, b, c, ..., z, then aa, ab, ..., zz, etc.)
   - Polygons, Polylines, Polyarcs: Use UN1, UN2, UN3, ... format
   - Simple lists: Use SL1, SL2, SL3, ... format
3. ${existingContext.isNotEmpty ? 'You can reference existing objects by their labels. ' : ''}${usedLabels != null && usedLabels.isNotEmpty ? 'DO NOT use these labels (already taken): ${usedLabels.join(', ')}. ' : ''}Choose the next available label following the policy.
4. ${canvasContext.isNotEmpty ? 'When creating points, spread them across the available coordinate range. ' : ''}Include all intermediate construction steps
5. Order commands by dependencies (use objects only after they're created)
6. Return ONLY a JSON array of command strings, no explanation
7. Each command must be a valid string that can be parsed. Prefer direct labels over nested expressions (e.g., supply `circle3(A, B, C, circumcircle)` instead of using midpoint expressions).

User description: $description

Return format example: ["point(0, 0, A)", "point(5, 0, B)", "line(A, B, ab)"]

Return only the JSON array:
''';
  }

  String _buildAllCommandsList() {
    return '''Available commands:
- point(x, y, label): Create a free point at coordinates, or point(object, label) for glider point on object
- line(p1, p2, label): Create a line through two points
- segment(p1, p2, label): Create a segment between two points
- circle(center, point, label): Create a circle with center through point
- circle(center, radius, label): Create a circle with center and radius
- circle3(p1, p2, p3, label): Create circumcircle through three points
- arc3(p1, through, p3, label): Create a circular arc passing through three points
- polyarc(p1, p2, ..., pN, label): Create a chain of arcs through sequential points
- extendpolyarc(polyarc, p1, p2, label): Extend an existing poly-arc with another arc
- polygon(p1, p2, ..., pN, label): Create polygon from sequential vertices
- extendpolygon(polygon, p, label): Extend an existing polygon with another vertex
- polyline(p1, p2, ..., pN, label): Create polyline from sequential points
- extendpolyline(polyline, p, label): Extend an existing polyline with another point
- polyarcgon(p1, p2, ..., pN, label): Create closed poly-arc from sequential points
- extendpolyarcgon(polyarcgon, p1, p2, label): Extend an existing poly-arc-gon with another arc
- midpoint(p1, p2, label): Create midpoint between two points or from a segment
- center(circle, label): Find and draw the center of a circle
- perpendicular(line, point, label): Create perpendicular line through point
- parallel(line, point, label): Create parallel line through point
- perpbisector(p1, p2, label): Perpendicular bisector of segment
- anglebisector(p1, vertex, p2, label): Angle bisector from three points (vertex at middle) or two lines
- tangent(obj1, obj2, label): Construct tangent lines between a point and a circle or between two circles
- tangents(obj1, obj2, label): Construct tangents between two objects (point-point, point-circle, or circle-circle)
- intersection(obj1, obj2, label): Find intersection points of geometry objects
- reflect(object, line, label): Reflect object about line, circle, or point
- rotate(object, center, angle, label): Rotate object around center by angle (degrees)
- dilate(object, center, factor, label): Scale object from center by factor
- translate(object, segment, label): Translate object by vector defined by segment
- incircle(p1, p2, p3, label): Construct the incircle of a triangle from three vertices
- excircle(p1, p2, p3, side, label): Construct an excircle of a triangle from three vertices and a side
- orthocenter(p1, p2, p3, label): Construct the orthocenter of a triangle from three vertices
- polar(point, circle, label): Construct the polar line of a point with respect to a circle
- circleFlex(center, point, label): Create circle with flexible center and point (center: point/circle, point: point/circle)
- geo3Flex(obj1, obj2, obj3, label): Create geometry through three flexible objects (returns point, line, or circle)
- lineFlex(obj1, obj2, label): Create line through two flexible objects (any SimpleGeometryObject)
- perpbisectorFlex(obj1, obj2, label): Perpendicular bisector with flexible arguments (circle or point, not line)
- perpendicularFlex(line, point, label): Perpendicular line with flexible point (point or circle)
- parallelFlex(line, point, label): Parallel line with flexible point (point or circle)
- icircle(p1, p2, label): Construct an imaginary circle from two points
- alcbc(mv1, mv2, mv3, label): Apply aLCbc operation on three multivectors
- union(obj1, obj2, ..., label): Create a union of simple or complex geometry objects
- text(x, y, content, label): Place a text annotation on the canvas
- triangle(p1, p2, p3, label): Create triangle (alias for polygon with 3 points)''';
  }

  String _buildLabelPolicy(Set<String>? usedLabels) {
    return '''Label Naming Conventions (frugal naming - reuse deleted labels first):
- Points and Intersection Points: UPPERCASE letters (A-Z, then AA-ZZ, then AAA-ZZZ, ...)
- Lines, Segments, Circles, Arcs: lowercase letters (a-z, then aa-zz, then aaa-zzz, ...)
- Simple List containers: SL1, SL2, SL3, ... (find first available)
- Union/Polygon/Polyline/Polyarc containers: UN1, UN2, UN3, ... (find first available)
- Transform objects: Use base label with apostrophe (A → A', a → a', etc.)
- When choosing labels, always start from the beginning and find the first available label
- Example: If A, B, C exist and A is deleted, next point gets A (not D)
- Example: If A-Z all exist and A is deleted, next point gets A (not AA)''';
  }

  String _buildCanvasContext({
    Size? canvasSize,
    Offset? viewportCenter,
    double? viewportZoom,
  }) {
    if (canvasSize == null) {
      return '';
    }

    final center = viewportCenter ?? Offset.zero;
    final zoom = viewportZoom ?? 1.0;
    
    // Calculate world coordinate bounds
    // World coordinates visible on screen
    final worldLeft = center.dx - canvasSize.width / (2 * zoom);
    final worldRight = center.dx + canvasSize.width / (2 * zoom);
    final worldTop = center.dy - canvasSize.height / (2 * zoom);
    final worldBottom = center.dy + canvasSize.height / (2 * zoom);
    
    final worldWidth = worldRight - worldLeft;
    final worldHeight = worldBottom - worldTop;

    return '''Canvas Information:
- Canvas size: ${canvasSize.width.toInt()} x ${canvasSize.height.toInt()} pixels
- Viewport center: (${center.dx.toStringAsFixed(1)}, ${center.dy.toStringAsFixed(1)})
- Zoom level: ${zoom.toStringAsFixed(2)}x
- Visible world coordinate range:
  * X-axis: approximately ${worldLeft.toStringAsFixed(1)} to ${worldRight.toStringAsFixed(1)} (range: ${worldWidth.toStringAsFixed(1)})
  * Y-axis: approximately ${worldTop.toStringAsFixed(1)} to ${worldBottom.toStringAsFixed(1)} (range: ${worldHeight.toStringAsFixed(1)})
- When creating points, spread them across this coordinate range. For example, if creating 3 points, place them at different corners/areas of the visible canvas rather than clustering them together.
- When user asks for "random points" or doesn't specify coordinates, distribute points across the full visible range to make the construction visible and well-spaced.''';
  }

  String _buildExistingObjectsContext(Map<String, String> existingObjects) {
    if (existingObjects.isEmpty) return '';
    
    final buffer = StringBuffer('The following objects already exist in the construction:\n');
    existingObjects.forEach((label, type) {
      buffer.writeln('- $label: $type');
    });
    buffer.writeln('\nYou can reference these objects by their labels in your commands.');
    buffer.writeln('Only generate commands for NEW objects that need to be created.');
    
    return buffer.toString();
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
          throw FormatException(
            'Unexpected result type: ${result.runtimeType}',
          );
        }
      } else {
        throw FormatException(
          'Response missing commands field: ${response.keys}',
        );
      }

      if (commands.isEmpty) {
        debugPrint('AIService: Parsed empty command list');
        return AIResponse.error('No commands generated');
      }

      debugPrint('AIService: Parsed ${commands.length} commands successfully');

      return AIResponse.success(commands);
    } catch (e) {
      debugPrint('AIService: Failed to parse response => $e');
      return AIResponse.error('Failed to parse response: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
