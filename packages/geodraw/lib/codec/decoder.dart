import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/dag/dag_manager.dart' as dag;
import '../models/canvas_object.dart';
import '../models/simple/geo_circle.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_Inf.dart';
import '../models/simple/geo_flex.dart';
import '../models/geometry_object.dart';
import '../models/transforms/geo_trans.dart';
import '../models/simple/geo_transformed_simple.dart';
import '../models/complex/geo_transformed_complex.dart';
import '../models/simple_lists/geo_intersection.dart';
import '../models/simple_lists/geo_tangent.dart';
import '../models/simple_lists/geo_angle_bisector.dart';
import '../models/complex/geo_shapes.dart';
import '../models/complex/geo_shapes_list.dart';

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
    'GeoOrthocenter': (json, _) => GeoOrthocenter.fromJson(json),
    'GeoConstructedPoint': (json, _) => GeoConstructedPoint.fromJson(json),
    'GeoInvPoint': (json, _) => GeoTransPoint.fromJson(json),
    'GeoInf': (json, _) => GeoInf.fromJson(json),

    // Lines
    'GeoLine2P': (json, _) => GeoLine2P.fromJson(json),
    'GeoLineFlex': (json, _) => GeoLineFlex.fromJson(json),
    'GeoPerpendicularBisector': (json, _) =>
        GeoPerpendicularBisector.fromJson(json),
    'GeoPerpendicularBisectorFlex': (json, _) =>
        GeoPerpendicularBisectorFlex.fromJson(json),
    'GeoPerpendicularLine': (json, _) => GeoPerpendicularLine.fromJson(json),
    'GeoPerpendicularLineFlex': (json, _) =>
        GeoPerpendicularLineFlex.fromJson(json),
    'GeoParallelLine': (json, _) => GeoParallelLine.fromJson(json),
    'GeoParallelLineFlex': (json, _) => GeoParallelLineFlex.fromJson(json),

    // Circles
    'GeoCircle2P': (json, _) => GeoCircle2P.fromJson(json),
    'GeoCircle3P': (json, _) => GeoCircle3P.fromJson(json),
    'GeoCircleFlex': (json, _) => GeoCircleFlex.fromJson(json),
    'Geo3Flex': (json, _) => Geo3Flex.fromJson(json),
    'GeoALCbc': (json, _) => GeoALCbc.fromJson(json),
    // Backward compatibility
    'GeoCircle3Flex': (json, _) => Geo3Flex.fromJson(json),
    'GeoInvCircle': (json, _) => GeoInvCircle.fromJson(json),

    // Transformations
    'GeoLineInverse': (json, _) => GeoLineInverse.fromJson(json),
    'GeoCircleInverse': (json, _) => GeoCircleInverse.fromJson(json),
    'GeoPointInverse': (json, _) => GeoPointInverse.fromJson(json),
    // Backward compatibility: old GeoInverse type
    'GeoInverse': (json, _) {
      final props = json['properties'] as Map<String, dynamic>?;
      final power = (props?['power'] as num?)?.toDouble() ?? 0.0;
      final centerPointId = props?['centerPointId'] as String? ?? '';
      
      // Try to determine type from multivector encoding
      final rawMv = json[SimpleGeometryObject.multivectorKey];
      if (rawMv is List && rawMv.length == 7) {
        // Full operator encoding = point inversion
        return GeoPointInverse.fromJson(json);
      } else if (power > 0 && centerPointId.isNotEmpty) {
        // Has power and center = circle inversion
        return GeoCircleInverse.fromJson(json);
      } else {
        // Default to line inversion
        return GeoLineInverse.fromJson(json);
      }
    },
    'GeoRotate': (json, _) => GeoRotate.fromJson(json),
    'GeoDilate': (json, _) => GeoDilate.fromJson(json),
    'GeoTranslate': (json, _) => GeoTranslate.fromJson(json),

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
    'polyArc': (json, dagManager) => GeoPolyArc.fromJson(
      json,
      (id) => _resolvePoint(dagManager, 'GeoPolyArc', id),
      dagManager,
    ),
    'polyArcGon': (json, dagManager) => GeoPolyArcGon.fromJson(
      json,
      (id) => _resolvePoint(dagManager, 'GeoPolyArcGon', id),
      dagManager,
    ),
    'polyLine': (json, dagManager) => GeoPolyLine.fromJson(
      json,
      (id) => _resolvePoint(dagManager, 'GeoPolyLine', id),
      dagManager,
    ),
    'polygon': (json, dagManager) => GeoPolygon.fromJson(
      json,
      (id) => _resolvePoint(dagManager, 'GeoPolygon', id),
      dagManager,
    ),
    'triangle': (json, dagManager) => GeoTriangle.fromJson(
      json,
      (id) => _resolvePoint(dagManager, 'GeoTriangle', id),
    ),
    'regularPolygonCenter': (json, dagManager) => GeoRegularPolygon2P.fromJson(
      json,
      (id) => _resolvePoint(dagManager, 'GeoRegularPolygon2P', id),
    ),
    'regularPolygonSegment': (json, dagManager) =>
        GeoRegularPolygonSegment.fromJson(
          json,
          (id) => _resolveSegment(dagManager, 'GeoRegularPolygonSegment', id),
        ),

    // Simple geometry lists
    'GeoAngleBisector2L': (json, _) => GeoAngleBisector2L.fromJson(json),
    'GeoIntersection': (json, _) => GeoIntersection.fromJson(json),
    // Backward compatibility: old type string
    'intersection': (json, _) => GeoIntersection.fromJson(json),
    'GeoTangentList': (json, dagManager) {
      final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
      if (deps.length != 2) {
        return GeoTangentList.fromJson(json);
      }

      final first = dagManager.getObject(deps[0]);
      final second = dagManager.getObject(deps[1]);

      if (first is! GeometryObject || second is! GeometryObject) {
        return GeoTangentList.fromJson(json);
      }

      try {
        return GeoTangentList.constructFromObjects(
          id: json['id'] as String,
          label: (json['label'] as String?) ?? '',
          first: first,
          second: second,
          dagManager: dagManager,
          styleOverrides: _extractStyleOverrides(json),
          visible: json['visible'] as bool? ?? true,
        );
      } catch (_) {
        return GeoTangentList.fromJson(json);
      }
    },
    // Backward compatibility: old type strings
    'GeoTangent': (json, dagManager) {
      final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
      if (deps.length != 2) {
        return GeoTangentList.fromJson(json);
      }

      final first = dagManager.getObject(deps[0]);
      final second = dagManager.getObject(deps[1]);

      if (first is! GeometryObject || second is! GeometryObject) {
        return GeoTangentList.fromJson(json);
      }

      try {
        return GeoTangentList.constructFromObjects(
          id: json['id'] as String,
          label: (json['label'] as String?) ?? '',
          first: first,
          second: second,
          dagManager: dagManager,
          styleOverrides: _extractStyleOverrides(json),
          visible: json['visible'] as bool? ?? true,
        );
      } catch (_) {
        return GeoTangentList.fromJson(json);
      }
    },
    'tangent': (json, dagManager) {
      final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
      if (deps.length != 2) {
        return GeoTangentList.fromJson(json);
      }

      final first = dagManager.getObject(deps[0]);
      final second = dagManager.getObject(deps[1]);

      if (first is! GeometryObject || second is! GeometryObject) {
        return GeoTangentList.fromJson(json);
      }

      try {
        return GeoTangentList.constructFromObjects(
          id: json['id'] as String,
          label: (json['label'] as String?) ?? '',
          first: first,
          second: second,
          dagManager: dagManager,
          styleOverrides: _extractStyleOverrides(json),
          visible: json['visible'] as bool? ?? true,
        );
      } catch (_) {
        return GeoTangentList.fromJson(json);
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
        debugPrint('Warning: Failed to decode object ${objJson['id']}: $e');
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

  static GeoSegment2P _resolveSegment(
    dag.DAGManager dagManager,
    String ownerType,
    String dependencyId,
  ) {
    final object = dagManager.getObject(dependencyId);
    if (object is GeoSegment2P) {
      return object;
    }
    throw StateError('$ownerType dependency $dependencyId is not a segment');
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
