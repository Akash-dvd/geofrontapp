import 'package:flutter/material.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_circle.dart';
import '../dag/dag_manager.dart';
import 'tool.dart';

/// Tool for creating circles (center + point on circumference)
class CircleTool extends BaseTool {
  final DAGManager dagManager;
  GeoPoint? _centerPoint;
  int _circleCounter = 0;

  CircleTool({
    required this.dagManager,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
  });

  @override
  ToolType get type => ToolType.circle;

  @override
  String get name => 'Circle';

  @override
  IconData get icon => Icons.circle_outlined;

  @override
  String get tooltip => 'Create a circle with center and point';

  @override
  void handleInput(PointerEvent event) {
    if (event is PointerDownEvent) {
      final nearby = dagManager.proximitySearch(event.position, threshold: 15.0);
      final point = nearby.whereType<GeoPoint>().firstOrNull;

      if (_centerPoint == null) {
        // First click: select or create center point
        if (point != null) {
          _centerPoint = point;
          notifyStateChanged('Selected ${point.label} as center. Click point on circle.');
        } else {
          _centerPoint = GeoPointer(
            id: 'point_${DateTime.now().millisecondsSinceEpoch}',
            label: _generatePointLabel(),
            x: event.position.dx,
            y: event.position.dy,
          );
          notifyObjectCreated(_centerPoint!, []);
          notifyStateChanged('Created ${_centerPoint!.label} as center. Click point on circle.');
        }
      } else {
        // Second click: create circle
        GeoPoint circumferencePoint;
        
        if (point != null && point.id != _centerPoint!.id) {
          circumferencePoint = point;
        } else {
          circumferencePoint = GeoPointer(
            id: 'point_${DateTime.now().millisecondsSinceEpoch}',
            label: _generatePointLabel(),
            x: event.position.dx,
            y: event.position.dy,
          );
          notifyObjectCreated(circumferencePoint, []);
        }

        final circle = GeoCircle2P.fromPoints(
          id: 'circle_${DateTime.now().millisecondsSinceEpoch}',
          label: _generateCircleLabel(),
          center: _centerPoint!,
          pointOnCircle: circumferencePoint,
        );

        notifyObjectCreated(circle, [_centerPoint!.id, circumferencePoint.id]);
        notifyStateChanged('Circle ${circle.label} created.');
        reset();
      }
    }
  }

  @override
  void reset() {
    _centerPoint = null;
    notifyStateChanged('Click center point for circle.');
  }

  @override
  bool get isComplete => _centerPoint == null;

  @override
  String get stateDescription {
    if (_centerPoint == null) {
      return 'Click center point';
    }
    return 'Click point on circle (center: ${_centerPoint!.label})';
  }

  int _pointLabelCounter = 0;
  String _generatePointLabel() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_pointLabelCounter < 26) {
      return letters[_pointLabelCounter++];
    }
    return 'P${_pointLabelCounter++}';
  }

  String _generateCircleLabel() {
    return 'c${++_circleCounter}';
  }
}
