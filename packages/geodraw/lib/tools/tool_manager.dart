import 'dart:async';

import 'package:flutter/material.dart';
import 'tool.dart';
import 'unified_tool.dart';
import 'incremental_union_tool.dart';
import 'staged_selection_tool.dart';
import '../core/command/command_history.dart';
import '../core/dag/dag_manager.dart';
import '../models/complex/geo_shapes.dart';
import '../models/complex/geo_shapes_list.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';

/// Manages the active tool and tool state
class ToolManager with ToolCallbacksMixin {
  final DAGManager dagManager;
  final CommandHistory? commandHistory;

  ToolType _activeToolType = ToolType.select;
  Tool? _activeTool;

  final _PointLabelGenerator _pointLabelGenerator = _PointLabelGenerator();

  ToolManager({
    required this.dagManager,
    this.commandHistory,
    OnObjectCreated? onObjectCreated,
    OnObjectSelected? onObjectSelected,
    OnToolStateChanged? onToolStateChanged,
  }) {
    this.onObjectCreated = onObjectCreated;
    this.onObjectSelected = onObjectSelected;
    this.onToolStateChanged = onToolStateChanged;
  }

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

    notifyStateChanged(
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

      case ToolType.lineSegment:
        return _SegmentTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
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

      case ToolType.arcThreePoints:
        return _ArcThreePointsTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.polyArc:
        return _PolyArcTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.polygon:
        return _PolygonTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.polyLine:
        return _PolyLineTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.polyArcGon:
        return _PolyArcGonTool(
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

      case ToolType.angleBisector:
        return _AngleBisectorTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.tangent:
        return _TangentTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.intersection:
        return _IntersectionTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          createFreePoint: _createFreePoint,
        );

      case ToolType.reflectLine:
        return _ReflectLineTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          onParameterRequest: null,
        );

