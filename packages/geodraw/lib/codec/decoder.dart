import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/dag/dag_manager.dart' as dag;
import '../models/canvas_object.dart';
import '../models/simple/geo_circle.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_point.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_trans.dart';
import '../models/simple/geo_transformed_simple.dart';
import '../models/complex/geo_transformed_complex.dart';
import '../models/simple_lists/geo_intersection.dart';
import '../models/simple_lists/geo_tangent.dart';
import '../models/complex/geo_shapes.dart';

/// Decodes JSON format back to geometry objects and DAG
///
/// Uses type registry pattern where each class has a fromJson factory.
/// This eliminates the need for large switch statements and makes the
/// decoder simple and maintainable.
typedef ObjectFactory =
    CanvasObject Function(Map<String, dynamic> json, dag.DAGManager dagManager);

class GeoDrawDecoder {
  /// Type registry mapping type strings to factory functions
  static final Map<String, ObjectFactory> _typeRegistry = {
    // Points
    'GeoPointer': (json, _) => GeoPointer.fromJson(json),
    'GeoMidpoint': (json, _) => GeoMidpoint.fromJson(json),
    'GeoInvPoint': (json, _) => GeoTransPoint.fromJson(json),

    // Lines
    'GeoLine2P': (json, _) => GeoLine2P.fromJson(json),
    'GeoPerpendicularBisector': (json, _) =>
        GeoPerpendicularBisector.fromJson(json),
    'GeoPerpendicularLine': (json, _) => GeoPerpendicularLine.fromJson(json),
    'GeoParallelLine': (json, _) => GeoParallelLine.fromJson(json),

    // Circles
    'GeoCircle2P': (json, _) => GeoCircle2P.fromJson(json),
    'GeoCircle3P': (json, _) => GeoCircle3P.fromJson(json),
    'GeoInvCircle': (json, _) => GeoInvCircle.fromJson(json),

    // Transformations
    'GeoInverse': (json, _) => GeoInverse.fromJson(json),
    'GeoRotate': (json, _) => GeoRotate.fromJson(json),
    'GeoDilate': (json, _) => GeoDilate.fromJson(json),

    // Transformed simple geometry
    'GeoTransPoint': (json, _) => GeoTransPoint.fromJson(json),
    'GeoTransLine': (json, _) => GeoTransLine.fromJson(json),
    'GeoTransCircle': (json, _) => GeoTransCircle.fromJson(json),
    'GeoTransSegment': (json, _) => GeoTransSegment.fromJson(json),
    'GeoTransArc': (json, _) => GeoTransArc.fromJson(json),
    'GeoTransUnionGeometryObjectList': (json, _) =>
        GeoTransUnionGeometryObjectList.fromJson(json),

    // Complex geometry
    'GeoSegment2P': (json, dagManager) => GeoSegment2P.fromJson(
      json,
      (id) => _resolvePoint(dagManager, 'GeoSegment2P', id),
    ),
    'GeoArc3P': (json, dagManager) => GeoArc3P.fromJson(
      json,
      (id) => _resolvePoint(dagManager, 'GeoArc3P', id),
    ),

    // Simple geometry lists
    'GeoIntersection': (json, _) => GeoIntersection.fromJson(json),
    'GeoTangent': (json, dagManager) {
      final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
      if (deps.length != 2) {
        return GeoTangent.fromJson(json);
      }

      final first = dagManager.getObject(deps[0]);
      final second = dagManager.getObject(deps[1]);

      if (first is! GeometryObject || second is! GeometryObject) {
        return GeoTangent.fromJson(json);
      }

      try {
        return GeoTangent.constructFromObjects(
          id: json['id'] as String,
          label: (json['label'] as String?) ?? '',
          first: first,
          second: second,
          styleOverrides: _extractStyleOverrides(json),
          visible: json['visible'] as bool? ?? true,
        );
      } catch (_) {
        return GeoTangent.fromJson(json);
      }
    },

    // TODO: Add remaining complex objects (polygons, intersections, etc.) as they are implemented
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

        // Call the appropriate factory with DAG context
        final object = factory(objJson, dagManager);
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
    Map<String, dynamic>? resolveMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((key, dynamic v) => MapEntry(key.toString(), v));
      }
      return null;
    }

    final centerJson = resolveMap(json['center']) ?? const {'x': 0, 'y': 0};
    final canvasJson = resolveMap(json['canvasSize']);

    num asNum(dynamic value, [num fallback = 0]) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? fallback;
      return fallback;
    }

    final zoomValue = asNum(json['zoom'], 1.0).toDouble();
    final gridValue = json['gridVisible'];

    return dag.Viewport(
      center: Offset(
        asNum(centerJson['x']).toDouble(),
        asNum(centerJson['y']).toDouble(),
      ),
      zoom: zoomValue,
      gridVisible: gridValue is bool ? gridValue : true,
      canvasSize: Size(
        asNum(canvasJson?['width'], 0).toDouble(),
        asNum(canvasJson?['height'], 0).toDouble(),
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

  /// Decode DAG from stored representation (JSON or base64-encoded JSON).
  dag.DAGManager decodeFromStorage(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return dag.DAGManager();
    }

    String jsonString;
    try {
      final decodedBytes = base64Decode(trimmed);
      jsonString = utf8.decode(decodedBytes);
    } catch (_) {
      jsonString = trimmed;
    }

    return decodeFromJson(jsonString);
  }

  static GeoPoint _resolvePoint(
    dag.DAGManager dagManager,
    String ownerType,
    String dependencyId,
  ) {
    final object = dagManager.getObject(dependencyId);
    if (object is GeoPoint) {
      return object;
    }
    throw StateError('$ownerType dependency $dependencyId is not a point');
  }
}

Map<String, dynamic>? _extractStyleOverrides(Map<String, dynamic> json) {
  final rawStyle = json['style'];
  if (rawStyle is Map<String, dynamic>) {
    return Map<String, dynamic>.unmodifiable(rawStyle);
  }
  if (rawStyle is Map) {
    return Map<String, dynamic>.unmodifiable(
      rawStyle.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
  return null;
}
