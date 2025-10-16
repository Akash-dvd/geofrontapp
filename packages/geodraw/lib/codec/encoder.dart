import 'dart:convert';
import '../core/dag/dag_manager.dart';

/// Encodes geometry objects and DAG to JSON format
///
/// Uses object-oriented serialization where each object handles its own
/// toJson() method. This eliminates the need for type switching and makes
/// the encoder simple and maintainable.
class GeoDrawEncoder {
  /// Encode a DAG manager to JSON
  Map<String, dynamic> encode(DAGManager dag) {
    return {
      'type': 'construction',
      'version': '1.0',
      'viewport': _encodeViewport(dag.viewport),
      'objects': dag.nodes.values.map((node) {
        // Delegate to object's toJson() method
        final json = node.object.toJson();
        json['depth'] = node.depth;
        return json;
      }).toList(),
      'metadata': dag.metadata,
    };
  }

  /// Encode viewport settings
  Map<String, dynamic>? _encodeViewport(Viewport? viewport) {
    if (viewport == null) return null;

    return {
      'center': {'x': viewport.center.dx, 'y': viewport.center.dy},
      'zoom': viewport.zoom,
      'gridVisible': viewport.gridVisible,
      'canvasSize': {
        'width': viewport.canvasSize.width,
        'height': viewport.canvasSize.height,
      },
    };
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