      case ToolType.reflectPoint:
        return _ReflectPointTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          onParameterRequest: null,
        );

      case ToolType.reflectCircle:
        return _ReflectCircleTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          onParameterRequest: null,
        );

      case ToolType.rotate:
        return _RotateTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          onParameterRequest: null,
        );

      case ToolType.translate:
        return _TranslateTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          onParameterRequest: null,
        );

      case ToolType.dilate:
        return _DilateTool(
          dagManager: dagManager,
          commandHistory: commandHistory,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
          onParameterRequest: null,
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
    notifyObjectCreated(point, const <String>[]);
    return point;
  }

  /// Get list of all available tools
  List<ToolType> get availableTools => [
    ToolType.select,
    ToolType.pan,
    ToolType.point,
    ToolType.lineSegment,
    ToolType.line,
    ToolType.circle,
    ToolType.circleThreePoints,
    ToolType.arcThreePoints,
    ToolType.polyArc,
    ToolType.polygon,
    ToolType.polyLine,
    ToolType.polyArcGon,
    ToolType.midpoint,
    ToolType.perpendicular,
    ToolType.parallel,
    ToolType.perpBisector,
    ToolType.angleBisector,
    ToolType.tangent,
    ToolType.intersection,
    ToolType.reflectLine,
    ToolType.reflectPoint,
    ToolType.reflectCircle,
    ToolType.rotate,
    ToolType.translate,
    ToolType.dilate,
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
      case ToolType.lineSegment:
        return const ToolMetadata(
          name: 'Segment',
          icon: Icons.show_chart,
          tooltip: 'Create a segment between two points',
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
      case ToolType.arcThreePoints:
        return const ToolMetadata(
          name: 'Arc (3 Points)',
          icon: Icons.panorama_fish_eye,
          tooltip: 'Create a circular arc through three points',
        );
      case ToolType.polyArc:
        return const ToolMetadata(
          name: 'Poly-Arc',
          icon: Icons.architecture,
          tooltip: 'Build a chain of arcs incrementally',
        );
      case ToolType.polygon:
        return const ToolMetadata(
          name: 'Polygon',
          icon: Icons.change_history,
          tooltip: 'Build a polygon incrementally',
        );
      case ToolType.polyLine:
        return const ToolMetadata(
          name: 'PolyLine',
          icon: Icons.show_chart,
          tooltip: 'Build a polyline incrementally',
        );
      case ToolType.polyArcGon:
        return const ToolMetadata(
          name: 'Poly-Arc-Gon',
          icon: Icons.all_inclusive,
          tooltip: 'Build a closed poly-arc incrementally',
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
      case ToolType.tangent:
        return const ToolMetadata(
          name: 'Tangent',
          icon: Icons.rotate_90_degrees_cw,
          tooltip: 'Create tangents between a point and circle or two circles',
        );
      case ToolType.reflectLine:
        return const ToolMetadata(
          name: 'Reflect Line',
          icon: Icons.flip,
          tooltip: 'Reflect object across a line',
        );
      case ToolType.reflectPoint:
        return const ToolMetadata(
          name: 'Reflect Point',
          icon: Icons.flip_camera_android,
          tooltip: 'Reflect object across a point',
        );
      case ToolType.reflectCircle:
        return const ToolMetadata(
          name: 'Reflect Circle',
          icon: Icons.flip_camera_ios,
          tooltip: 'Reflect object across a circle (inversion)',
        );
      case ToolType.rotate:
        return const ToolMetadata(
          name: 'Rotate',
          icon: Icons.rotate_left,
          tooltip: 'Rotate object around a center point',
        );
      case ToolType.translate:
        return const ToolMetadata(
          name: 'Translate',
          icon: Icons.open_in_full,
          tooltip: 'Translate object by a vector',
        );
      case ToolType.dilate:
        return const ToolMetadata(
          name: 'Dilate',
          icon: Icons.center_focus_strong,
          tooltip: 'Scale object from a center point',
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

/// Segment tool - creates segments between two points
class _SegmentTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _SegmentTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.lineSegment;

  @override
  String get commandName => 'segment';

  @override
  String get name => 'Segment';

  @override
  IconData get icon => Icons.show_chart;

  @override
  String get tooltip => 'Create a segment between two points';

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
    notifyStateChanged('Click first point for segment');
  }
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

/// Arc through three points tool
class _ArcThreePointsTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _ArcThreePointsTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.arcThreePoints;

  @override
  String get commandName => 'arc3';

  @override
  String get name => 'Arc (3 Points)';

  @override
  IconData get icon => Icons.panorama_fish_eye;

  @override
  String get tooltip => 'Create a circular arc through three points';

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
    notifyStateChanged('Select three points for arc');
  }
}

/// Poly-arc tool - incrementally builds chained arcs via point selection
class _PolyArcTool extends IncrementalUnionTool<GeoPolyArc> {
  _PolyArcTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  final GeoPointer Function(Offset position) createFreePoint;

  @override
  ToolType get type => ToolType.polyArc;

  @override
  String get name => 'Poly-Arc';

  @override
  IconData get icon => Icons.architecture;

  @override
  String get tooltip => 'Build a chain of arcs incrementally';

  @override
  String get createCommandName => 'polyArc';

  @override
  String? get extendCommandName => 'extendPolyArc';

  @override
  String get creatingMessage => 'Creating poly-arc...';

  @override
  String get extendingMessage => 'Extending poly-arc...';

  @override
  String creationSuccessMessage(GeoPolyArc object) =>
      'Poly-arc created. Select two more points to extend';

  @override
  String extensionSuccessMessage(GeoPolyArc object) =>
      'Poly-arc extended. Select two more points to continue';

  @override
  String formatCreationFailure(String reason) =>
      'Unable to create poly-arc: $reason';

  @override
  String formatExtensionFailure(String reason) =>
      'Unable to extend poly-arc: $reason';

  @override
  String get unresolvedInputMessage =>
      'Unable to resolve a point at that location';

  @override
  bool isInitialInputComplete(List<dynamic> inputs) =>
      inputs.length >= 3 && inputs.length.isOdd;

  @override
  int extensionBatchSize(GeoPolyArc object) => 2;

  @override
  List<dynamic> buildCreateArguments(List<dynamic> inputs) =>
      List<dynamic>.from(inputs);

  @override
  List<dynamic> buildExtendArguments(
    GeoPolyArc object,
    List<dynamic> newInputs,
  ) {
    if (newInputs.length < 2) {
      return <dynamic>[object];
    }
    return <dynamic>[object, newInputs[newInputs.length - 2], newInputs.last];
  }

  @override
  List<dynamic>? resolveDependencies(List<String> dependencyIds) {
    final resolved = <GeoPoint>[];
    for (final id in dependencyIds) {
      final candidate = dagManager.getObject(id);
      if (candidate is GeoPoint) {
        resolved.add(candidate);
        continue;
      }
      return null;
    }
    return resolved;
  }

  @override
  dynamic resolveInput(Offset position) {
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    for (final candidate in nearby) {
      if (candidate is GeoPoint) {
        return candidate;
      }
    }
    return createFreePoint(position);
  }

  @override
  String initialPrompt(int inputCount) {
    switch (inputCount) {
      case 0:
        return 'Select first point for poly-arc';
      case 1:
        return 'Select second point for poly-arc';
      case 2:
        return 'Select third point to complete first arc';
      default:
        return 'Select points for poly-arc';
    }
  }

  @override
  String extensionPrompt(int newInputCount) {
    if (newInputCount <= 0) {
      return 'Select control point to extend poly-arc';
    }
    if (newInputCount == 1) {
      return 'Select end point to complete the new arc';
    }
    return 'Select control point to extend poly-arc';
  }

  @override
  String? validateNextInput(List<dynamic> currentInputs, dynamic candidate) {
    if (candidate is! GeoPoint) {
      return 'Select a point to continue';
    }
    if (currentInputs.isNotEmpty) {
      final last = currentInputs.last;
      if (last is GeoPoint && last.id == candidate.id) {
        return 'Select a distinct point to continue';
      }
    }
    return null;
  }
}

/// Polygon tool - incrementally builds polygon via point selection
class _PolygonTool extends IncrementalUnionTool<GeoPolygon> {
  _PolygonTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  final GeoPointer Function(Offset position) createFreePoint;

  @override
  ToolType get type => ToolType.polygon;

  @override
  String get name => 'Polygon';

  @override
  IconData get icon => Icons.change_history;

  @override
  String get tooltip => 'Build a polygon incrementally';

  @override
  String get createCommandName => 'polygon';

  @override
  String? get extendCommandName => 'extendPolygon';

  @override
  String get creatingMessage => 'Creating polygon...';

  @override
  String get extendingMessage => 'Extending polygon...';

  @override
  String creationSuccessMessage(GeoPolygon object) =>
      'Polygon created with ${object.vertexCount} vertices. Select another point to extend';

  @override
  String extensionSuccessMessage(GeoPolygon object) =>
      'Polygon extended to ${object.vertexCount} vertices. Select another point to continue';

  @override
  String formatCreationFailure(String reason) =>
      'Unable to create polygon: $reason';

  @override
  String formatExtensionFailure(String reason) =>
      'Unable to extend polygon: $reason';

  @override
  String get unresolvedInputMessage =>
      'Unable to resolve a point at that location';

  @override
  bool isInitialInputComplete(List<dynamic> inputs) => inputs.length >= 3;

  @override
  int extensionBatchSize(GeoPolygon object) => 1;

  @override
  List<dynamic> buildCreateArguments(List<dynamic> inputs) =>
      List<dynamic>.from(inputs);

  @override
  List<dynamic> buildExtendArguments(
    GeoPolygon object,
    List<dynamic> newInputs,
  ) {
    if (newInputs.isEmpty) {
      return <dynamic>[object];
    }
    return <dynamic>[object, newInputs.last];
  }

  @override
  List<dynamic>? resolveDependencies(List<String> dependencyIds) {
    final resolved = <GeoPoint>[];
    for (final id in dependencyIds) {
      final candidate = dagManager.getObject(id);
      if (candidate is GeoPoint) {
        resolved.add(candidate);
        continue;
      }
      return null;
    }
    return resolved;
  }

  @override
  dynamic resolveInput(Offset position) {
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    for (final candidate in nearby) {
      if (candidate is GeoPoint) {
        return candidate;
      }
    }
    return createFreePoint(position);
  }

  @override
  String initialPrompt(int inputCount) {
    switch (inputCount) {
      case 0:
        return 'Select first vertex for polygon';
      case 1:
        return 'Select second vertex for polygon';
      case 2:
        return 'Select third vertex to create polygon';
      default:
        return 'Select vertices for polygon ($inputCount so far)';
    }
  }

  @override
  String extensionPrompt(int newInputCount) {
    return 'Select another vertex to extend polygon';
  }

  @override
  String? validateNextInput(List<dynamic> currentInputs, dynamic candidate) {
    if (candidate is! GeoPoint) {
      return 'Select a point to continue';
    }
    if (currentInputs.isNotEmpty) {
      final last = currentInputs.last;
      if (last is GeoPoint && last.id == candidate.id) {
        return 'Select a distinct point to continue';
      }
    }
    return null;
  }
}

/// PolyLine tool - incrementally builds polyline via point selection
class _PolyLineTool extends IncrementalUnionTool<GeoPolyLine> {
  _PolyLineTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  final GeoPointer Function(Offset position) createFreePoint;

  @override
  ToolType get type => ToolType.polyLine;

  @override
  String get name => 'PolyLine';

  @override
  IconData get icon => Icons.show_chart;

  @override
  String get tooltip => 'Build a polyline incrementally';

  @override
  String get createCommandName => 'polyLine';

  @override
  String? get extendCommandName => 'extendPolyLine';

  @override
  String get creatingMessage => 'Creating polyline...';

  @override
  String get extendingMessage => 'Extending polyline...';

  @override
  String creationSuccessMessage(GeoPolyLine object) =>
      'Polyline created with ${object.vertexCount} points. Select another point to extend';

  @override
  String extensionSuccessMessage(GeoPolyLine object) =>
      'Polyline extended to ${object.vertexCount} points. Select another point to continue';

  @override
  String formatCreationFailure(String reason) =>
      'Unable to create polyline: $reason';

  @override
  String formatExtensionFailure(String reason) =>
      'Unable to extend polyline: $reason';

  @override
  String get unresolvedInputMessage =>
      'Unable to resolve a point at that location';

  @override
  bool isInitialInputComplete(List<dynamic> inputs) => inputs.length >= 2;

  @override
  int extensionBatchSize(GeoPolyLine object) => 1;

  @override
  List<dynamic> buildCreateArguments(List<dynamic> inputs) =>
      List<dynamic>.from(inputs);

  @override
  List<dynamic> buildExtendArguments(
    GeoPolyLine object,
    List<dynamic> newInputs,
  ) {
    if (newInputs.isEmpty) {
      return <dynamic>[object];
    }
    return <dynamic>[object, newInputs.last];
  }

  @override
  List<dynamic>? resolveDependencies(List<String> dependencyIds) {
    final resolved = <GeoPoint>[];
    for (final id in dependencyIds) {
      final candidate = dagManager.getObject(id);
      if (candidate is GeoPoint) {
        resolved.add(candidate);
        continue;
      }
      return null;
    }
    return resolved;
  }

  @override
  dynamic resolveInput(Offset position) {
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    for (final candidate in nearby) {
      if (candidate is GeoPoint) {
        return candidate;
      }
    }
    return createFreePoint(position);
  }

  @override
  String initialPrompt(int inputCount) {
    switch (inputCount) {
      case 0:
        return 'Select start point for polyline';
      case 1:
        return 'Select second point to create polyline';
      default:
        return 'Select points for polyline ($inputCount so far)';
    }
  }

  @override
  String extensionPrompt(int newInputCount) {
    return 'Select another point to extend polyline';
  }

  @override
  String? validateNextInput(List<dynamic> currentInputs, dynamic candidate) {
    if (candidate is! GeoPoint) {
      return 'Select a point to continue';
    }
    if (currentInputs.isNotEmpty) {
      final last = currentInputs.last;
      if (last is GeoPoint && last.id == candidate.id) {
        return 'Select a distinct point to continue';
      }
    }
    return null;
  }
}

/// PolyArcGon tool - incrementally builds closed poly-arc via point selection
class _PolyArcGonTool extends IncrementalUnionTool<GeoPolyArcGon<GeoArc>> {
  _PolyArcGonTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  final GeoPointer Function(Offset position) createFreePoint;

  @override
  ToolType get type => ToolType.polyArcGon;

  @override
  String get name => 'Poly-Arc-Gon';

  @override
  IconData get icon => Icons.all_inclusive;

  @override
  String get tooltip => 'Build a closed poly-arc incrementally';

  @override
  String get createCommandName => 'polyArcGon';

  @override
  String? get extendCommandName => 'extendPolyArcGon';

  @override
  String get creatingMessage => 'Creating poly-arc-gon...';

  @override
  String get extendingMessage => 'Extending poly-arc-gon...';

  @override
  String creationSuccessMessage(GeoPolyArcGon<GeoArc> object) =>
      'Poly-arc-gon created. Select two more points to extend';

  @override
  String extensionSuccessMessage(GeoPolyArcGon<GeoArc> object) =>
      'Poly-arc-gon extended. Select two more points to continue';

  @override
  String formatCreationFailure(String reason) =>
      'Unable to create poly-arc-gon: $reason';

  @override
  String formatExtensionFailure(String reason) =>
      'Unable to extend poly-arc-gon: $reason';

  @override
  String get unresolvedInputMessage =>
      'Unable to resolve a point at that location';

  @override
  bool isInitialInputComplete(List<dynamic> inputs) =>
      inputs.length >= 4 && inputs.length.isOdd;

  @override
  int extensionBatchSize(GeoPolyArcGon<GeoArc> object) => 2;

  @override
  List<dynamic> buildCreateArguments(List<dynamic> inputs) =>
      List<dynamic>.from(inputs);

  @override
  List<dynamic> buildExtendArguments(
    GeoPolyArcGon<GeoArc> object,
    List<dynamic> newInputs,
  ) {
    if (newInputs.length < 2) {
      return <dynamic>[object];
    }
    return <dynamic>[object, newInputs[newInputs.length - 2], newInputs.last];
  }

  @override
  List<dynamic>? resolveDependencies(List<String> dependencyIds) {
    final resolved = <GeoPoint>[];
    for (final id in dependencyIds) {
      final candidate = dagManager.getObject(id);
      if (candidate is GeoPoint) {
        resolved.add(candidate);
        continue;
      }
      return null;
    }
    return resolved;
  }

  @override
  dynamic resolveInput(Offset position) {
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    for (final candidate in nearby) {
      if (candidate is GeoPoint) {
        return candidate;
      }
    }
    return createFreePoint(position);
  }

  @override
  String initialPrompt(int inputCount) {
    switch (inputCount) {
      case 0:
        return 'Select first point for poly-arc-gon';
      case 1:
        return 'Select second point for poly-arc-gon';
      case 2:
        return 'Select third point for poly-arc-gon';
      case 3:
        return 'Select fourth point to complete first arc and close';
      default:
        return 'Select points for poly-arc-gon';
    }
  }

  @override
  String extensionPrompt(int newInputCount) {
    if (newInputCount <= 0) {
      return 'Select control point to extend poly-arc-gon';
    }
    if (newInputCount == 1) {
      return 'Select end point to complete the new arc';
    }
    return 'Select control point to extend poly-arc-gon';
  }

  @override
  String? validateNextInput(List<dynamic> currentInputs, dynamic candidate) {
    if (candidate is! GeoPoint) {
      return 'Select a point to continue';
    }
    if (currentInputs.isNotEmpty) {
      final last = currentInputs.last;
      if (last is GeoPoint && last.id == candidate.id) {
        return 'Select a distinct point to continue';
      }
    }
    return null;
  }
}

/// Reflect Line tool - reflects object across a line
class _ReflectLineTool extends StagedSelectionTool {
  _ReflectLineTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.reflectLine;

  @override
  String get name => 'Reflect Line';

  @override
  IconData get icon => Icons.flip;

  @override
  String get tooltip => 'Reflect object across a line';

  @override
  String get commandName => 'reflect';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoLine, GeoLine2P}, // Stage 1: Line
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to reflect';
      case 1:
        return 'Select line to reflect across';
      default:
        return 'Reflecting...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    return [selectedObjects[0], selectedObjects[1]];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (reflection)';

  @override
  String failureMessage(String reason) =>
      'Unable to reflect object: $reason';
}

