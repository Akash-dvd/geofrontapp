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
        );

      case ToolType.line:
        return _LineTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
        );

      case ToolType.circle:
        return _CircleTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
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

  /// Get list of all available tools
  List<ToolType> get availableTools => [
    ToolType.select,
    ToolType.pan,
    ToolType.point,
    ToolType.line,
    ToolType.circle,
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
  _PointTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
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
      final result = await executor.execute(
        commandName: commandName,
        arguments: [position.dx, position.dy],
      );

      if (result.success && result.object != null) {
        onObjectCreated?.call(result.object!, []);
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
  int _labelCounter = 0;

  _LineTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
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
    if (nextType != null && nextType.accepts(GeoPointer)) {
      final point = GeoPointer(
        id: 'point_${DateTime.now().millisecondsSinceEpoch}',
        label: _generatePointLabel(),
        x: position.dx,
        y: position.dy,
      );

      dagManager.addObject(point, []);
      onObjectCreated?.call(point, []);
      return point;
    }
    return null;
  }

  String _generatePointLabel() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_labelCounter < 26) {
      return letters[_labelCounter++];
    }
    return 'P${_labelCounter++}';
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Click first point for line');
  }
}

/// Circle tool - creates circles with center and point
class _CircleTool extends UnifiedTool {
  int _labelCounter = 0;

  _CircleTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
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
    if (nextType != null && nextType.accepts(GeoPointer)) {
      final point = GeoPointer(
        id: 'point_${DateTime.now().millisecondsSinceEpoch}',
        label: _generatePointLabel(),
        x: position.dx,
        y: position.dy,
      );

      dagManager.addObject(point, []);
      onObjectCreated?.call(point, []);
      return point;
    }
    return null;
  }

  String _generatePointLabel() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_labelCounter < 26) {
      return letters[_labelCounter++];
    }
    return 'P${_labelCounter++}';
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Click center point for circle');
  }
}
