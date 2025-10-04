import 'package:flutter/material.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../dag/dag_manager.dart';
import 'tool.dart';

/// Tool for creating lines through two points
class LineTool extends BaseTool {
  final DAGManager dagManager;
  GeoPoint? _firstPoint;
  int _lineCounter = 0;

  LineTool({
    required this.dagManager,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
  });

  @override
  ToolType get type => ToolType.line;

  @override
  String get name => 'Line';

  @override
  IconData get icon => Icons.horizontal_rule;

  @override
  String get tooltip => 'Create a line through two points';

  @override
  void handleInput(PointerEvent event) {
    if (event is PointerDownEvent) {
      final nearby = dagManager.proximitySearch(event.position, threshold: 15.0);
      final point = nearby.whereType<GeoPoint>().firstOrNull;

      if (_firstPoint == null) {
        // First click: select or create first point
        if (point != null) {
          _firstPoint = point;
          notifyStateChanged('Selected ${point.label}. Click second point.');
        } else {
          _firstPoint = GeoPointer(
            id: 'point_${DateTime.now().millisecondsSinceEpoch}',
            label: _generatePointLabel(),
            x: event.position.dx,
            y: event.position.dy,
          );
          notifyObjectCreated(_firstPoint!, []);
          notifyStateChanged('Created ${_firstPoint!.label}. Click second point.');
        }
      } else {
        // Second click: create line
        GeoPoint secondPoint;
        
        if (point != null && point.id != _firstPoint!.id) {
          secondPoint = point;
          notifyStateChanged('Selected ${point.label}.');
        } else {
          secondPoint = GeoPointer(
            id: 'point_${DateTime.now().millisecondsSinceEpoch}',
            label: _generatePointLabel(),
            x: event.position.dx,
            y: event.position.dy,
          );
          notifyObjectCreated(secondPoint, []);
        }

        final line = GeoLine2P.fromPoints(
          id: 'line_${DateTime.now().millisecondsSinceEpoch}',
          label: _generateLineLabel(),
          p1: _firstPoint!,
          p2: secondPoint,
        );

        notifyObjectCreated(line, [_firstPoint!.id, secondPoint.id]);
        notifyStateChanged('Line ${line.label} created.');
        reset();
      }
    }
  }

  @override
  void reset() {
    _firstPoint = null;
    notifyStateChanged('Click first point for line.');
  }

  @override
  bool get isComplete => _firstPoint == null;

  @override
  String get stateDescription {
    if (_firstPoint == null) {
      return 'Click first point';
    }
    return 'Click second point (selected: ${_firstPoint!.label})';
  }

  int _pointLabelCounter = 0;
  String _generatePointLabel() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_pointLabelCounter < 26) {
      return letters[_pointLabelCounter++];
    }
    return 'P${_pointLabelCounter++}';
  }

  String _generateLineLabel() {
    return 'l${++_lineCounter}';
  }
}