/// Reflect Point tool - reflects object across a point
class _ReflectPointTool extends StagedSelectionTool {
  _ReflectPointTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.reflectPoint;

  @override
  String get name => 'Reflect Point';

  @override
  IconData get icon => Icons.flip_camera_android;

  @override
  String get tooltip => 'Reflect object across a point';

  @override
  String get commandName => 'reflect';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoPoint, GeoPointer, GeoMidpoint}, // Stage 1: Point
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to reflect';
      case 1:
        return 'Select point to reflect across';
      default:
        return 'Reflecting...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    return [selectedObjects[0], selectedObjects[1]];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (reflection)';

  @override
  String failureMessage(String reason) =>
      'Unable to reflect object: $reason';
}

/// Reflect Circle tool - reflects object across a circle (inversion)
class _ReflectCircleTool extends StagedSelectionTool {
  _ReflectCircleTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.reflectCircle;

  @override
  String get name => 'Reflect Circle';

  @override
  IconData get icon => Icons.flip_camera_ios;

  @override
  String get tooltip => 'Reflect object across a circle (inversion)';

  @override
  String get commandName => 'reflect';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoCircle, GeoCircle2P, GeoCircle3P}, // Stage 1: Circle
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to invert';
      case 1:
        return 'Select circle for inversion';
      default:
        return 'Inverting...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    return [selectedObjects[0], selectedObjects[1]];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (inversion)';

  @override
  String failureMessage(String reason) =>
      'Unable to invert object: $reason';
}

