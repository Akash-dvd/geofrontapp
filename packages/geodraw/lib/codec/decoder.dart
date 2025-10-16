import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';
import '../models/simple/geo_trans.dart';
import '../core/dag/dag_manager.dart' as dag;

/// Decodes JSON format back to geometry objects and DAG
///
/// Uses type registry pattern where each class has a fromJson factory.
/// This eliminates the need for large switch statements and makes the
/// decoder simple and maintainable.
class GeoDrawDecoder {
  /// Type registry mapping type strings to fromJson factory functions
  static final Map<String, Function> _typeRegistry = {
    // Points
    'GeoPointer': GeoPointer.fromJson,
    'GeoMidpoint': GeoMidpoint.fromJson,
    'GeoInvPoint': GeoInvPoint.fromJson,

    // Lines
    'GeoLine2P': GeoLine2P.fromJson,
    'GeoPerpendicularBisector': GeoPerpendicularBisector.fromJson,
    'GeoPerpendicularLine': GeoPerpendicularLine.fromJson,
    'GeoParallelLine': GeoParallelLine.fromJson,

    // Circles
    'GeoCircle2P': GeoCircle2P.fromJson,
    'GeoCircle3P': GeoCircle3P.fromJson,
    'GeoInvCircle': GeoInvCircle.fromJson,

    // Transformations
    'GeoInverse': GeoInverse.fromJson,
    'GeoRotate': GeoRotate.fromJson,
    'GeoDilate': GeoDilate.fromJson,

    // TODO: Add complex objects as they are implemented
    // 'GeoSegment': GeoSegment.fromJson,
    // 'GeoTriangle': GeoTriangle.fromJson,
    // 'GeoPolygon': GeoPolygon.fromJson,
    // 'GeoIntersection': GeoIntersection.fromJson,
    // 'GeoTangent': GeoTangent.fromJson,
  };

  /// Decode JSON to DAG manager
  dag.DAGManager decode(Map<String, dynamic> json) {
    final dagManager = dag.DAGManager();

    // Decode viewport if present
    if (json['viewport'] != null) {
      dagManager.viewport = _decodeViewport(json['viewport']);
    }

    // Decode metadata
    if (json['metadata'] != null) {
      dagManager.metadata = Map<String, dynamic>.from(json['metadata']);
    }

    // Decode objects in dependency order (sorted by depth)
    final objectsJson = (json['objects'] as List).cast<Map<String, dynamic>>();
    final sorted = _sortByDepth(objectsJson);

    for (final objJson in sorted) {
      try {
        final type = objJson['type'] as String;
        final factory = _typeRegistry[type];

        if (factory == null) {
          throw UnsupportedError('Unknown type: $type');
        }

        // Call the appropriate fromJson factory
        final object = factory(objJson) as GeometryObject;
        final dependencies = (objJson['dependencies'] as List).cast<String>();
        dagManager.addObject(object, dependencies);
      } catch (e) {
        print('Warning: Failed to decode object ${objJson['id']}: $e');
      }
    }

    dagManager.propagateUpdates();
    return dagManager;
  }

  /// Decode viewport settings
  dag.Viewport? _decodeViewport(Map<String, dynamic> json) {
    return dag.Viewport(
      center: Offset(
        (json['center']['x'] as num).toDouble(),
        (json['center']['y'] as num).toDouble(),
      ),
      zoom: (json['zoom'] as num).toDouble(),
      gridVisible: json['gridVisible'] as bool,
      canvasSize: Size(
        (json['canvasSize']['width'] as num).toDouble(),
        (json['canvasSize']['height'] as num).toDouble(),
      ),
    );
  }

  /// Sort objects by depth for correct reconstruction
  List<Map<String, dynamic>> _sortByDepth(List<Map<String, dynamic>> objects) {
    final sorted = List<Map<String, dynamic>>.from(objects);
    sorted.sort((a, b) {
      final depthA = (a['depth'] as num?)?.toInt() ?? 0;
      final depthB = (b['depth'] as num?)?.toInt() ?? 0;
      return depthA.compareTo(depthB);
    });
    return sorted;
  }

  /// Decode from JSON string
  dag.DAGManager decodeFromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return decode(json);
  }
}
