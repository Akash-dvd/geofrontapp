import 'package:flutter/material.dart';
import 'tool.dart';
import 'unified_tool.dart';
import '../core/dag/dag_manager.dart';
import '../core/command/command_history.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';

/// Manages the active tool and tool state
class ToolManager {
  final DAGManager dagManager;
  final CommandHistory? commandHistory;

  ToolType _activeToolType = ToolType.select;
  Tool? _activeTool;

  final _PointLabelGenerator _pointLabelGenerator = _PointLabelGenerator();

  final OnObjectCreated? onObjectCreated;
  final OnObjectSelected? onObjectSelected;
  final OnToolStateChanged? onToolStateChanged;

  ToolManager({
    required this.dagManager,
    this.commandHistory,
    this.onObjectCreated,
    this.onObjectSelected,
    this.onToolStateChanged,
  });

  /// Get the currently active tool type
  ToolType get activeToolType => _activeToolType;

  /// Get the currently active tool instance
  Tool? get activeTool => _activeTool;

  /// Select a tool by type
  void selectTool(ToolType type) {
    // Reset current tool before switching
    _activeTool?.reset();

    _activeToolType = type;
    _activeTool = _createTool(type);

    onToolStateChanged?.call(
      _activeTool?.stateDescription ?? 'No tool selected',
    );
  }

  /// Handle pointer input
  void handleInput(PointerEvent event) {
    _activeTool?.handleInput(event);
  }

  /// Reset the active tool
  void resetTool() {
    _activeTool?.reset();
  }

  /// Create a tool instance by type (inline implementation)
  Tool? _createTool(ToolType type) {
    switch (type) {
      case ToolType.point:
        return _PointTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          labelGenerator: _pointLabelGenerator,
        );

      case ToolType.line:
        return _LineTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.circle:
        return _CircleTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.circleThreePoints:
        return _CircleThreePointsTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.midpoint:
        return _MidpointTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.perpendicular:
        return _PerpendicularTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.parallel:
        return _ParallelTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.perpBisector:
        return _PerpBisectorTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.select:
      case ToolType.pan:
        // These tools don't create geometry
        return null;

      default:
        // Other tools not yet implemented
        return null;
    }
  }

  GeoPointer _createFreePoint(Offset position) {
    final point = GeoPointer(
      id: dagManager.generateId('point'),
      label: _pointLabelGenerator.next(),
      x: position.dx,
      y: position.dy,
    );

    dagManager.addObject(point, const <String>[]);
    onObjectCreated?.call(point, const <String>[]);
    return point;
  }

  /// Get list of all available tools
  List<ToolType> get availableTools => [
    ToolType.select,
    ToolType.pan,
    ToolType.point,
    ToolType.line,
    ToolType.circle,
    ToolType.circleThreePoints,
    ToolType.midpoint,
    ToolType.perpendicular,
    ToolType.parallel,
    ToolType.perpBisector,
  ];

  /// Check if a tool type is available
  bool isToolAvailable(ToolType type) {
    return availableTools.contains(type);
  }

  /// Get tool metadata
  ToolMetadata getToolMetadata(ToolType type) {
    switch (type) {
      case ToolType.select:
        return const ToolMetadata(
          name: 'Select',
          icon: Icons.touch_app,
          tooltip: 'Select and move objects',
        );
      case ToolType.pan:
        return const ToolMetadata(
          name: 'Pan',
          icon: Icons.pan_tool,
          tooltip: 'Pan the canvas',
        );
      case ToolType.point:
        return const ToolMetadata(
          name: 'Point',
          icon: Icons.circle,
          tooltip: 'Create a free point',
        );
      case ToolType.line:
        return const ToolMetadata(
          name: 'Line',
          icon: Icons.horizontal_rule,
          tooltip: 'Create a line through two points',
        );
      case ToolType.circle:
        return const ToolMetadata(
          name: 'Circle',
          icon: Icons.circle_outlined,
          tooltip: 'Create a circle',
        );
      case ToolType.circleThreePoints:
        return const ToolMetadata(
          name: 'Circle (3 Points)',
          icon: Icons.circle,
          tooltip: 'Create a circle through three points',
        );
      case ToolType.midpoint:
        return const ToolMetadata(
          name: 'Midpoint',
          icon: Icons.adjust,
          tooltip: 'Create midpoint of two points',
        );
      case ToolType.perpendicular:
        return const ToolMetadata(
          name: 'Perpendicular Line',
          icon: Icons.rotate_90_degrees_ccw,
          tooltip: 'Create a line perpendicular to another line',
        );
      case ToolType.parallel:
        return const ToolMetadata(
          name: 'Parallel Line',
          icon: Icons.swap_calls,
          tooltip: 'Create a line parallel to another line',
        );
      case ToolType.perpBisector:
        return const ToolMetadata(
          name: 'Perpendicular Bisector',
          icon: Icons.straighten,
          tooltip: 'Create the perpendicular bisector of two points',
        );
      default:
        return const ToolMetadata(
          name: 'Unknown',
          icon: Icons.help_outline,
          tooltip: 'Not implemented',
        );
    }
  }
}