/// Rotate tool - rotates object around a center point by an angle
class _RotateTool extends StagedSelectionTool {
  _RotateTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.rotate;

  @override
  String get name => 'Rotate';

  @override
  IconData get icon => Icons.rotate_left;

  @override
  String get tooltip => 'Rotate object around a center point';

  @override
  String get commandName => 'rotate';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoPoint, GeoPointer, GeoMidpoint}, // Stage 1: Center point
  ];

  @override
  List<ParameterSpec> get parameterSpecs => const [
    ParameterSpec(
      key: 'angle',
      label: 'Angle (degrees)',
      type: ParameterType.angle,
      defaultValue: 90.0,
      hint: 'Enter rotation angle in degrees (+ for CCW, - for CW)',
    ),
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to rotate';
      case 1:
        return 'Select center point for rotation';
      default:
        return 'Rotating...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    final angle = (parameters?['angle'] ?? 90.0) as double;
    return [selectedObjects[0], selectedObjects[1], angle];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (rotated)';

  @override
  String failureMessage(String reason) =>
      'Unable to rotate object: $reason';
}

/// Translate tool - translates object by a vector
class _TranslateTool extends StagedSelectionTool {
  _TranslateTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.translate;

  @override
  String get name => 'Translate';

  @override
  IconData get icon => Icons.open_in_full;

