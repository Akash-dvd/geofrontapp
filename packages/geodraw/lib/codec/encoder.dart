import 'dart:convert';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';
import '../models/simple/geo_trans.dart';
import '../models/simple_lists/geo_intersection.dart';
import '../models/complex/geo_shapes.dart';
import '../dag/dag_manager.dart';

/// Encodes geometry objects and DAG to JSON format
class GeoDrawEncoder {
  /// Encode a DAG manager to JSON
  Map<String, dynamic> encode(DAGManager dag) {
    return {
      'type': 'construction',
      'version': '1.0',
      'viewport': _encodeViewport(dag.viewport),
      'objects': dag.nodes.values.map((node) => _encodeNode(node)).toList(),
      'metadata': dag.metadata,
    };
  }

  /// Encode viewport settings
  Map<String, dynamic>? _encodeViewport(Viewport? viewport) {
    if (viewport == null) return null;
    
    return {
      'center': {
        'x': viewport.center.dx,
        'y': viewport.center.dy,
      },
      'zoom': viewport.zoom,
      'gridVisible': viewport.gridVisible,
      'canvasSize': {
        'width': viewport.canvasSize.width,
        'height': viewport.canvasSize.height,
      },
    };
  }

  /// Encode a DAG node
  Map<String, dynamic> _encodeNode(dynamic node) {
    final obj = node.object as GeometryObject;
    
    return {
      'id': node.id,
      'type': _getObjectType(obj),
      'label': obj.label,
      'properties': _encodeProperties(obj),
      'dependencies': node.parentIds,
      'depth': node.depth,
    };
  }

  /// Get the type string for an object
  String _getObjectType(GeometryObject obj) {
    if (obj is GeoPointer) return 'GeoPointer';
    if (obj is GeoMidpoint) return 'GeoMidpoint';
    if (obj is GeoInvPoint) return 'GeoInvPoint';
    if (obj is GeoLine2P) return 'GeoLine2P';
    if (obj is GeoPerpendicularBisector) return 'GeoPerpendicularBisector';
    if (obj is GeoPerpendicularLine) return 'GeoPerpendicularLine';
    if (obj is GeoParallelLine) return 'GeoParallelLine';
    if (obj is GeoCircle2P) return 'GeoCircle2P';
    if (obj is GeoCircle3P) return 'GeoCircle3P';
    if (obj is GeoInvCircle) return 'GeoInvCircle';
    if (obj is GeoInverse) return 'GeoInverse';
    if (obj is GeoRotate) return 'GeoRotate';
    if (obj is GeoDilate) return 'GeoDilate';
    if (obj is GeoIntersection) return 'GeoIntersection';
    if (obj is GeoTangent) return 'GeoTangent';
    if (obj is GeoSegment) return 'GeoSegment';
    if (obj is GeoTriangle) return 'GeoTriangle';
    if (obj is GeoPolygon) return 'GeoPolygon';
    
    return 'Unknown';
  }

  /// Encode object-specific properties
  Map<String, dynamic> _encodeProperties(GeometryObject obj) {
    final props = {
      'color': '#${obj.color.value.toRadixString(16).padLeft(8, '0')}',
      'visible': obj.visible,
    };

    if (obj is GeoPoint) {
      props.addAll({
        'x': obj.x,
        'y': obj.y,
        'size': obj.size,
      });
    } else if (obj is GeoLine) {
      props.addAll({
        'a': obj.a,
        'b': obj.b,
        'c': obj.c,
        'thickness': obj.thickness,
        'style': obj.style.toString().split('.').last,
      });
    } else if (obj is GeoCircle) {
      props.addAll({
        'centerX': obj.centerX,
        'centerY': obj.centerY,
        'radius': obj.radius,
        'thickness': obj.thickness,
        'filled': obj.filled,
      });
    } else if (obj is GeoInverse) {
      props.addAll({
        'centerPointId': obj.centerPointId,
        'power': obj.power,
      });
    } else if (obj is GeoRotate) {
      props.addAll({
        'centerPointId': obj.centerPointId,
        'angle': obj.angle,
      });
    } else if (obj is GeoDilate) {
      props.addAll({
        'centerPointId': obj.centerPointId,
        'factor': obj.factor,
      });
    } else if (obj is GeoSegment) {
      props.addAll({
        'startPointId': obj.startPointId,
        'endPointId': obj.endPointId,
        'underlyingObjectId': obj.underlyingObjectId,
      });
    } else if (obj is SimpleGeometryObjectList) {
      props.addAll({
        'objectCount': obj.length,
      });
    } else if (obj is ComplexGeometryObjectList) {
      props.addAll({
        'elementCount': obj.elements.length,
        'vertexCount': obj.vertexCount,
      });
    }

    return props;
  }

  /// Encode to JSON string
  String encodeToJson(DAGManager dag, {bool pretty = true}) {
    final map = encode(dag);
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }
}
