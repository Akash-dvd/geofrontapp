import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';
import '../models/simple/geo_trans.dart';
import '../models/simple_lists/geo_intersection.dart';
import '../models/complex/geo_shapes.dart';
import '../dag/dag_manager.dart' as dag;

/// Decodes JSON format back to geometry objects and DAG
class GeoDrawDecoder {
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
        final object = _decodeObject(objJson);
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

  /// Decode a single object
  GeometryObject _decodeObject(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as String;
    final label = json['label'] as String;
    final props = json['properties'] as Map<String, dynamic>;
    final deps = (json['dependencies'] as List).cast<String>();

    final color = _decodeColor(props['color'] as String);
    final visible = props['visible'] as bool? ?? true;

    switch (type) {
      case 'GeoPointer':
        return GeoPointer(
          id: id,
          label: label,
          x: (props['x'] as num).toDouble(),
          y: (props['y'] as num).toDouble(),
          size: (props['size'] as num?)?.toDouble() ?? 5.0,
          color: color,
          visible: visible,
        );

      case 'GeoMidpoint':
        return GeoMidpoint(
          id: id,
          label: label,
          dependencies: deps,
          x: (props['x'] as num).toDouble(),
          y: (props['y'] as num).toDouble(),
          size: (props['size'] as num?)?.toDouble() ?? 5.0,
          color: color,
          visible: visible,
        );

      case 'GeoInvPoint':
        return GeoInvPoint(
          id: id,
          label: label,
          dependencies: deps,
          x: (props['x'] as num).toDouble(),
          y: (props['y'] as num).toDouble(),
          size: (props['size'] as num?)?.toDouble() ?? 5.0,
          color: color,
          visible: visible,
        );

      case 'GeoLine2P':
        return GeoLine2P(
          id: id,
          label: label,
          dependencies: deps,
          a: (props['a'] as num).toDouble(),
          b: (props['b'] as num).toDouble(),
          c: (props['c'] as num).toDouble(),
          thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
          style: _decodeLineStyle(props['style'] as String?),
          color: color,
          visible: visible,
        );

      case 'GeoPerpendicularBisector':
        return GeoPerpendicularBisector(
          id: id,
          label: label,
          dependencies: deps,
          a: (props['a'] as num).toDouble(),
          b: (props['b'] as num).toDouble(),
          c: (props['c'] as num).toDouble(),
          thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
          style: _decodeLineStyle(props['style'] as String?),
          color: color,
          visible: visible,
        );

      case 'GeoPerpendicularLine':
        return GeoPerpendicularLine(
          id: id,
          label: label,
          dependencies: deps,
          a: (props['a'] as num).toDouble(),
          b: (props['b'] as num).toDouble(),
          c: (props['c'] as num).toDouble(),
          thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
          style: _decodeLineStyle(props['style'] as String?),
          color: color,
          visible: visible,
        );

      case 'GeoParallelLine':
        return GeoParallelLine(
          id: id,
          label: label,
          dependencies: deps,
          a: (props['a'] as num).toDouble(),
          b: (props['b'] as num).toDouble(),
          c: (props['c'] as num).toDouble(),
          thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
          style: _decodeLineStyle(props['style'] as String?),
          color: color,
          visible: visible,
        );

      case 'GeoCircle2P':
        return GeoCircle2P(
          id: id,
          label: label,
          dependencies: deps,
          centerX: (props['centerX'] as num).toDouble(),
          centerY: (props['centerY'] as num).toDouble(),
          radius: (props['radius'] as num).toDouble(),
          thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
          filled: props['filled'] as bool? ?? false,
          color: color,
          visible: visible,
        );

      case 'GeoCircle3P':
        return GeoCircle3P(
          id: id,
          label: label,
          dependencies: deps,
          centerX: (props['centerX'] as num).toDouble(),
          centerY: (props['centerY'] as num).toDouble(),
          radius: (props['radius'] as num).toDouble(),
          thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
          filled: props['filled'] as bool? ?? false,
          color: color,
          visible: visible,
        );

      case 'GeoInvCircle':
        return GeoInvCircle(
          id: id,
          label: label,
          dependencies: deps,
          centerX: (props['centerX'] as num).toDouble(),
          centerY: (props['centerY'] as num).toDouble(),
          radius: (props['radius'] as num).toDouble(),
          thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
          filled: props['filled'] as bool? ?? false,
          color: color,
          visible: visible,
        );

      case 'GeoInverse':
        return GeoInverse(
          id: id,
          label: label,
          dependencies: deps,
          centerPointId: props['centerPointId'] as String,
          power: (props['power'] as num).toDouble(),
          color: color,
          visible: visible,
        );

      case 'GeoRotate':
        return GeoRotate(
          id: id,
          label: label,
          dependencies: deps,
          centerPointId: props['centerPointId'] as String,
          angle: (props['angle'] as num).toDouble(),
          color: color,
          visible: visible,
        );

      case 'GeoDilate':
        return GeoDilate(
          id: id,
          label: label,
          dependencies: deps,
          centerPointId: props['centerPointId'] as String,
          factor: (props['factor'] as num).toDouble(),
          color: color,
          visible: visible,
        );

      case 'GeoSegment':
        return GeoSegment(
          id: id,
          label: label,
          dependencies: deps,
          startPointId: props['startPointId'] as String,
          endPointId: props['endPointId'] as String,
          underlyingObjectId: props['underlyingObjectId'] as String,
          color: color,
          visible: visible,
        );

      default:
        throw UnsupportedError('Unknown object type: $type');
    }
  }

  /// Decode color from hex string
  Color _decodeColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Decode line style from string
  LineStyle _decodeLineStyle(String? style) {
    switch (style) {
      case 'dashed':
        return LineStyle.dashed;
      case 'dotted':
        return LineStyle.dotted;
      default:
        return LineStyle.solid;
    }
  }

  /// Decode from JSON string
  dag.DAGManager decodeFromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return decode(json);
  }
}