  @override
  String get tooltip => 'Translate object by a vector';

  @override
  String get commandName => 'translate';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoSegment, GeoSegment2P}, // Stage 1: Segment (defines vector)
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to translate';
      case 1:
        return 'Select segment (defines translation vector)';
      default:
        return 'Translating...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    return [selectedObjects[0], selectedObjects[1]];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (translated)';

  @override
  String failureMessage(String reason) =>
      'Unable to translate object: $reason';
}

/// Dilate tool - scales object from a center by a factor
class _DilateTool extends StagedSelectionTool {
  _DilateTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.dilate;

  @override
  String get name => 'Dilate';

  @override
  IconData get icon => Icons.center_focus_strong;

  @override
  String get tooltip => 'Scale object from a center point';

  @override
  String get commandName => 'dilate';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoPoint, GeoPointer, GeoMidpoint}, // Stage 1: Center point
  ];

  @override
  List<ParameterSpec> get parameterSpecs => const [
    ParameterSpec(
      key: 'scale',
      label: 'Scale Factor',
      type: ParameterType.number,
      defaultValue: 2.0,
      hint: 'Enter scale factor (> 1 to enlarge, < 1 to shrink)',
    ),
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to dilate';
      case 1:
        return 'Select center point for dilation';
      default:
        return 'Dilating...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    final scale = (parameters?['scale'] ?? 2.0) as double;
    return [selectedObjects[0], selectedObjects[1], scale];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (dilated)';

  @override
  String failureMessage(String reason) =>
      'Unable to dilate object: $reason';
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

/// Angle bisector tool - constructs angle bisector from 3 points or 2 lines
class _AngleBisectorTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _AngleBisectorTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.angleBisector;

  @override
  String get commandName => 'anglebisector';

  @override
  String get name => 'Angle Bisector';

  @override
  IconData get icon => Icons.call_split;

  @override
  String get tooltip =>
      'Create angle bisector from three points (vertex at middle) or two lines';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    // Can accept GeoPoint or GeoLine depending on the pattern
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    // Cannot create GeoLine at position, user must select existing lines
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three points (or two lines) for angle bisector');
  }
}

/// Intersection tool - finds intersection points between two objects
class _IntersectionTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _IntersectionTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.intersection;

  @override
  String get commandName => 'intersection';

  @override
  String get name => 'Intersection';

  @override
  IconData get icon => Icons.control_point;

  @override
  String get tooltip => 'Find intersection points between two objects';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    // Intersection requires selecting existing objects (lines, circles, points)
    // Cannot create new objects at position
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two objects to find intersection');
  }
}

/// Tangent tool - constructs tangents from point/circle inputs
class _TangentTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _TangentTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.tangent;

  @override
  String get commandName => 'tangent';

  @override
  String get name => 'Tangent';

  @override
  IconData get icon => Icons.rotate_90_degrees_cw;

  @override
  String get tooltip => 'Create tangents between point/circle inputs';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select point or circle for tangent');
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
