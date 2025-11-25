import 'dart:async';

import 'package:flutter/material.dart';
import 'tool.dart';
import 'tool_registry.dart';
import 'tool_catalog.dart';
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
    _registerAllTools();
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

  /// Create a tool instance using the registry
  Tool? _createTool(ToolType type) {
    final context = ToolFactoryContext(
          dagManager: dagManager,
      commandHistory: commandHistory, // Optional: only for CLI/AI logging, not core functionality
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
      createFreePoint: _createFreePoint,
          labelGenerator: _pointLabelGenerator,
      onParameterRequest: null,
    );

    return ToolRegistry().createTool(type, context);
  }

  /// Register all tools with the registry
  void _registerAllTools() {
    final registry = ToolRegistry();

    // Point tool
    registry.registerFromManager(
      ToolType.point,
      (context) => _PointTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        labelGenerator: context.labelGenerator as _PointLabelGenerator,
      ),
      const ToolCatalogEntry(
        id: 'point',
        label: 'Point',
        icon: Icons.gps_fixed,
        assetIcon: 'assets/tool_icons/point.svg',
        command: 'Point[]',
        toolType: ToolType.point,
        implemented: true,
      ),
    );

    // Segment tool
    registry.registerFromManager(
      ToolType.lineSegment,
      (context) => _SegmentTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'segment',
        label: 'Segment',
        icon: Icons.show_chart,
        assetIcon: 'assets/tool_icons/segment.svg',
        command: 'Segment[]',
        toolType: ToolType.lineSegment,
        implemented: true,
      ),
    );

    // Line tool
    registry.registerFromManager(
      ToolType.line,
      (context) => _LineTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'line',
        label: 'Line',
        icon: Icons.horizontal_rule,
        assetIcon: 'assets/tool_icons/line.svg',
        command: 'Line[]',
        toolType: ToolType.line,
        implemented: true,
      ),
    );

    // Circle tool
    registry.registerFromManager(
      ToolType.circle,
      (context) => _CircleTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'circle_center',
        label: 'Circle (Center)',
        icon: Icons.circle_outlined,
        assetIcon: 'assets/tool_icons/circle2.svg',
        command: 'Circle[]',
        toolType: ToolType.circle,
        implemented: true,
      ),
    );

    // Circle Three Points tool
    registry.registerFromManager(
      ToolType.circleThreePoints,
      (context) => _CircleThreePointsTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'circle_three_points',
        label: 'Circle (3 Points)',
        icon: Icons.circle,
        assetIcon: 'assets/tool_icons/circle3.svg',
        command: 'Circle3[]',
        toolType: ToolType.circleThreePoints,
        implemented: true,
      ),
    );

    // Arc Three Points tool
    registry.registerFromManager(
      ToolType.arcThreePoints,
      (context) => _ArcThreePointsTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'circular_arc',
        label: 'Arc (3 Points)',
        icon: Icons.panorama_fish_eye,
        assetIcon: 'assets/tool_icons/arc.svg',
        command: 'Arc3[]',
        toolType: ToolType.arcThreePoints,
        implemented: true,
      ),
    );

    // PolyArc tool
    registry.registerFromManager(
      ToolType.polyArc,
      (context) => _PolyArcTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'poly_arc',
        label: 'Poly-Arc',
        icon: Icons.architecture,
        command: 'PolyArc[]',
        toolType: ToolType.polyArc,
        implemented: true,
      ),
    );

    // Polygon tool
    registry.registerFromManager(
      ToolType.polygon,
      (context) => _PolygonTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'polygon',
        label: 'Polygon',
        icon: Icons.change_history,
        assetIcon: 'assets/tool_icons/polygon.svg',
        command: 'Polygon[]',
        toolType: ToolType.polygon,
        implemented: true,
      ),
    );

    // PolyLine tool
    registry.registerFromManager(
      ToolType.polyLine,
      (context) => _PolyLineTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'poly_line',
        label: 'PolyLine',
        icon: Icons.show_chart,
        command: 'PolyLine[]',
        toolType: ToolType.polyLine,
        implemented: true,
      ),
    );

    // PolyArcGon tool
    registry.registerFromManager(
      ToolType.polyArcGon,
      (context) => _PolyArcGonTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'poly_arc_gon',
        label: 'Poly-Arc-Gon',
        icon: Icons.all_inclusive,
        command: 'PolyArcGon[]',
        toolType: ToolType.polyArcGon,
        implemented: true,
      ),
    );

    // Midpoint tool
    registry.registerFromManager(
      ToolType.midpoint,
      (context) => _MidpointTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'midpoint',
        label: 'Midpoint',
        icon: Icons.adjust,
        assetIcon: 'assets/tool_icons/midpoint.svg',
        command: 'Midpoint[]',
        toolType: ToolType.midpoint,
        implemented: true,
      ),
    );

    // Perpendicular tool
    registry.registerFromManager(
      ToolType.perpendicular,
      (context) => _PerpendicularTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'perpendicular',
        label: 'Perpendicular',
        icon: Icons.rotate_90_degrees_ccw,
        assetIcon: 'assets/tool_icons/perpendicularline.svg',
        command: 'Perpendicular[]',
        toolType: ToolType.perpendicular,
        implemented: true,
      ),
    );

    // Parallel tool
    registry.registerFromManager(
      ToolType.parallel,
      (context) => _ParallelTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'parallel',
        label: 'Parallel',
        icon: Icons.swap_calls,
        assetIcon: 'assets/tool_icons/parallel_line.svg',
        command: 'Parallel[]',
        toolType: ToolType.parallel,
        implemented: true,
      ),
    );

    // Perpendicular Bisector tool
    registry.registerFromManager(
      ToolType.perpBisector,
      (context) => _PerpBisectorTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'perp_bisector',
        label: 'Perp. Bisector',
        icon: Icons.straighten,
        assetIcon: 'assets/tool_icons/perpendicularbisector.svg',
        command: 'PerpBisector[]',
        toolType: ToolType.perpBisector,
        implemented: true,
      ),
    );

    // Angle Bisector tool
    registry.registerFromManager(
      ToolType.angleBisector,
      (context) => _AngleBisectorTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'angle_bisector',
        label: 'Angle Bisector',
        icon: Icons.call_split,
        assetIcon: 'assets/tool_icons/angle_Bisector.svg',
        command: 'AngleBisector[]',
        toolType: ToolType.angleBisector,
        implemented: true,
      ),
    );

    // Tangent tool
    registry.registerFromManager(
      ToolType.tangent,
      (context) => _TangentTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'tangent',
        label: 'Tangent',
        icon: Icons.rotate_90_degrees_cw,
        assetIcon: 'assets/tool_icons/tangent_lines.svg',
        command: 'Tangent[]',
        toolType: ToolType.tangent,
        implemented: true,
      ),
    );

    // Intersection tool
    registry.registerFromManager(
      ToolType.intersection,
      (context) => _IntersectionTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'intersection',
        label: 'Intersection',
        icon: Icons.control_point,
        assetIcon: 'assets/tool_icons/intersection.svg',
        command: 'Intersect[]',
        toolType: ToolType.intersection,
        implemented: true,
      ),
    );

    // Reflect Line tool
    registry.registerFromManager(
      ToolType.reflectLine,
      (context) => _ReflectLineTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'reflect_line',
        label: 'Reflect Line',
        icon: Icons.flip,
        assetIcon: 'assets/tool_icons/invert_about_line.svg',
        command: 'Reflect[]',
        toolType: ToolType.reflectLine,
        implemented: true,
      ),
    );

    // Reflect Point tool
    registry.registerFromManager(
      ToolType.reflectPoint,
      (context) => _ReflectPointTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'reflect_point',
        label: 'Reflect Point',
        icon: Icons.flip_camera_android,
        assetIcon: 'assets/tool_icons/reflection_about_point.svg',
        command: 'Reflect[]',
        toolType: ToolType.reflectPoint,
        implemented: true,
      ),
    );

    // Reflect Circle tool
    registry.registerFromManager(
      ToolType.reflectCircle,
      (context) => _ReflectCircleTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'reflect_circle',
        label: 'Reflect Circle',
        icon: Icons.flip_camera_ios,
        assetIcon: 'assets/tool_icons/inversion.svg',
        command: 'Reflect[]',
        toolType: ToolType.reflectCircle,
        implemented: true,
      ),
    );

    // Rotate tool
    registry.registerFromManager(
      ToolType.rotate,
      (context) => _RotateTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'rotate',
        label: 'Rotate',
        icon: Icons.rotate_left,
        assetIcon: 'assets/tool_icons/rotate.svg',
        command: 'Rotate[]',
        toolType: ToolType.rotate,
        implemented: true,
      ),
    );

    // Translate tool
    registry.registerFromManager(
      ToolType.translate,
      (context) => _TranslateTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'translate',
        label: 'Translate',
        icon: Icons.open_in_full,
        command: 'Translate[]',
        toolType: ToolType.translate,
        implemented: true,
      ),
    );

    // Dilate tool
    registry.registerFromManager(
      ToolType.dilate,
      (context) => _DilateTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'dilate',
        label: 'Dilate',
        icon: Icons.center_focus_strong,
        assetIcon: 'assets/tool_icons/dilation.svg',
        command: 'Dilate[]',
        toolType: ToolType.dilate,
        implemented: true,
      ),
    );

    // Select and Pan tools (no geometry creation, but register metadata)
    registry.registerFromManager(
      ToolType.select,
      (context) => null,
      const ToolCatalogEntry(
        id: 'move',
        label: 'Move',
        icon: Icons.open_with,
        assetIcon: 'assets/tool_icons/move.svg',
        command: 'Move[]',
        toolType: ToolType.select,
        implemented: true,
      ),
    );

    registry.registerFromManager(
      ToolType.pan,
      (context) => null,
      const ToolCatalogEntry(
        id: 'pan',
        label: 'Pan',
        icon: Icons.pan_tool,
        assetIcon: 'assets/tool_icons/Standard View.svg',
        command: 'Pan[]',
        toolType: ToolType.pan,
        implemented: true,
      ),
    );
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

  /// Get list of all available tools from registry
  List<ToolType> get availableTools => ToolRegistry().availableTools;

  /// Check if a tool type is available
  bool isToolAvailable(ToolType type) {
    return ToolRegistry().isToolAvailable(type);
  }
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

/// Perpendicular line tool - builds a line perpendicular to a reference line through a point
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
    notifyStateChanged('Select a point and a line for perpendicular');
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