/// Tool metadata for UI display
class ToolMetadata {
  final String name;
  final IconData icon;
  final String tooltip;

  const ToolMetadata({
    required this.name,
    required this.icon,
    required this.tooltip,
  });
}

// ============================================================================
// Inline Tool Implementations (merged from unified_*_tool.dart files)
// ============================================================================

/// Point tool - creates points immediately on click
class _PointTool extends UnifiedTool {
  final _PointLabelGenerator labelGenerator;

  _PointTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.labelGenerator,
  });

  @override
  ToolType get type => ToolType.point;

  @override
  String get commandName => 'point';

  @override
  String get name => 'Point';

  @override
  IconData get icon => Icons.circle;

  @override
  String get tooltip => 'Create a free point';

  @override
  void handleInput(PointerEvent event) {
    if (event is PointerDownEvent) {
      _createPointAt(event.position);
    }
  }

  Future<void> _createPointAt(Offset position) async {
    try {
      final label = labelGenerator.next();
      final result = await executor.execute(
        commandName: commandName,
        arguments: [position.dx, position.dy],
        customLabel: label,
      );

      if (result.success && result.object is GeometryObject) {
        final geometry = result.object as GeometryObject;
        onObjectCreated?.call(geometry, geometry.dependencies);
        notifyStateChanged(result.message);
      } else {
        notifyStateChanged('Error: ${result.message}');
      }
    } catch (e) {
      notifyStateChanged('Error: $e');
    }
  }

  @override
  GeometryObject? createObjectAtPosition(Offset position) => null;

  @override
  void reset() {
    notifyStateChanged('Click to create a point');
  }

  @override
  bool get isComplete => true;

  @override
  String get stateDescription => 'Click to create a point';
}

/// Line tool - creates lines through two points
class _LineTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _LineTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.line;

  @override
  String get commandName => 'line';

  @override
  String get name => 'Line';

  @override
  IconData get icon => Icons.horizontal_rule;

  @override
  String get tooltip => 'Create a line through two points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Click first point for line');
  }
}

/// Circle tool - creates circles with center and point
class _CircleTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _CircleTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.circle;

  @override
  String get commandName => 'circle';

  @override
  String get name => 'Circle';

  @override
  IconData get icon => Icons.circle_outlined;

  @override
  String get tooltip => 'Create a circle with center and point';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Click center point for circle');
  }
}

/// Circle through three points tool
class _CircleThreePointsTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _CircleThreePointsTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.circleThreePoints;

  @override
  String get commandName => 'circle3';

  @override
  String get name => 'Circle (3 Points)';

  @override
  IconData get icon => Icons.circle;

  @override
  String get tooltip => 'Create a circle through three points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three points for circle');
  }
}

/// Midpoint tool - constructs midpoint between two points
class _MidpointTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _MidpointTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.midpoint;

  @override
  String get commandName => 'midpoint';

  @override
  String get name => 'Midpoint';

  @override
  IconData get icon => Icons.adjust;

  @override
  String get tooltip => 'Create midpoint of two points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two points for midpoint');
  }
}

/// Perpendicular line tool - builds a line perpendicular to a reference line
class _PerpendicularTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _PerpendicularTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.perpendicular;

  @override
  String get commandName => 'perpendicular';

  @override
  String get name => 'Perpendicular Line';

  @override
  IconData get icon => Icons.rotate_90_degrees_ccw;

  @override
  String get tooltip => 'Create a line perpendicular to another line';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select a line and a point for perpendicular');
  }
}

/// Parallel line tool - builds a line parallel to a reference line
class _ParallelTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _ParallelTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.parallel;

  @override
  String get commandName => 'parallel';

  @override
  String get name => 'Parallel Line';

  @override
  IconData get icon => Icons.swap_calls;

  @override
  String get tooltip => 'Create a line parallel to another line';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select a line and a point for parallel line');
  }
}

/// Perpendicular bisector tool - constructs bisector of segment formed by two points
class _PerpBisectorTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _PerpBisectorTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.perpBisector;

  @override
  String get commandName => 'perpbisector';

  @override
  String get name => 'Perpendicular Bisector';

  @override
  IconData get icon => Icons.straighten;

  @override
  String get tooltip => 'Create the perpendicular bisector of two points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two points for perpendicular bisector');
  }
}

class _PointLabelGenerator {
  int _counter = 0;

  String next() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_counter < letters.length) {
      return letters[_counter++];
    }
    return 'P${_counter++}';
  }
}
