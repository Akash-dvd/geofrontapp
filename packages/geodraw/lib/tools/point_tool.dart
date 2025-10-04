import 'package:flutter/material.dart';
import '../models/simple/geo_point.dart';
import 'tool.dart';

/// Tool for creating free points
class PointTool extends BaseTool {
  int _pointCounter = 0;

  PointTool({
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
  });

  @override
  ToolType get type => ToolType.point;

  @override
  String get name => 'Point';

  @override
  IconData get icon => Icons.circle_outlined;

  @override
  String get tooltip => 'Create a free point';

  @override
  void handleInput(PointerEvent event) {
    if (event is PointerDownEvent) {
      final point = GeoPointer(
        id: 'point_${DateTime.now().millisecondsSinceEpoch}',
        label: _generateLabel(),
        x: event.position.dx,
        y: event.position.dy,
      );

      notifyObjectCreated(point, []);
      notifyStateChanged('Point ${point.label} created at (${event.position.dx.toStringAsFixed(1)}, ${event.position.dy.toStringAsFixed(1)})');
    }
  }

  @override
  void reset() {
    // Point tool doesn't need state reset
  }

  @override
  bool get isComplete => true;

  @override
  String get stateDescription => 'Click to create a point';

  String _generateLabel() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_pointCounter < 26) {
      return letters[_pointCounter++];
    } else {
      final cycle = _pointCounter ~/ 26;
      final index = _pointCounter % 26;
      _pointCounter++;
      return '${letters[index]}$cycle';
    }
  }
}
